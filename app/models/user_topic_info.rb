class UserTopicInfo
  include MongoMapper::Document

  key :user_id, String, :required => true, :index => true
  belongs_to :user

  key :topic_id, ObjectId, :required => true, :index => true
  belongs_to :topic

  key :followed_at, Date
  key :ignored_at, Date
  key :answers_count, Integer, :default => 0
  key :questions_count, Integer, :default => 0

  validates_uniqueness_of :user_id, :scope => [:topic_id]
  ensure_index([[:user_id, 1], [:topic_id, 1]])

  def followed?
    self.followed_at.present?
  end

  def follow!
    self.followed_at ||= Time.now
  end

  def unfollow!
    self.followed_at = nil
  end

  def ignored?
    self.ignored_at.present?
  end

  def ignore!
    self.ignored_at ||= Time.now
  end

  def unignore!
    self.ignored_at = nil
  end

  def self.question_added!(question)
    question.topics.each do |topic|
      update_question_topic(question.user, topic)
    end
  end

  def self.question_removed!(question)
    question.topics.each do |topic|
      update_question_topic(question.user, topic, -1)
    end
  end

  def self.answer_added!(answer)
    answer.question.topics.each do |topic|
      update_answer_topic(answer.user, topic)
    end
  end

  def self.answer_removed!(answer)
    answer.question.topics.each do |topic|
      update_answer_topic(answer.user, topic, -1)
    end
  end

  def self.question_classified!(question, topic)
    # Update questions and answers_count
    update_question_topic(question.user, topic)

    Answer.fields([:user_id]).find_each(:question_id => question.id) do |answer|
      update_answer_topic(answer.user, topic)
    end
  end

  def update_counts
     self.answers_count = Answer.fields([:question_id]).query(
       :user_id => user.id).select{|a| a.question &&
         a.question.topic_ids.include?(self.topic_id)}.size
     self.questions_count = Question.count(:user_id => self.user_id, 
                                           :topic_ids => self.topic_id)
     self.save!
  end

  private

  def self.update_question_topic(user, topic, increment=1)
    user_topic = UserTopicInfo.first(:topic_id => topic.id,
                                     :user_id => user.id)
    if user_topic
      user_topic.questions_count += increment
      user_topic.save
    else
      increment = [increment, 0].max
      UserTopicInfo.create(:topic_id => topic.id, :user_id => user.id,
                           :questions_count => increment)
    end
  end

  def self.update_answer_topic(user, topic, increment=1)
    user_topic = UserTopicInfo.first(:topic_id => topic.id,
                                     :user_id => user.id)
    if user_topic
      user_topic.answers_count += increment
      user_topic.save
    else
      increment = [increment, 0].max
      UserTopicInfo.create(:topic_id => topic.id, :user_id => user.id,
                           :answers_count => increment)
    end
  end

end
