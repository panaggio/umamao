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
    set_page_title(t("invitations.new.title"))
    @fetching_contacts = params[:wait].present?
    @has_contacts = current_user.contacts.count > 0

    @pending_invitations =
      current_user.invitations.query(:accepted_at => nil)

    @accepted_invitations =
      current_user.invitations.query(:accepted_at.ne => nil)
  end

  def create
    @emails = params[:emails]
    @message = params[:message]

    count =
      if @emails.present?
        Invitation.invite_emails!(current_user, current_group,
                                  @message, @emails)
      else
        0
      end

    if count > 0
      track_event(:sent_invitation, :count => count)
    end
    redirect_to new_invitation_path

  end
end
