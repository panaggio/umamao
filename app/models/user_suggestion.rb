class UserSuggestion < Suggestion
  include MongoMapper::Document
  key :origin_id, :required => true, :index => true
  belongs_to :origin, :class_name => 'User'

  key :accepted_at, Date
  key :rejected_at, Date

  validates_uniqueness_of :user_id, :scope => [ :origin_id, :entry_id ],
    :message => lambda { 'already have been suggested that topic by origin' }

  validate :user_is_origin?
  validate :user_follow_entry?

  after_create :send_notification

  def accepted?
    !!self.accepted_at
  end

  def rejected?
    !!self.rejected_at
  end

  def accept!
    self.accepted_at = Time.zone.now
    self.save!
  end

  def delete!
    self.destroy
  end

  def reject!
    self.rejected_at = Time.zone.now
    self.save!
  end

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

  def user_is_origin?
    if self.user == self.origin
      self.errors.add_to_base('User and origin are the same')
    end
  end

  def user_follow_entry?
    if self.user.following?(self.entry)
      self.errors.add(
        :user_id, 'already follows entry')
    end
  end
end
