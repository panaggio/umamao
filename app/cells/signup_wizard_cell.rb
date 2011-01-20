# Wizard that is displayed after a user signs up. Steps through
# external accounts integration, topics and users suggestions.

class SignupWizardCell < Cell::Rails
  include Devise::Controllers::Helpers
  helper ApplicationHelper

  def wizard
    @steps = ["connect", "follow"]
    @current_step = params[:current_step]
    current_step_idx = @steps.index(@current_step)
    @previous_step = current_step_idx == 0 ? nil : @steps[current_step_idx - 1]
    @next_step = @steps[current_step_idx + 1]
    render
  end

  def follow
    @current_user = current_user
    @suggestion_list = @current_user.suggestion_list
    # We begin by populating the suggestions list.
    if @suggestion_list.suggested_user_ids.blank?
      @suggestion_list.suggest(@current_user.find_external_contacts)
    end

    if @suggestion_list.suggested_topic_ids.blank?
      @suggestion_list.suggest(@current_user.find_topics)
      @suggestion_list.suggest_random_topics
    end

    @suggestion_list.last_modified_at = Time.now
    @suggestion_list.save!
    render
  end

end
