class Settings::AvatarsController < ApplicationController
  before_filter :login_required
  before_filter :admin_required

  def edit
    @user = current_user
  end

  def update
    current_user.update_avatar!(params[:avatar] ||
                                params[:user][:avatar_config])

    redirect_to settings_avatar_path
  end

end
