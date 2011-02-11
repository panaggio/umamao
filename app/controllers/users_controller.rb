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

  def resend_confirmation_email
    current_user.resend_confirmation_token

    respond_to do |format|
      format.js {
        render :json => {
          :success => true,
          :message => t('users.annoying.resent_confirmation')
        }
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

    # User added by invitation
    if params[:invitation_token]
    @invitation = Invitation.
      find_by_invitation_token(params[:invitation_token])

      if @invitation
        @user.email = @invitation[:recipient_email]
        @user.invitation_token = @invitation.invitation_token
      end

    end

    # User added by affiliation
    if params[:affiliation_token]
      @affiliation = Affiliation.
        find_by_affiliation_token(params[:affiliation_token])

      if @affiliation.present?
        if @affiliation.user.present?
          redirect_to(root_url) && return
        else
          @user.affiliation_token = @affiliation.affiliation_token
        end
      end

    end

    if @invitation || @affiliation || @group_invitation
      @user.timezone = AppConfig.default_timezone
      render 'new', :layout => 'welcome'
    else
      return redirect_to(:root)
    end
  end

  def create
    tracking_properties = {}
    @user = User.new
    @user.safe_update(%w[login email name password_confirmation password
                         preferred_languages website language timezone
                         identity_url bio invitation_token
                         affiliation_token], params[:user])

    @user.agrees_with_terms_of_use =
      case params[:user][:agrees_with_terms_of_use]
      when "1"
        true
      when "0"
        false
      end

    if params[:user]["birthday(1i)"]
      @user.birthday = build_date(params[:user], "birthday")
    end

    @group_invitation = GroupInvitation.
      first(:slug => params[:group_invitation])
    @user.confirmed_at = Time.now if @group_invitation

    if invitation = Invitation.find_by_invitation_token(@user.invitation_token)
      tracking_properties[:invited_by] = invitation.sender.email
    end

    if @user.save
      if @group_invitation
        @group_invitation.push(:user_ids => @user.id)
        tracking_properties[:invited_by] = @group_invitation.slug
      end

      if @user.affiliation_token.present?
        @affiliation = Affiliation.
          find_by_affiliation_token(@user.affiliation_token)
        @affiliation.confirmed_at ||= Time.now
        @user.affiliations << @affiliation
        @user.bio = @affiliation.university.short_name
        @user.save
      end

      current_group.add_member(@user)
      track_event(:sign_up, {:user_id => @user.id,
                    :confirmed => @user.confirmed?}.merge(tracking_properties))
      flash[:conversion] = true

      # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      if @user.active?
        flash[:notice] = t("welcome", :scope => "users.create")
      else
        flash[:notice] = t("confirm", :scope => "users.create")
      end
      sign_in_and_redirect(:user, @user) # !! now logged in
    else
      flash[:error]  = t("users.create.flash_error")
      render :action => 'new', :layout => 'welcome'
    end
  end

  def wizard
    track_event("wizard_#{params[:current_step]}".to_sym)
    if ["skip", "finish"].include?(params[:current_step])
      current_user.has_been_through_wizard = true
      current_user.save!
      redirect_to root_path
    else
      render :layout => "welcome"
    end
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
    current_user.save!

    track_event(:followed_user)

    notice = t("followable.flash.follow", :followable => @user.name)

    if @user.notification_opts.activities
      Notifier.delay.follow(current_user, @user)
    end

    respond_to do |format|
      format.html do
        flash[:notice] = notice
        redirect_to user_path(@user)
      end
      format.js {
        followers_count = @user.followers.count
        response = {
          :success => true,
          :message => notice,
          :follower => (render_cell :users, :small_picture,
                        :user => current_user),
          :followers_count => I18n.t("followable.followers",
                                     :count => followers_count)
        }
        if params[:suggestion]
          response[:suggestions] =
            render_cell :suggestions, :users
        end
        render :json => response.to_json
      }
    end
  end

  def unfollow
    @user = User.find_by_login_or_id(params[:id])
    current_user.unfollow(@user)
    current_user.save!

    track_event(:unfollowed_user)

    notice = t("followable.flash.unfollow", :followable => @user.name)

    respond_to do |format|
      format.html do
        flash[:notice] = notice
        redirect_to user_path(@user)
      end
      format.js {
        followers_count = @user.followers.count
        render(:json => {
                 :success => true,
                 :message => notice,
                 :user_id => current_user.id,
                 :followers_count => I18n.t("followable.followers",
                                            :count => followers_count)
               }.to_json)
      }
    end
  end

  def set_not_new
    current_user.new_user = false
    current_user.save
    respond_to do |format|
      format.js  { head :ok }
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


