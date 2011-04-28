class Affiliation
  include MongoMapper::Document
  include Support::TokenConfirmable

  @@token_confirmable_key = :affiliation_token
  token_confirmable_key :affiliation_token

  key :confirmed_at, Time, :default => nil
  key :user_id, String
  key :university_id, ObjectId
  key :student_id, ObjectId
  key :email, String, :length => 256, :default => nil
  key :affiliation_token, String, :index => true
  key :sent_at, Time

  belongs_to :university
  belongs_to :user
  belongs_to :student

  timestamps!

  validates_true_for :email, :logic => lambda {
    (self.email =~ self.university.email_regexp) != nil
  }

  validates_format_of :email, :with => Devise::email_regexp
  validates_uniqueness_of :email
  validates_presence_of :email

  before_validation :strip_email
  after_create :send_confirmation
  after_save :set_user_in_student

  def send_confirmation
    return if self.confirmed_at.present? # We don't need to confirm this.
    if self.university.open_for_signup
      generate_affiliation_token! if self.affiliation_token.nil?
      Notifier.delay.signup(self)
    else
      Notifier.delay.closed_for_signup(self)
    end
  end

  def self.resend_confirmation(email)
    where(:email => email).first.send_confirmation
  end

  # Confirm the affiliation.
  def confirm
    self.confirmed_at = Time.now
  end

  # Return true if this affiliation has been confirmed.
  def confirmed?
    self.confirmed_at.present?
  end

  def strip_email
    self.email = self.email.strip if self.email
  end

  # Associate this affiliation's Student with the corresponding User.
  def set_user_in_student
    if self.student.present? && self.student.user.blank?
      self.student.user = self.user
      self.student.save!
    end
  end

end
