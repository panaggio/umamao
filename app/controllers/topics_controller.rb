class TopicsController < ApplicationController
  before_filter :login_required, :only => [:edit, :update, :follow, :unfollow]
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
    @topic = Topic.find_by_slug_or_id(params[:id])
    set_page_title(@topic.title)
    @questions = Question.paginate(:topic_ids => @topic.id, :banned => false,
                                   :order => :activity_at.desc, :per_page => 25,
                                   :page => params[:page] || 1)

    respond_with @topics
  end

  def edit
    @topic = Topic.find_by_slug_or_id(params[:id])
    respond_with @topic
  end

  def update
    @topic = Topic.find_by_slug_or_id(params[:id])
    @topic.safe_update(%w[title description], params[:topic])
    @topic.save
    track_event(:edited_topic)

    Question.all(:topic_ids => @topic.id, :select => [:id]).each do |question|
      sweep_question(question)
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
    @topic.followers << current_user
    @topic.save
    current_user.populate_news_feed!(@topic)

    track_event(:followed_topic)

    flash[:notice] = t("followable.flash.follow", :followable => @topic.title)

    respond_to do |format|
      format.html do
        redirect_to topic_path(@topic)
      end
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice] }.to_json)
      }
    end
  end

  def unfollow
    @topic = Topic.find_by_slug_or_id(params[:id])
    @topic.follower_ids.delete(current_user.id)
    @topic.save

    track_event(:unfollowed_topic)

    flash[:notice] = t("followable.flash.unfollow", :followable => @topic.title)

    respond_to do |format|
      format.html do
        redirect_to topic_path(@topic)
      end
      format.js {
        render(:json => {:success => true,
                 :message => flash[:notice] }.to_json)
      }
    end
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
             {
               :id => t.id,
               :title => t.title,
               :count => t.questions_count,
               :html => (render_to_string :partial => "autocomplete.html", :locals => {:topic => t}),
               :box => (render_to_string ({
                          :partial => (params[:follow] ? "topic.html" : "box.html"),
                          :locals => {:topic => t}
                        }))
             }
           end.to_json)
      end
    end
  end

end
