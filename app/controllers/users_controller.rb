class UsersController < ApplicationController
  prepend_before_filter :require_no_authentication, :only => [:new, :create]
  before_filter :login_required, :only => [:edit, :update, :wizard,
                                           :follow, :unfollow]

  tabs :default => :users

  subtabs :index => [[:newest, "created_at desc"],
                     [:oldest, "created_at asc"],
                     [:name, "name asc"]]

  def index
    set_page_title(t("users.index.title"))
    options =  {:per_page => params[:per_page]||24,
               :order => current_order,
               :page => params[:page] || 1}
    options[:login] = /^#{Regexp.escape(params[:q])}/ if params[:q]

    @users = current_group.paginate_users(options)

    respond_to do |format|
      format.html
      format.json {
        render :json => @users.to_json(:only => %w[name login membership_list bio website location language])
      }
      format.js {
        html = render_to_string(:partial => "user", :collection  => @users)
        pagination = render_to_string(:partial => "shared/pagination", :object => @users,
                                      :format => "html")
        render :json => {:html => html, :pagination => pagination }
      }
    end

  end

  def new
    if params[:group_invitation]
      @group_invitation = GroupInvitation.first(:slug => params[:group_invitation])
      unless @group_invitation && @group_invitation.active?
        redirect_to(root_path) && return
      end
    end

    @user = User.new

    @invitation = Invitation.
      find_by_invitation_token(params[:invitation_token])

    if @invitation
      @user.email = @invitation[:recipient_email]
      @user.invitation_token = @invitation.invitation_token
    end

    @user.timezone = AppConfig.default_timezone
    render 'new', :layout => 'welcome'
  end

  def create
    @user = User.new
    @user.safe_update(%w[login email academic_email name password_confirmation password preferred_languages website
                         language timezone identity_url bio hide_country invitation_token], params[:user])
    if params[:user]["birthday(1i)"]
      @user.birthday = build_date(params[:user], "birthday")
    end

    @group_invitation = GroupInvitation.
      first(:slug => params[:group_invitation])
    @user.confirmed_at = Time.now if @group_invitation

    success = @user && @user.save
    if success && @user.errors.empty?

      @group_invitation.push(:user_ids => @user.id) if @group_invitation

      current_group.add_member(@user)
      track_event(:sign_up, :user_id => @user.id, :confirmed => @user.confirmed?)
      flash[:conversion] = true

      # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      @user.localize(request.remote_ip)
      if @user.active?
        flash[:notice] = t("welcome", :scope => "users.create")
      else
        flash[:notice] = t("confirm", :scope => "users.create")
      end
      # sign_in_and_redirect(:user, @user) # !! now logged in
      sign_in(:user, @user)
      render :action => "show"
    else
      flash[:error]  = t("flash_error", :scope => "users.create")
      render :action => 'new'
    end
  end

  def wizard
    render :layout => "welcome"
  end

  def show
    @user = User.find_by_login_or_id(params[:id])
    raise Goalie::NotFound unless @user

    set_page_title(t("users.show.title", :user => @user.name))

    @q_sort, order = active_subtab(:q_sort)
    @questions = @user.questions.paginate(:page=>params[:questions_page],
                                          :order => order,
                                          :per_page => 10,
                                          :group_id => current_group.id,
                                          :banned => false)

    @a_sort, order = active_subtab(:a_sort)
    @answers = @user.answers.paginate(:page=>params[:answers_page],
                                      :order => order,
                                      :group_id => current_group.id,
                                      :per_page => 10,
                                      :banned => false)

    @f_sort, order = active_subtab(:f_sort)
    @favorites = @user.favorites.paginate(:page => params[:favorites_page],
                                          :per_page => 25,
                                          :order => order,
                                          :group_id => current_group.id)

    @favorite_questions = Question.find(@favorites.map{|f| f.question_id })

    @topics = Topic.query(:follower_ids => @user.id)

    add_feeds_url(url_for(:format => "atom"), t("feeds.user"))

    @user.viewed_on!(current_group) if @user != current_user && !is_bot?

    respond_to do |format|
      format.html
      format.atom
      format.json {
        render :json => @user.to_json(:only => %w[name login membership_list bio website location language])
      }
    end
  end

  def change_preferred_tags
    @user = current_user
    if params[:tags]
      if params[:opt] == "add"
        @user.add_preferred_tags(params[:tags], current_group) if params[:tags]
      elsif params[:opt] == "remove"
        @user.remove_preferred_tags(params[:tags], current_group)
      end
    end

    respond_to do |format|
      format.html {redirect_to questions_path}
    end
  end

  def follow
    @user = User.find_by_login_or_id(params[:id])
    current_user.follow(@user)
    current_user.populate_news_feed!(@user)

    track_event(:followed_user)

    notice = t("followable.flash.follow", :followable => @user.name)

    if @user.notification_opts.activities
      Notifier.follow(current_user, @user).deliver
    end

    respond_to do |format|
      format.html do
        flash[:notice] = notice
        redirect_to user_path(@user)
      end
      format.js {
        render(:json => {:success => true,
                 :message => notice }.to_json)
      }
    end
  end

  def unfollow
    @user = User.find_by_login_or_id(params[:id])
    current_user.unfollow(@user)

    track_event(:unfollowed_user)

    notice = t("followable.flash.unfollow", :followable => @user.name)

    respond_to do |format|
      format.html do
        flash[:notice] = notice
        redirect_to user_path(@user)
      end
      format.js {
        render(:json => {:success => true,
                 :message => notice }.to_json)
      }
    end
  end

  def destroy
    if false && current_user.delete # FIXME We need a better way to delete users
      flash[:notice] = t("destroyed", :scope => "devise.registrations")
    else
      flash[:notice] = t("destroy_failed", :scope => "devise.registrations")
    end
    return redirect_to(:root)
  end

  protected
  def active_subtab(param)
    key = params.fetch(param, "votes")
    order = "votes_average desc, created_at desc"
    case key
      when "votes"
        order = "votes_average desc, created_at desc"
      when "views"
        order = "views desc, created_at desc"
      when "newest"
        order = "created_at desc"
      when "oldest"
        order = "created_at asc"
    end
    [key, order]
  end

end


