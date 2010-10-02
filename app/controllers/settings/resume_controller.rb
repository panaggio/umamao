class ResumeController < ApplicationController
  before_filter :login_required

  set_tab :resume, :settings

  def edit
  end

  def update
  end

end
