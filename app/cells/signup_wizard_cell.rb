class SignupWizardCell < Cell::Rails
  include Devise::Controllers::Helpers
  helper ApplicationHelper

  def wizard
    @user = @opts[:user]
    render
  end

end
