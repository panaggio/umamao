class NewsItem
  include MongoMapper::Document

  key :recipient_id, :required => true
  belongs_to :recipient, :class_name => 'User'

  key :news_update_id, ObjectId, :required => true
  belongs_to :news_update

  # origin is the reason why this update made its way to the
  # recipient: a user, topic or question she was following.
  key :origin_id, :required => true
  key :origin_type, :required => true
  belongs_to :origin, :polymorphic => true

  ensure_index([[:recipient_id, 1], [:created_at, -1]])

  timestamps!

  def self.from_news_update!(news_update)
    origins = [news_update.author] + news_update.entry.topics
    notified_users = []

    origins.each do |origin|
      origin.followers.each do |follower|
        next if notified_users.include?(follower)
        news_item = self.create(
          :news_update => news_update,
          :recipient => follower,
          :origin => origin
        )
        notified_users << follower
      end
    end
  end

  def title
    self.news_update.entry.title
  end
end
