class ShareQuestionController < ApplicationController
  before_filter :login_required
  before_filter :check_connections

  def new
    @question = Question.find_by_id(params[:question])
    respond_to do |format|
      format.js do
        render :json => {
          :success => true,
          :html => (render_cell :share_question, :display,
                    :question => @question)
        }
      end
    end
  end

  def create
    @body = params[:body]
    @question = Question.find_by_id(params[:question])
    if params[:where] == "facebook"
      graph = current_user.facebook_connection
      graph.put_wall_post(@body, :link => question_url(@question))
      status = :success
      message = I18n.t("questions.show.share_success", :site => "Facebook")
    end

    respond_to do |format|
      format.html do
        case status
        when :success
          redirect_to question_path(@question)
        when :needs_connection
          redirect_to settings_external_accounts_path
        end
      end

      format.js do
        case status
        when :success
          render :json => {
            :success => true,
            :message => message
          }.to_json
        when :needs_connection
          session["omniauth_return_url"] = "http://www.google.com"
          render :json => {
            :success => false,
            :status => "needs_connection",
            :html => html,
            :url => "/auth/facebook"
          }.to_json
        end
      end
    end
  end

  def check_connections
  end

end
