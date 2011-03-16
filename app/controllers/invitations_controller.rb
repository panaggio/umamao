class InvitationsController < ApplicationController
  before_filter :login_required

  def pending
    @pending_invitations = Invitation.query(:sender_id => current_user.id,
                                            :accepted_at => nil,
                                            :order => :created_at.desc)
  end

  def accepted
    @accepted_invitations = Invitation.query(:sender_id => current_user.id,
                                             :accepted_at.ne => nil,
                                             :order => :created_at.desc)
  end

  def new
    @fetching_contacts = params[:wait].present?
  end

  def create
    @emails = params[:emails]
    @message = params[:message]

    if Invitation.invite_emails!(current_user, current_group,
                                 @message, @emails) > 0
      track_event(:sent_invitation)
      redirect_to new_invitation_path
    else
      render :new
    end
  end
end
