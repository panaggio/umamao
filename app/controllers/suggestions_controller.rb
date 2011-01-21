class SuggestionsController < ApplicationController
  before_filter :login_required

  # Refuse suggestions.
  def refuse
    type = nil
    if @suggestion = Suggestion.find_by_id(params[:suggestion])
      type = (@suggestion.entry_type.downcase + "s").to_sym
      current_user.refuse_suggestion(@suggestion)
      current_user.save!
    end

    track_event(:refused_suggestion)

    respond_to do |format|
      format.js do
        request_answer = {:success => !!@suggestion}
        if type
          request_answer[:suggestions] = render_cell :suggestions, type
        end
        render :json => request_answer.to_json
      end
    end
  end

end
