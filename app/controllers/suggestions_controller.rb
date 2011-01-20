class SuggestionsController < ApplicationController
  before_filter :login_required

  def destroy
    thing = type = nil
    if params[:user]
      thing = User.find_by_id(params[:user])
      type = :users
    elsif params[:topic]
      thing = Topic.find_by_id(params[:topic])
      type = :topics
    end

    if thing
      current_user.mark_as_uninteresting(thing)
      current_user.save!
    end

    respond_to do |format|
      format.js do
        request_answer = {:success => !!thing}
        if type
          request_answer[:suggestions] = render_cell :suggestions, type
        end
        render :json => request_answer.to_json
      end
    end
  end

end
