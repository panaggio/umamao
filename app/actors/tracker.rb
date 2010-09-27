require File.dirname(__FILE__)+"/env"

module Actors
  class Tracker
    include Magent::Actor

    expose :track_event

    def track_event(payload)
      event, user_id, ip, properties = payload
      user = User.find(user_id)
      user_email = nil

      if user
        properties.reverse_merge!({
          :questions_count => user.questions.count,
          :answers_count => user.answers.count,
          :votes_count => user.votes.count,
          :invited => user.invitation_token.present?,
          :academic_email => user.academic_email
        })
        user_email = user.email
      end

      Mixpanel.log_event(event, user_email, ip, properties)
    end
  end

  Magent.register(Tracker.new)
end

if $0 == __FILE__
  Magent::Processor.new(Magent.current_actor).run!
end
