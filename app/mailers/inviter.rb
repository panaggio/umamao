class Inviter < ActionMailer::Base
  default :from => AppConfig.notification_email

  helper :application

  def invitation(invitation)
    @sender = invitation.sender
    @group = invitation.group
    @recipient_email = invitation.recipient_email
    @message = invitation.message
    @invitation_token = invitation.invitation_token
    @topics = invitation.topics

    mail(:to => @recipient_email, :subject => t('inviter.invitation.subject',
                                                :inviter => @sender.name))
  end

  def request_answer(answer_request, sender)
    @sender = sender
    @group = sender.groups[0] if sender && sender.groups.present?
    @invited = answer_request.invited
    @recipient_email = answer_request.invited.email
    @message = answer_request.message
    @question = answer_request.question
    mail(:to => @recipient_email, :subject => t('inviter.request_answer.subject',
                                                :user => @sender.name))
  end
end
