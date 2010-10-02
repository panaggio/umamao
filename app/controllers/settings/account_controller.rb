class Settings::AccountController < ApplicationController
  before_filter :login_required
  layout 'settings'
  set_tab :account, :settings

  def edit
    @user = current_user
    @user.timezone = AppConfig.default_timezone if @user.timezone.blank?
  end

  def update
    @user = current_user

    if params[:current_password] && @user.valid_password?(params[:current_password])
      @user.encrypted_password = ""
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
    end

    @user.safe_update(%w[login email name language timezone preferred_languages
                         notification_opts bio hide_country website], params[:user])

    if params[:user]["birthday(1i)"]
      @user.birthday = build_date(params[:user], "birthday")
    end

    Magent.push("actors.judge", :on_update_user, @user.id, current_group.id)

    preferred_tags = params[:user][:preferred_tags]
    if @user.valid? && @user.save
      @user.add_preferred_tags(preferred_tags, current_group) if preferred_tags
      redirect_to root_path
    else
      render :action => "edit"
    end
  end

end
