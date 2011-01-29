module Tracking
class EventTracker
  def self.track_event(payload)
    event, user_id, ip, properties = payload
    user = User.find(user_id)
    user_email = nil

    if user
      properties.reverse_merge!({
                                  :questions_count => user.questions.count,
                                  :answers_count => user.answers.count,
                                  :votes_count => user.votes.count,
                                  :invited => user.invitation_token.present?,
                                  :email => user.email
                                })
      user_email = user.email
    end

    Mixpanel.log_event(event, user_email, ip, properties)
  end
end
end
