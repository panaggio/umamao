class SuggestionList
  include MongoMapper::EmbeddedDocument

  key :user_id, String
  belongs_to :user

  key :last_modified_at, Time

  key :suggested_topic_ids, Array, :default => []

  def suggested_topics(count = 5)
    if Time.now - self.last_modified_at > 1.week
      self.refresh_suggestions!
    end
    Topic.query(:id.in => self.suggested_topic_ids[0 .. count])
  end

  key :uninteresting_topic_ids, Array, :default => []
  has_many :uninteresting_topics, :class_name => "Topic",
    :in => :uninteresting_topic_ids

  key :suggested_user_ids, Array, :default => []

  def suggested_users(count = 5)
    User.query(:id.in => self.suggested_user_ids[0 .. count])
  end

  key :uninteresting_user_ids, Array, :default => []
  has_many :uninteresting_users, :class_name => "User",
    :in => :uninteresting_user_ids

  def suggest(thing)
    # For some reason, the case statement wasn't working.
    if thing.is_a?(Topic)
      if !self.suggested_topic_ids.include?(thing.id) &&
          !thing.follower_ids.include?(self.user_id) &&
          !self.uninteresting_topic_ids.include?(thing.id)
        self.suggested_topic_ids << thing.id
      end
    elsif thing.is_a?(User)
      if !self.suggested_user_ids.include?(thing.id) &&
          !self.user.following?(thing) &&
          !self.uninteresting_user_ids.include?(thing.id)
        self.suggested_user_ids << thing.id
      end
    elsif thing.respond_to?(:each)
      thing.each do |t|
        self.suggest(t)
      end
    else
      raise "Entity can't be suggested to a user: #{thing.class}"
    end
  end

  def suggest!(thing)
    self.suggest(thing)
    self.save!
  end

  def remove_suggestion(thing)
    case thing
    when Topic
      self.suggested_topic_ids.delete(thing.id)
    when User
      self.suggested_user_ids.delete(thing.id)
    end
  end

  def mark_as_uninteresting(thing)
    case thing
    when Topic
      self.suggested_topic_ids.delete(thing.id)
      if !self.uninteresting_topic_ids.include?(thing.id)
        self.uninteresting_topic_ids << thing.id
      end
    when User
      self.suggested_user_ids.delete(thing.id)
      if !self.uninteresting_user_ids.include?(thing.id)
        self.uninteresting_user_ids << thing.id
      end
    else
      raise "Entity can't be suggested to a user"
    end
  end

  def suggest_random_topics
    failed = 0
    while self.suggested_topic_ids.length < 13 && failed < 30
      topic = Topic.query(:offset => 5 + rand(50)).first
      if self.suggested_topic_ids.include?(topic.id) ||
          self.uninteresting_topic_ids.include?(topic.id) ||
          topic.follower_ids.include?(self.user_id)
        # We cannot suggest this topic
        failed += 1
        next
      end
      self.suggested_topic_ids << topic.id
    end
  end

  def refresh_suggestions!(type = :all)
    if [:all, :topics].include?(type)
      self.refresh_topic_suggestions
    else
      raise "Don't know how to suggest #{type}"
    end

    self.last_modified_at = Time.now

    self.save!
  end

  def refresh_topic_suggestions
    if self.suggested_topic_ids.length < 8 &&
        Topic.query(:follower_ids => self.user_id).count == 0
      # If user doesn't follow anything, we show the most popular
      # topics, and some random ones.
      Topic.query(:order => :questions_count.desc, :limit => 6).each do |topic|
        unless self.uninteresting_topic_ids.include?(topic.id)
          self.suggested_topic_ids << topic.id
        end
      end

      self.suggest_random_topics
      self.save!
      return
    end

    count = {}

    Topic.query(:follower_ids => self.user_id, :select => [:id, :title]).each do |topic|
      Question.query(:topic_ids => topic.id, :select => :topic_ids).each do |question|
        question.topics.each do |related_topic|
          next if related_topic.id == topic.id ||
            related_topic.follower_ids.include?(self.user_id) ||
            self.uninteresting_topic_ids.include?(related_topic.id)
          count[related_topic.id] = (count[related_topic.id] || 0) + 1
        end
      end
    end

    self.suggested_topic_ids = count.to_a.sort do |a,b|
      -(a[1] <=> b[1])
    end[0 .. 49].map {|v| v[0]}
    if self.suggested_topic_ids.length < 10
      self.suggest_random_topics
    end

    self.save!

  end

end
