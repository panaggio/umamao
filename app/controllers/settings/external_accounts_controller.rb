class Settings::ExternalAccountsController < ApplicationController
  respond_to :html
  before_filter :login_required
  layout 'settings'
  set_tab :external_accounts, :settings

  def index
  end

  def create
    auth_hash = request.env['omniauth.auth']
    unless @external_account = ExternalAccount.find_from_hash(auth_hash)
      @external_account = ExternalAccount.create_from_hash(auth_hash,
                                                           current_user)
    end

    respond_with(@external_account, :status => :created) do |format|
      track_event("connected_#{@external_account.provider}".to_sym)
      format.html { redirect_to session["omniauth_return_url"] }
    end
  end

  def failure
    respond_to do |format|
      format.html { redirect_to session["omniauth_return_url"] }
    end
  end

  def destroy
    @external_account = ExternalAccount.find(params[:id])
    @external_account.destroy
    respond_with(@external_account, :status => :ok) do |format|
      format.html { redirect_to session["omniauth_return_url"] }
    end
  end

end
