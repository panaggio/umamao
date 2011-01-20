class SuggestionList
  include MongoMapper::EmbeddedDocument

  belongs_to :user

  key :suggested_topic_ids, Array, :default => []

  def suggested_topics(count = 5)
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

  def refresh_suggestions(type = :all)
    if [:all, :topics].include?(type)
      self.refresh_topic_suggestions
    else
      raise "Don't know how to suggest #{type}"
    end
  end

  def refresh_topic_suggestions
    count = {}

    Topic.query(:follower_ids => self.user.id).each do |topic|
      topic.related_topics.each do |related_topic|
        next if related_topic.follower_ids.include?(self.user.id) ||
          self.uninteresting_topic_ids.include?(self.user.id)
        count[related_topic.id] = (count[related_topic.id] || 0) + 1
      end
    end

    self.suggested_topic_ids = count.to_a.
      sort{|a,b| -(a[1] <=> b[1])}[0 .. 29].map(&:first)
  end

end
