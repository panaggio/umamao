# Used for associating a Twitter account with a Topic. For account
# creation, see settings/external_accounts_controller.rb

class TopicExternalAccountsController < ApplicationController
  before_filter :login_required, :admin_required

  def new
    session["umamao.topic_id"] = params[:topic_id]
    redirect_to "/auth/twitter"
  end

  def destroy
    @external_account = TopicExternalAccount.find_by_id(params[:id])
    @topic = @external_account.topic
    @external_account.destroy
    redirect_to topic_path(@topic)
  end

end
