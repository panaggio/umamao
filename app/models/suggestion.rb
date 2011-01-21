class Suggestion
  include MongoMapper::Document

  key :user_id, :required => true, :index => true
  belongs_to :user

  key :entry_id, :required => true
  key :entry_type, :required => true
  belongs_to :entry, :polymorphic => true

  key :reason, String

  timestamps!
end
