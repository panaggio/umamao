class AvatarsController < ApplicationController
  before_filter :login_required

  def update
    if params[:avatar].present?
      current_user.update_avatar!(params[:avatar], current_group)
    else
      current_user.avatar_config = params[:avatar_config]

      if current_user.save
        current_user.avatar.destroy if current_user.avatar.present?
      else
        flash[:error] = t("avatars.update.error")
      end
    end

    redirect_to settings_profile_path
  end

  def delete
    if current_user.avatar
      current_user.avatar.destroy
    else
      flash[:error] = t("avatars.destroy.error")
    end

    redirect_to settings_profile_path
  end

end
