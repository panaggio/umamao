class Suggestion
  include MongoMapper::Document

  key :user_id, :required => true, :index => true
  belongs_to :user

  key :entry_id, :required => true
  key :entry_type, :required => true
  belongs_to :entry, :polymorphic => true

  ensure_index([[:entry_id, 1], [:entry_type, 1]])

  key :reason, String

  timestamps!

  def reject!
    self.destroy
  end
end
