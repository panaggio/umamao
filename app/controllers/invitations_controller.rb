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

    @faulty_emails = flash[:faulty_emails]
  end

  def create
    @emails = params[:emails]
    @message = params[:message]

    count, @faulty_emails =
      current_user.invite!(@emails, current_group, @message)

    if @faulty_emails.present?
      flash[:faulty_emails] = @faulty_emails
    end

    if count && count > 0
      track_event(:sent_invitation, :count => count)
    end

    redirect_to new_invitation_path

  end

  def new_invitation_student
    @course = Course.find_by_slug_or_id(params[:id])
    @student = Student.find_by_id(params[:student_id])

    respond_to do |format|
      format.js do
        render :json => {
          :success => true,
          :html => render_to_string(:layout => false)
        }
      end
      format.html
    end
  end

  def create_invitation_student
    s = Student.find_by_id(params[:student_id])
    if s.academic_email
      invitation = Invitation.new(:sender_id => current_user.id,
                     :group_id => current_group.id,
                     :message => params[:message],
                     :topic_id => params[:course_id],
                     :recipient_email => s.academic_email)
      invitation.save!
    end

    respond_to do |format|
      format.js do
        render :json => {
          :success => true,
          :message => t("invitations.sent")
        }
       format.html
      end
    end
  end

  def resend
    invitation = Invitation.find_by_id(params[:id])
    invitation.send_invitation
    respond_to do |format|
      format.js do
        render :json => {
          :success => true,
          :message => t("invitations.sent")
        }
       format.html
      end
    end
  end
end
