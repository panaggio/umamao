class Affiliation
  include MongoMapper::Document

  key :confirmed_at, Time, :default => nil
  key :user_id, String
  key :university_id, ObjectId
  key :email,            String, :limit => 40, :default => nil
  
  belongs_to :university
  belongs_to :user

  validates_uniqueness_of   :email
  validates_format_of       :email, :with => lambda { |u|
                                               u.university.email_regexp
											 }

end
