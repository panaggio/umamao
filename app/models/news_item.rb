class NewsItem
  include MongoMapper::Document

  key :recipient_id, :required => true
  key :recipient_type, :required => true
  belongs_to :recipient, :polymorphic => true

  key :news_update_id, ObjectId, :required => true
  belongs_to :news_update

  # origin is the reason why this update made its way to the
  # recipient: a user, topic or question she was following.
  key :origin_id, :required => true
  key :origin_type, :required => true
  belongs_to :origin, :polymorphic => true

  ensure_index([[:recipient_id, 1], [:created_at, -1]])

  timestamps!

  # Notifies each recipient of a news update
  def self.from_news_update!(news_update)
    origins = [news_update.author] + news_update.entry.topics
    notify!(news_update, news_update.author, news_update.author)
    notified_users = Set.new [news_update.author]

    origins.each do |origin|
      origin.followers.each do |follower|
        next if notified_users.include?(follower)
        notify!(news_update, follower, origin)
        notified_users << follower
      end
    end

    news_update.entry.topics.each do |topic|
      notify!(news_update, topic, topic)
    end
  end

  # Notifies a single recipient
  def self.notify!(news_update, recipient, origin)
    create(
      :news_update => news_update,
      :recipient => recipient,
      :origin => origin
    )
  end

  def title
    self.news_update.entry.title
  end
end
