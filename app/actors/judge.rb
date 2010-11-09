require File.dirname(__FILE__)+"/env"

module Actors
  # /actors/judge
  class Judge
    include Magent::Actor

    expose :post_to_twitter

    def post_to_twitter(payload)
      user = User.find(payload.first)

      client = TwitterOAuth::Client.new(
        :consumer_key => AppConfig.twitter["key"],
        :consumer_secret => AppConfig.twitter["secret"],
        :token => user.twitter_token,
        :secret => user.twitter_secret
      )

      client.update(payload[1])
    end

  end
  Magent.register(Judge.new)
end

if $0 == __FILE__
  Magent::Processor.new(Magent.current_actor).run!
end
