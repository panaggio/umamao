class WaitingUsersController < ApplicationController
  # POST /lectures
  # POST /lectures.xml
  def create
    @user = User.new
    @waiting_user = WaitingUser.new(params[:user])

    if @waiting_user.save
      redirect_to root_path(:saved => true), :notice => 'Email salvo. Em breve entraremos em contato.'
    else
      render 'welcome/landing', :layout => false
    end
  end
end
