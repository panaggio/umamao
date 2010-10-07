class Settings::NotificationsController < ApplicationController
  before_filter :login_required
  layout 'settings'
  set_tab :notifications, :settings

  def edit
    @notification_opts = current_user.notification_opts
  end

  def update
    @notification_opts = current_user.notification_opts
    @notification_opts.safe_update(%w[new_answer], params[:notification_config])

    if @notification_opts.save
      flash.now[:notice] = t(:success, :scope => 'global.edit')
    else
      flash.now[:error] = t(:error, :scope => 'global.edit')
    end

    render :action => "edit"
  end

end
