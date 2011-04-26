class Settings::AvatarsController < ApplicationController
  before_filter :login_required

  def edit
    @user = current_user
  end

  def create
    if current_user.update_avatar(params[:avatar])
      track_event(:uploaded_avatar)
      flash[:notice] = t("settings.avatars.create.success")
    else
      flash[:error] = t("settings.avatars.create.error")
    end

    redirect_to settings_avatar_path
  end

  def destroy
    if current_user.remove_avatar
      track_event(:removed_avatar)
      flash[:notice] = t("settings.avatars.destroy.success")
    else
      flash[:error] = t("settings.avatars.destroy.error")
    end

    redirect_to settings_avatar_path
  end

end
