class WaitingUser
  include MongoMapper::Document

  key :_id, String
  key :email, String
  key :university, String #legacy

  timestamps!

  validates_presence_of :email
  validates_uniqueness_of :email
end
