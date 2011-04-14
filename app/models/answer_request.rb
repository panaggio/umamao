# -*- coding: utf-8 -*-
class AnswerRequest
  include MongoMapper::Document

  after_create :send_invitation

  key :sender_ids, Array
  has_many :senders, :class_name => 'User', :in => :sender_ids
  key :invited_id, String
  belongs_to :invited, :class_name => 'User'
  key :question_id, String
  belongs_to :question
  key :message, String
  key :accepted_at, Time
  key :rejected, Boolean, :default => false
  key :sent_at, Time

  # Send confirmation instructions by email
  def send_invitation
    Inviter.delay.request_answer(self, self.senders[0])
  end

end
