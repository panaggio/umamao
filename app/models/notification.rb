# Notification messages shown to users.

class Notification
  include MongoMapper::Document

  timestamps!

  belongs_to :user

  key :event_type, String, :required => true

  key :data, Hash, :required => true

  def unread?
    !self.user.last_read_notifications_at ||
      self.user.last_read_notifications_at < self.created_at
  end

  def info
    @info ||=
      begin
        info = {}
        info[:user] = User.find_by_id(self.data[:user_id])
        if self.data[:question_id]
          info[:question] = Question.find_by_id(self.data[:question_id])
        end
        info
      end
  end
end
