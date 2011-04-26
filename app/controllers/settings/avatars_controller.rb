class Settings::AvatarsController < ApplicationController
  before_filter :login_required
  before_filter :admin_required

  def edit
    @user = current_user
  end

  def create
    current_user.update_avatar!(params[:avatar])

    track_event(:uploaded_avatar)

    redirect_to settings_avatar_path
  end

  def destroy
    if current_user.remove_avatar!
      track_event(:removed_avatar)
    end
    redirect_to settings_avatar_path
  end

end
