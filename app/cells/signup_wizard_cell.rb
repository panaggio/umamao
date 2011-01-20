# Wizard that is displayed after a user signs up. Steps through
# external accounts integration, topics and users suggestions.

class SignupWizardCell < Cell::Rails
  include Devise::Controllers::Helpers
  helper ApplicationHelper
  helper_method :current_user

  def wizard
    @steps = ["connect", "follow"]
    @current_step = params[:current_step]
    current_step_idx = @steps.index(@current_step)
    @previous_step = current_step_idx == 0 ? nil : @steps[current_step_idx - 1]
    @next_step = @steps[current_step_idx + 1]
    render
  end

  def follow
    current_user.find_first_suggestions
    current_user.save!
    render
  end

end
