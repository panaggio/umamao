class PasswordController < ApplicationController
  before_filter :login_required

  set_tab :password, :settings

  def edit
  end

  def update
  end

end
