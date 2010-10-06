class Settings::ProfileController < ApplicationController
  before_filter :login_required
  layout 'settings'
  set_tab :profile, :settings

  def edit
    @user = current_user
  end

  def update
  end

end
