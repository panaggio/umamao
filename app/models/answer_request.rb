# -*- coding: utf-8 -*-
class AnswerRequest
  include MongoMapper::Document

  after_create :send_invitation, :create_notification

  key :sender_ids, Array
  has_many :senders, :class_name => 'User', :in => :sender_ids
  key :invited_id, String
  belongs_to :invited, :class_name => 'User'
  key :question_id, String
  belongs_to :question
  key :message, String
  key :accepted_at, Time
  key :rejected, Boolean, :default => false

  timestamps!

  # Send confirmation instructions by email
  def send_invitation
    Inviter.delay.request_answer(self, self.senders[0])
  end

  def create_notification
    Notification.create!(:user => self.invited,
                         :event_type => "new_answer_request",
                         :origin => self.senders[0],
                         :reason => self)
  end
  handle_asynchronously :create_notification

end
