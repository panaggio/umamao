class Settings::AvatarsController < ApplicationController
  before_filter :login_required
  before_filter :admin_required

  def edit
    @user = current_user
  end

  def update
    current_user.update_avatar!(params[:avatar] ||
                                params[:user][:avatar_config])

    if params[:avatar].present?
      track_event(:uploaded_avatar)
    elsif params[:user][:avatar_config].present?
      track_event(:changed_avatar, :to => params[:user][:avatar_config])
    end

    redirect_to settings_avatar_path
  end

end
