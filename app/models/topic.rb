class Topic
  include MongoMapper::Document
  include MongoMapperExt::Slugizer
  include Support::Versionable

  key :title, String, :required => true, :index => true, :unique => true
  key :description, String
  key :questions_count, :default => 0

  key :updated_by_id, String
  belongs_to :updated_by, :class_name => "User"

  slug_key :title, :unique => true, :min_length => 3

  timestamps!

  versionable_keys :title, :description

  # Takes array of strings and returns array of topics with matching
  # titles, creating new topics for titles that are not found.
  def self.from_titles!(titles)
    return if titles.blank?
    titles = titles.map(&:strip)
    self.all(:title.in => titles).tap { |topics|
      if topics.size != titles.size
        new_titles = titles - topics.map(&:title)
        new_topics = new_titles.map {|t| self.create(:title => t) }
        topics.push(*new_topics)
      end
    }
  end

end
