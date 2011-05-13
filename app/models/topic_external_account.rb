# These external accounts get updates from events on the topic, such
# as a new question being posted. Right now, topics can only have
# associated Twitter accounts.

class TopicExternalAccount < ExternalAccount
  belongs_to :topic
end
