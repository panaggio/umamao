# -*- coding: utf-8 -*-
class Invitation
  include MongoMapper::Document

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

  before_create :generate_invitation_token
  after_create :send_invitation

  validate_on_create :recipient_is_not_user

  ensure_index([[:created_at, -1]])

  timestamps!

  # stolen from devise (TODO place this somewhere common to affiliation
  # and invitation)
  def self.generate_token
    loop do
      token = ActiveSupport::SecureRandom.base64(15).tr('+/=', '-_ ').strip.
        delete("\n")
      break token unless self.where(:invitation_token => token).count > 0
    end
  end

  def generate_invitation_token
    self.invitation_token = nil
    self.invitation_token = self.class.generate_token
    self.sent_at = Time.now.utc
  end

  def generate_invitation_token!
    generate_invitation_token && save(:validate => false)
  end

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
