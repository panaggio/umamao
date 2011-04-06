class QuestionList < Topic
  key :main_topic_id, ObjectId, :index => true, :required => true
  belongs_to :main_topic, :class_name => "Topic"

  key :topic_ids, Array, :index => true
  many :topics, :in => :topic_ids

  key :user_id, String, :index => true
  belongs_to :user

  # Classifies self under topic topic.
  def classify!(topic)
    if !topic_ids.include? topic.id
      self.topic_ids_will_change!
      self.topic_ids << topic.id
      self.needs_to_update_search_index
      save!
    else
      false
    end
  end

  # Removes self from topic topic.
  def unclassify!(topic)
    if topic_ids.include? topic.id
      self.topic_ids_will_change!
      self.topic_ids.delete topic.id
      self.needs_to_update_search_index
      save!
    else
      false
    end
  end
end
