class UserSuggestion < Suggestion
  include MongoMapper::Document
  key :origin_id, :required => true, :index => true
  belongs_to :origin, :class_name => 'User'

  validates_uniqueness_of :user_id, :scope => [ :origin_id, :entry_id ]

  validate :user_dont_follow_entry?

  after_save :send_notification

  def send_notification
    # FIXME: by the time notifications send e-mail, send invitation will
    # not be necessary anymore
    Notifier.new_user_suggestion(self.user, self.origin, self.entry).deliver

    Notification.new(
      :user => self.user,
      :event_type => 'new_user_suggestion',
      :origin_id => self.origin_id,
      :reason => self,
      :topic_id => self.entry_id
    ).save!
  end
  handle_asynchronously :send_notification

  def user_dont_follow_entry?
    if self.user.following?(self.entry)
      self.errors.add(:user_id,
                      "User already follows that entry")
    end
  end
end
