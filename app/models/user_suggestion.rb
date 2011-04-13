class UserSuggestion < Suggestion
  include MongoMapper::Document
  key :origin_id, :required => true, :index => true
  belongs_to :origin, :class_name => 'User'

  validates_uniqueness_of :user_id, :scope => [ :origin_id, :entry_id ]

  validate :user_dont_follow_entry?

  # FIXME: by the time notifications send e-mail, send invitation will
  # not be necessary anymor
  after_create :send_notification, :send_invitation

  def send_invitation
  end

  def send_notification
    Notification.new(
      :user => self.user,
      :event_type => 'new_user_suggestion',
      :origin_id => self.origin_id,
      :reason => self,
      :topic_id => self.entry_id
    ).save!
  end

  def user_dont_follow_entry?
    if self.user.following?(self.entry)
      self.errors.add(:user_id,
                      "User already follows that entry")
    end
  end
end
