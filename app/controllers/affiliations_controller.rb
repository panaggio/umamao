class AffiliationsController < ApplicationController
  def create
    @user = User.new
    @user.safe_update(%w[login email academic_email name password_confirmation password preferred_languages website
                         language timezone identity_url bio hide_country invitation_token], params[:user])
    if params[:user]["birthday(1i)"]
      @user.birthday = build_date(params[:user], "birthday")
    end

    @group_invitation = GroupInvitation.
      first(:slug => params[:group_invitation])
    @user.confirmed_at = Time.now if @group_invitation

    success = @user && @user.save
    if success && @user.errors.empty?

      @group_invitation.push(:user_ids => @user.id) if @group_invitation

      current_group.add_member(@user)
      track_event(:sign_up, :user_id => @user.id, :confirmed => @user.confirmed?)
      flash[:conversion] = true

      # Protects against session fixation attacks, causes request forgery
      # protection if visitor resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      @user.localize(request.remote_ip)
      if @user.active?
        flash[:notice] = t("welcome", :scope => "users.create")
      else
        flash[:notice] = t("confirm", :scope => "users.create")
      end
      sign_in_and_redirect(:user, @user) # !! now logged in
    else
      flash[:error]  = t("flash_error", :scope => "users.create")
      render :action => 'new'
    end
  end
end


