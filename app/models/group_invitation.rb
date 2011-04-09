# Group invitations are special URLs that allow users to sign up
# without an academic email (e.g. example.com/slashdot). It also
# allows displaying a special message and tracking users who sign up
# through that URL, so it's good for marketing campaigns.
class GroupInvitation
  include MongoMapper::Document

  key :slug, String, :unique => true
  key :message, String
  key :active, Boolean, :default => true

  key :user_ids, Array
  many :users, :in => :user_ids
  key :topic_ids, Array
  many :topics, :in => :topic_ids
end
