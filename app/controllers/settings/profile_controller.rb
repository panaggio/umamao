class ProfileController < ApplicationController
  before_filter :login_required

  set_tab :profile, :settings

  def edit
  end

  def update
  end

end
