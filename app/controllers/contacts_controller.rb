# Import contacts from user's external accounts.

class ContactsController < ApplicationController

  VALID_PROVIDERS = ["GMAIL", "YAHOO"]

  def index
  end

  def import
    importer = init_importer
    info = importer.begin_import(params[:provider])
    session["import_id"] = info[:import_id]
    @consent_url = info[:consent_url]
  end

  def import_callback
    importer = init_importer
    loop do
      @contacts = importer.get_contacts(session["import_id"])
      if @contacts
        session["import_id"] = nil
        break
      end
    end
  end

  protected
  def init_importer
    Cloudsponge::ContactImporter.new(AppConfig.cloudsponge["key"],
                                     AppConfig.cloudsponge["password"])
  end

end
