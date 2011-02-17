# This controller is used so that existing users who haven't agreed
# yet to our terms of service see the terms and agree with them or
# not.

class AgreementController < ApplicationController
  layout "welcome"

  def edit
  end

  def update
    if params[:agrees_with_terms_of_service] == "1"
      current_user.agrees_with_terms_of_service = true
      current_user.save!
      track_event :old_user_agreed_with_tos
      redirect_to root_path
    else
      flash[:error] = t("agreement.errors.did_not_agree")
      render "edit"
    end
  end

  def refuse
    flash[:error] = t("agreement.errors.did_not_agree")
    track_event :old_user_did_not_agree_with_tos
    sign_out_and_redirect current_user
  end

  def check_agreement_to_tos
    if !needs_to_agree_with_tos?
      redirect_to root_path
    end
  end
end
