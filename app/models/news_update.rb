class NewsUpdate
  include MongoMapper::Document

  key :author_id, String, :required => true, :index => true
  belongs_to :author, :class_name => 'User'

  key :entry_id, :required => true
  key :entry_type, :required => true
  belongs_to :entry, :polymorphic => true

  has_many :news_items, :dependent => :destroy

  key :action, String, :required => true, :in => %w[created upvoted]

  timestamps!

  after_create :create_news_items

  def create_news_items
    NewsItem.from_news_update!(self)
  end
  handle_asynchronously :create_news_items

end
