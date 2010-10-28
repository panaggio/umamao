class NewsUpdate
  include MongoMapper::Document

  key :author_id, String, :required => true, :index => true
  belongs_to :author, :class_name => 'User'

  key :entry_id, :required => true
  key :entry_type, :required => true
  belongs_to :entry, :polymorphic => true

  key :action, String, :required => true, :in => %w[created upvoted]

  timestamps!
end
