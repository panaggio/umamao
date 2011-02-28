class SuggestionsController < ApplicationController
  before_filter :login_required

  # Refuse suggestions.
  def refuse
    type = nil

    if params[:suggestion].present?
      @suggestion = Suggestion.find_by_id(params[:suggestion])
    elsif params[:topic].present?
      @suggestion = Suggestion.first(:entry_id => BSON::ObjectId(params[:topic]),
                                     :entry_type => "Topic",
                                     :user_id => current_user.id)
    elsif params[:user].present?
      @suggestion = Suggestion.first(:entry_id => params[:user],
                                     :entry_type => "User",
                                     :user_id => current_user.id)
    end

    if @suggestion
      type = (@suggestion.entry_type.downcase + "s").to_sym
      current_user.refuse_suggestion(@suggestion)
      current_user.save!
      track_event(:refused_suggestion)
    end

    respond_to do |format|
      format.js do
        request_answer = {:success => !!@suggestion}
        if type
          request_answer[:suggestions] = render_cell :suggestions, type, :single_column => params[:single_column]
        end
        render :json => request_answer.to_json
      end
    end
  end

end
