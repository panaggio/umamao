class Affiliation
  include MongoMapper::Document
  include Support::TokenConfirmable

  @@token_confirmable_key = :affiliation_token

  key :confirmed_at, Time, :default => nil
  key :user_id, String
  key :university_id, ObjectId
  key :email, String, :limit => 40, :default => nil
  key :affiliation_token, String, :index => true
  key :sent_at, Time
  
  token_confirmable_key :affiliation_token

  belongs_to :university
  belongs_to :user

  validates_true_for :email, :logic => lambda {
    (self.email =~ self.university.email_regexp) != nil
  }

  validates_uniqueness_of :email
  validates_presence_of :email

  after_create  :send_confirmation
end
