class WaitingUsersController < ApplicationController
  # POST /lectures
  # POST /lectures.xml
  def create
    @user = User.new
    @waiting_user = WaitingUser.new(params[:user])

    if @waiting_user.save
      redirect_to root_path(:saved => true), :notice => 'Email salvo. Em breve entraremos em contato.'
    else
      if @waiting_user.errors.present?
        localized_errors = @waiting_user.errors.map { |field, message|
          [field, t("validatable.#{message}")]
        }

        localized_errors.each do |field, message|
          @waiting_user.errors.replace(field, message)
        end
      end

      render 'welcome/landing', :layout => false
    end
  end
end
