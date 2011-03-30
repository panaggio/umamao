class TopicsController < ApplicationController
  before_filter :login_required, :only => [:edit, :update, :follow, :unfollow, :toggle_email_subscription]
  respond_to :html

  tabs :default => :topics

  def index
    set_page_title(t("layouts.application.tags"))

    order = params[:sort].try(:to_sym) || :questions_count
    set_tab order, :topics
    order = order.desc if [:questions_count, :created_at].include? order

    @topics = Topic.sort(order).paginate(:per_page => 100,
                                         :page => params[:page] || 1)

    respond_with @topics
  end

  def show
    begin
      @topic = Topic.find_by_slug_or_id(params[:id])
    rescue BSON::InvalidObjectId
      raise Goalie::NotFound
    end
    set_page_title(@topic.title)

    set_tab :all, :topic_show

    @news_items = NewsItem.paginate(:recipient_id => @topic.id,
                                    :recipient_type => "Topic",
                                    :per_page => 30,
                                    :page => params[:page] || 1,
                                    :order => :created_at.desc)
    @questions = Question.paginate(:topic_ids => @topic.id, :banned => false,
                                   :order => :activity_at.desc, :per_page => 25,
                                   :page => params[:page] || 1) if @news_items.blank?

    @related_topics_count =
      @topic.related_topics_count.sort_by { |k,v| -v }.map { |k,v| [Topic.find_by_id(k), v] }

    respond_with @topics
  end

  def edit
    @topic = Topic.find_by_slug_or_id(params[:id])
    respond_with @topic
  end

  def update
    @topic = Topic.find_by_slug_or_id(params[:id])
    @topic.safe_update(%w[title description], params[:topic])
    @topic.updated_by = current_user
    @topic.save
    track_event(:edited_topic)

    Question.all(:topic_ids => @topic.id,
                 :select => [:id, :updated_at]).each do |question|
    end

    respond_with @topic
  end

  def follow
    if params[:id]
      @topic = Topic.find_by_slug_or_id(params[:id])
    elsif params[:title]
      @topic = Topic.find_by_title(params[:title]) ||
        Topic.new(:title => params[:title])
    end

    user = current_user
    followers_count = @topic.followers_count + 1
    @topic.add_follower!(user)
    user.remove_suggestion(@topic)
    user.populate_news_feed!(@topic)
    user.save!

    track_event(:followed_topic)

    notice = t("followable.flash.follow", :followable => @topic.title)

    respond_to do |format|
      format.html do
        redirect_to topic_path(@topic)
      end
      format.js do
        res = {
          :success => true,
          :message => notice,
          :follower => (render_cell :users, :small_picture,
                        :user => current_user),
          :followers_count => I18n.t("followable.followers.link",
                                     :count => followers_count,
                                     :link => followers_topic_path(@topic))
        }

        if params[:answer]
          # Used when following from settings page
          res[:html] = render_cell :topics, :followed, :topic => @topic
        elsif params[:suggestion]
          # We need to redraw the topics suggestions
          res[:suggestions] = render_cell :suggestions, :topics, :single_column => params[:single_column]
        end

        render :json => res.to_json
      end
    end
  end

  def unfollow
    @topic = Topic.find_by_slug_or_id(params[:id])
    followers_count = @topic.followers_count - 1
    @topic.remove_follower!(current_user)

    current_user.mark_as_uninteresting(@topic)
    current_user.save!

    track_event(:unfollowed_topic)

    notice = t("followable.flash.unfollow", :followable => @topic.title)

    respond_to do |format|
      format.html do
        redirect_to topic_path(@topic)
      end
      format.js do
        render(:json => {
                 :success => true,
                 :message => notice,
                 :user_id => current_user.id,
                 :followers_count =>
                 I18n.t("followable.followers.link",
                        :count => followers_count,
                        :link => followers_topic_path(@topic.id))
               }.to_json)
      end
    end
  end

  def toggle_email_subscription
    if params[:id]
      @topic = Topic.find_by_slug_or_id(params[:id])
    elsif params[:title]
      @topic = Topic.find_by_title(params[:title]) ||
        Topic.new(:title => params[:title])
    end

    user = current_user

    # TODO: ignore when user does not follow topic
    # if @topic.follower_ids.include?(user.id)

    if @topic.email_subscriber_ids.include?(user.id)
      @topic.email_subscriber_ids.delete(user.id)
      @topic.save!
      notice = t("topics.show.email_subscription.notice.unsubscribed", :topic => @topic.title)
    else
      @topic.email_subscriber_ids << user.id
      @topic.save!
      notice = t("topics.show.email_subscription.notice.subscribed", :topic => @topic.title)
    end

    respond_to do |format|
      format.html do
        redirect_to topic_path(@topic)
      end
      format.js do
        res = {
          :success => true,
          :message => notice
        }

        render :json => res.to_json
      end
    end
  end

  def unanswered
    begin
      @topic = Topic.find_by_slug_or_id(params[:id])
    rescue BSON::InvalidObjectId
      raise Goalie::NotFound
    end
    set_page_title(@topic.title)

    set_tab :unanswered, :topic_show

    conditions = scoped_conditions(:answered_with_id => nil, :banned => false,
                                   :closed => false)

    @questions = Question.paginate({:topic_ids => @topic.id, :banned => false,
                                   :order => :activity_at.desc, :per_page => 25,
                                   :page => params[:page] || 1}.merge(conditions))

    respond_with @topics
  end

  # Searches matching topics and render them in JSON form for input
  # autocomplete.
  def autocomplete
    result = []
    if q = params[:q]
      result = Topic.filter(q, :per_page => 5)
    end

    re = Regexp.new("^#{Regexp.escape q}$")

    if !result.any? {|t| t.title =~ re}
      result << Topic.new(:title => q, :questions_count => 0)
    end

    respond_to do |format|
      format.js do
        render :json =>
          (result.map do |t|
             res = {
               :id => t.id,
               :title => t.title,
               :count => t.questions_count,
               :html => (render_to_string :partial => "autocomplete.html", :locals => {:topic => t, :question => false})
             }
             if !params[:follow]
               res[:box] = render_to_string(:partial => "box.html",
                                            :locals => {:topic => t, :question => false})
             end
             res
           end.to_json)
      end
    end
  end

  def followers
    @topic = Topic.find_by_slug_or_id(params[:id])
    @followers =
      @topic.followers.paginate :per_page => 15, :page => params[:page]
    respond_to do |format|
      format.html
    end
  end

  def javascript_embedded
    begin
      topic = Topic.find_by_slug_or_id(params[:id])
    rescue BSON::InvalidObjectId
      raise Goalie::NotFound
    end

    questions = Question.paginate(:topic_ids => topic.id, :banned => false,
                                   :order => :activity_at.desc, :per_page => 5,
                                   :page =>  1)

    @info = render_to_string :partial => "embedded.html", :locals => {:topic => topic, :questions => questions}
    @info.gsub!("\n", "").gsub!("\"", "\\\"")
    render :content_type => 'text/javascript'
  end

end
