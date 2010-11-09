class Settings::ProfileController < ApplicationController
  before_filter :login_required
  layout 'settings'
  set_tab :profile, :settings

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    @user.safe_update(%w[name gender bio description location], params[:user])

    if params[:user]["birthday(1i)"]
      @user.birthday = build_date(params[:user], "birthday")
    end

    if @user.save
      flash.now[:notice] = t(:success, :scope => 'global.edit')
    else
      flash.now[:error] = t(:error, :scope => 'global.edit')
    end

    render :action => "edit"
  end

end
