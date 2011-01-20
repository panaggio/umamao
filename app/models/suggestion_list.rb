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

  # Add things to the user's suggestion lists, ignoring the ones that
  # were already suggested, followed, or marked as
  # uninteresting. Works on enumerables as well.
  #
  # options:
  # - limit: maximum number of things to suggest
  #
  def suggest(thing, options = {})
    limit = options[:limit]
    # For some reason, the case statement wasn't working.
    if thing.is_a?(Topic)
      if !self.suggested_topic_ids.include?(thing.id) &&
          !thing.follower_ids.include?(self.user_id) &&
          !self.uninteresting_topic_ids.include?(thing.id)
        self.suggested_topic_ids << thing.id
        return 1
      end
    elsif thing.is_a?(User)
      if !self.suggested_user_ids.include?(thing.id) &&
          !self.user.following?(thing) &&
          !self.uninteresting_user_ids.include?(thing.id)
        self.suggested_user_ids << thing.id
        return 1
      end
    elsif thing.respond_to?(:each)
      total = 0
      thing.each do |t|
        break if limit.present? && total >= limit
        total += self.suggest(t)
      end
      return total
    else
      raise "Entity can't be suggested to a user: #{thing.class}"
    end
    return 0
  end

  # Remove a thing from the list of suggestions.
  def remove_suggestion(thing)
    case thing
    when Topic
      self.suggested_topic_ids.delete(thing.id)
    when User
      self.suggested_user_ids.delete(thing.id)
    end
  end

  # Mark something as uninteresting. Uninteresting users and topics
  # will be ignored in future suggestions.
  def mark_as_uninteresting(thing)
    case thing
    when Topic
      if !self.uninteresting_topic_ids.include?(thing.id)
        self.uninteresting_topic_ids << thing.id
      end
    when User
      if !self.uninteresting_user_ids.include?(thing.id)
        self.uninteresting_user_ids << thing.id
      end
    else
      raise "Entity can't be suggested to a user"
    end
  end

  # Refuse a suggestion. Refused suggestions cannot be re-suggested.
  def refuse_suggestion(thing)
    self.remove_suggestion(thing)
    self.mark_as_uninteresting(thing)
  end

  # Find suggestions from the user's external accounts.
  def suggest_from_outside
    self.suggest(self.user.find_external_contacts)
    self.suggest(self.user.find_external_topics)
  end

  # Suggest the 20 most followed topics.
  def suggest_popular_topics
    self.suggest(Topic.query(:order => :followers_count.desc),
                 :limit => 20)
  end

  # Populate the user's suggestion list for the signup wizard.
  def find_first_suggestions
    if self.suggested_topic_ids.blank? &&
        self.suggested_user_ids.blank?
      self.suggest_from_outside
      self.suggest_popular_topics
    end
  end

  # Recalculate suggestions for the user.
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
