class UploadsController < ApplicationController
  before_filter :login_required, :only => [:new, :create]

  def index
    @files = UploadedFile.all
  end

  def new
  end

  def create
    @file = UploadedFile.new(:file => params[:file],
                             :user => current_user)
    if @file.save
      redirect_to uploads_path
    else
      flash[:error] = t("uploads.create.error")
    end
  end

end
