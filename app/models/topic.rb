class Topic
  include MongoMapper::Document
  include MongoMapperExt::Slugizer
  include MongoMapperExt::Filter
  include Support::Versionable

  key :title, String, :required => true, :index => true, :unique => true
  filterable_keys :title
  key :description, String
  key :questions_count, :default => 0

  key :updated_by_id, String
  belongs_to :updated_by, :class_name => "User"

  key :follower_ids, Array, :index => true
  has_many :followers, :class_name => 'User', :in => :follower_ids

  slug_key :title, :unique => true, :min_length => 3

  has_many :news_items, :foreign_key => :recipient_id, :dependent => :destroy

  timestamps!

  versionable_keys :title, :description

  before_save :generate_slug

  # Takes array of strings and returns array of topics with matching
  # titles, creating new topics for titles that are not found.
  def self.from_titles!(titles)
    return [] if titles.blank?
    self.all(:title.in => titles).tap { |topics|
      if topics.size != titles.size
        new_titles = titles - topics.map(&:title)
        new_topics = new_titles.map {|t| self.create(:title => t) }
        topics.push(*new_topics)
      end
    }
  end

  def name
    title
  end

  # Merges other to self: self receives every question, follower and
  # news update from other. Destroys other. Cannot be undone.
  def merge_with!(other)
    other.followers.each do |f|
      if !follower_ids.include? f.id
        followers << f
      end
    end

    Question.query(:topic_ids => other.id).each do |q|
      q.classify! self
    end

    # TODO: check whether this is actually safe.
    other.news_items.each do |item|
      if NewsItem.query(:recipient_id => id,
                         :recipient_type => "Topic",
                         :news_update_id => item.id).count == 0
        item.recipient = self
        item.save
      end
    end

    NewsItem.query(:origin_id => other.id, :origin_type => "Topic").each do |item|
      item.origin = self
      item.save
    end

    other.destroy
    save
  end

end
