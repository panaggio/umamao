# -*- coding: utf-8 -*-
class AnswerRequest
  include MongoMapper::Document

  key :sender_ids, Array
  has_many :senders, :class_name => 'User'
  key :invited_id, String
  belongs_to :invited, :class_name => 'User'
  key :message, String
  key :accepted_at, Time
  key :rejected, Boolean, :default => false
  key :sent_at, Time

end
