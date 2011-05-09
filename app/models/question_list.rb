class QuestionList < Topic
  key :main_topic_id, ObjectId, :index => true, :required => true
  belongs_to :main_topic, :class_name => "Topic"

  key :topic_ids, Array, :index => true
  many :topics, :in => :topic_ids

  key :user_id, String, :index => true
  belongs_to :user

  has_many :question_list_files, :dependent => :destroy

  after_create :add_author_as_follower

  def initialize(options = {})
    if options[:topics].present?
      options[:topic_ids] = options[:topics].map(&:id)
      options.delete :topics
    elsif options[:topic_ids].blank?
      # Use "solved exercices" topic by default
      options[:topic_ids] = [BSON::ObjectId('4cbefdbb79de4f58ea00012c')]
    end

    super
  end

  def default_question_order
    :created_at
  end

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

  protected

  def add_author_as_follower
    self.add_follower!(self.user)
  end
end
