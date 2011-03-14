class Contact
  include MongoMapper::Document
  include MongoMapperExt::Filter

  timestamps!

  key :name, String, :length => 256
  key :email, String, :length => 256

  key :user_id, ObjectId
  belongs_to :user

  validates_format_of :email, :with => Devise::email_regexp

  filterable_keys :name, :email
end
