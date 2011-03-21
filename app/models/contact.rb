# User's external contacts.

class Contact
  include MongoMapper::Document
  include MongoMapperExt::Filter

  timestamps!

  key :name, String, :length => 256
  key :email, String, :length => 256

  key :user_id, String
  belongs_to :user

  key :invitation_id, String
  belongs_to :invitation

  # The user account that corresponds to this contact, if it exists.
  key :corresponding_user_id, String
  belongs_to :corresponding_user, :class_name => "User"

  validates_format_of :email, :with => Devise::email_regexp

  filterable_keys :name, :email
end
