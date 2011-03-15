# Import contacts from user's external accounts.

class ContactsController < ApplicationController
  before_filter :login_required

  VALID_PROVIDERS = ["GMAIL", "YAHOO", "WINDOWSLIVE"]

  def index
    @contacts = current_user.contacts
  end

  def import
    info = current_user.begin_contact_import(params[:provider])
    session["import_id"] = info[:import_id]
    @consent_url = info[:consent_url]

    redirect_to @consent_url
  end

  def import_callback
    begin
      success = current_user.import_contacts!(session["import_id"])
      session["import_id"] = nil
    rescue
      success = false
    end

    if success
      @contacts = current_user.contacts
      render :index
    else
      flash[:error] = I18n.t("contacts.import.error")
      redirect_to invitations_path
    end
  end

  def search
    @contacts =
      Contact.filter(params[:q],
                     :fields => {:user_id => current_user.id},
                     :per_page => 7)

    respond_to do |format|
      format.js do
        render :json => @contacts.map{ |c|
          {:name => c.name, :email => c.email}
        }.to_json
      end
    end

  end

  def invite
    @message = params[:message]
    @emails = params[:emails]

    Invitation.invite_emails! current_user, @message, @emails

    redirect_to invitations_path
  end
end
