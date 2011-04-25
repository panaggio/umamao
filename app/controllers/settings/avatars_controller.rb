class Settings::AvatarsController < ApplicationController
  before_filter :login_required

  def update
    current_user.update_avatar!(params[:avatar] ||
                                params[:user][:avatar_config])

    redirect_to settings_profile_path
  end

end
