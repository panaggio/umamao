class UserSuggestion < Suggestion
  include MongoMapper::Document
  key :origin_id, :required => true, :index => true
  belongs_to :origin, :class_name => 'User'

  validates_uniqueness_of :user_id, :scope => [ :origin_id, :entry_id ]

  validate :user_dont_follow_entry?

  def user_dont_follow_entry?
    if self.user.following?(self.entry)
      self.errors.add(:user_id,
                      "User already follows that entry")
    end
  end
end
