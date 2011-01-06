class ExternalAccountsCell < Cell::Rails
  include Devise::Controllers::Helpers

  def display
    # We track from which page we authenticate so we can return to it
    # later.
    session["return_url"] = request.url
    render
  end

  def facebook
    @provider = 'facebook'
    @external_account = current_user.external_accounts.
      first(:provider => @provider)
    @name = @external_account.user_info['name'] if @external_account.present?
    render :view => 'external_account'
  end

  def twitter
    @provider = 'twitter'
    @external_account = current_user.external_accounts.
      first(:provider => @provider)

    if @external_account.present?
      @name = '@' + @external_account.user_info['nickname']
    end

    render :view => 'external_account'
  end

end
