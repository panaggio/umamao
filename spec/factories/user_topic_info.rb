Factory.define :user_topic_info do |ut|
  ut.association :user
  ut.association :topic
end
