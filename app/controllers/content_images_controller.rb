class ContentImagesController < ApplicationController
  before_filter :login_required
  before_filter :get_file_from_raw_post_data, :only => :create

  def create
    @content_image = ContentImage.new(:file => params[:qqfile])

    if @content_image.save
      if request.xhr?
        render :json => {
          :success => true,
          :html =>
            render_to_string(:partial => "content_images/content_image",
                             :locals => { :content_image => @content_image })
        }.to_json
      end
    else
      if request.xhr?
        render :json => {:success => false}.to_json
      end
    end
  end

  def destroy
    @content_image = ContentImage.find_by_id(params[:image_id])

    @content_image.destroy

    if request.xhr?
      render :json => { :success => true }
    end
  end

end


