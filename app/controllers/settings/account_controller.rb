class Settings::AccountController < ApplicationController
  before_filter :login_required
  layout 'settings'
  set_tab :account, :settings

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    @user.safe_update(%w[email timezone], params[:user])

    if @user.save
      flash.now[:notice] = t(:success, :scope => 'global.edit')
    else
      flash.now[:error] = t(:error, :scope => 'global.edit')
    end

    render :action => "edit"
  end

end
