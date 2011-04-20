class AvatarsController < ApplicationController
  before_filter :login_required

  def create
    @file = Avatar.new(:file => params[:file],
                       :user => current_user,
                       :group => current_group)

    if !@file.save
      flash[:error] = t("avatars.create.error")
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
