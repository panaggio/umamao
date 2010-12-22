class Affiliation
  include MongoMapper::Document

  key :_id, String
  key :confirmation_status, String, :default => false
  key :user_id, String
  key :email,            String, :limit => 40, :default => nil
  
  belongs_to :university
  belongs_to :user

  validates_uniqueness_of   :email, :if => lambda { |u| u.new_record? && u.user.confirmed_at.blank? }
  validates_format_of       :email, :with => lambda { |u| u.university.email_regexp },
                            :if => lambda { |u| u.new_record? && u.user.confirmed_at.blank? }

end
