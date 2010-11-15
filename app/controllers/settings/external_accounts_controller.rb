class Settings::ExternalAccountsController < ApplicationController
  before_filter :login_required
  layout 'settings'
  set_tab :external_accounts, :settings

  def index
    @external_accounts = current_user.external_accounts
  end

  def create
    render :text => request.env['rack.auth'].inspect
  end

  def destroy
  end

end
