class Settings::PasswordController < ApplicationController
  before_filter :login_required
  layout 'settings'
  set_tab :password, :settings

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.valid? && @user.update_with_password(params[:user])
      flash.now[:notice] = t(:new_password_saved, :scope => 'settings.password.edit')
      render :action => 'edit'
    else
      flash.now[:error] = t(:error_changing_password, :scope => 'settings.password.edit')
      render :action => "edit"
    end
  end

end
