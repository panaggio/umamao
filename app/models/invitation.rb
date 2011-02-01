# -*- coding: utf-8 -*-
class Invitation
  include MongoMapper::Document
  include Support::TokenConfirmable

  @@token_confirmable_key = :invitation_token

  key :_id, String
  key :sender_id, String, :required => true, :index => true
  belongs_to :sender, :class_name => 'User'
  key :recipient_id, String
  belongs_to :recipient, :class_name => 'User'
  key :recipient_email, String, :required => true, :unique => true
  key :message, String
  key :accepted_at, Time
  key :invitation_token, String, :index => true
  key :sent_at, Time
  key :group_id, String
  belongs_to :group

  token_confirmable_key :invitation_token

  after_create :send_invitation

  validate_on_create :recipient_is_not_user

  ensure_index([[:created_at, -1]])

  timestamps!

  # Send confirmation instructions by email
  def send_invitation
    generate_invitation_token! if self.invitation_token.nil?
    Inviter.delay.invitation(self)
  end

  private
  def recipient_is_not_user
    if User.find_by_email(self.recipient_email)
      self.errors.add(:email, "já está cadastrado no Umamão!")
    end
  end

end
