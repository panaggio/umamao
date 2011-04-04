class QuestionList < Topic
  key :main_topic_id, ObjectId, :index => true, :required => true
  belongs_to :main_topic, :class_name => "Topic"

  key :topic_ids, Array, :index => true
  many :topics, :in => :topic_ids

  key :question_ids, Array, :index => true
  many :questions, :in => :question_ids

  key :user_id, String, :index => true
  belongs_to :user
end
