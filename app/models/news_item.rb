class NewsItem
  include MongoMapper::Document

  key :recipient_id, :required => true
  key :recipient_type, :required => true
  belongs_to :recipient, :polymorphic => true

  key :news_update_id, ObjectId, :required => true
  belongs_to :news_update
  key :news_update_entry_type, String
  key :open_question, Boolean

  # origin is the reason why this update made its way to the
  # recipient: a user, topic or question she was following.
  key :origin_id, :required => true
  key :origin_type, :required => true
  belongs_to :origin, :polymorphic => true

  ensure_index([[:recipient_id, 1], [:created_at, -1]])

  timestamps!

  # Notifies each recipient of a news update. The creation date will
  # be the same as the news update's.
  def self.from_news_update!(news_update)
    logger.debug "news_items.news_update_entry_type=#{news_update.entry_type}"
    news_update.news_items.each do |ni|
      ni.news_update_entry_type = news_update.entry_type
      case ni.news_update_entry_type
      when "Question"
        ni.open_question = news_update.entry.is_open
      #when "Answer"
      #  ni.open_question = news_update.entry.question.is_open
      end
      ni.save
    end

    origins = [news_update.author] + news_update.entry.topics
    notify!(news_update, news_update.author,
            news_update.author, news_update.created_at)
    notified_users = Set.new [news_update.author]

    origins.each do |origin|
      origin.followers.each do |follower|
        next if notified_users.include?(follower)
        notify!(news_update, follower, origin, news_update.created_at)
        notified_users << follower
      end
    end

    news_update.entry.topics.each do |topic|
      notify!(news_update, topic, topic, news_update.created_at)
    end
  end

  # Notifies a single recipient. Allows us to specify when the item
  # was created.
  def self.notify!(news_update, recipient, origin, created_at = nil)
    news_item = create(:news_update => news_update,
               :recipient => recipient,
               :origin => origin)
    if created_at
      news_item.created_at = created_at
      news_item.save
    end

    news_item
  end

  def title
    self.news_update.entry.title
  end
end
