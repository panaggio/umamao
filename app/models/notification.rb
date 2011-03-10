# Notification messages shown to users.

class Notification
  include MongoMapper::Document

  timestamps!

  belongs_to :user

  key :event_type, String, :required => true

  belongs_to :origin, :class_name => "User"

  belongs_to :question

  def unread?
    !self.user.last_read_notifications_at ||
      self.user.last_read_notifications_at < self.created_at
  end
end
