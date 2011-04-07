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
end
