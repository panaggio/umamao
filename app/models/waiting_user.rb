class WaitingUser
  include MongoMapper::Document

  key :_id, String
  key :email, String
  key :university, String
  key :confirmation_token, String, :index => true

  timestamps!

  validates_format_of :email, :with => Devise::email_regexp
  validates_presence_of   :email
  validates_uniqueness_of :email
  after_create            :send_wait_note

  def non_academic_email?
    self.email =~ /\.com(\.|$)/
  end

  def send_wait_note
    if non_academic_email?
      Notifier.delay.non_academic(self)
    else
      Notifier.delay.wait(self)
    end
  end

  def self.resend_wait_note(email)
    where(:email=>email).first.send_wait_note
  end
end
