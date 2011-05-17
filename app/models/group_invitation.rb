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

  key :entry_id
  key :entry_type
  belongs_to :entry, :polymorphic => true

  key :sharer_id, ObjectId
  belongs_to :sharer, :class_name => "User"

  key :share_type, String

  timestamps!

  def self.shared_content(content, share_type, message=nil, user=nil)
    user_id = user && user.id
    gi =  GroupInvitation.first(:entry_id => content.id,
                                :share_type => share_type,
                                :sharer_id => user_id)
    return gi if gi

    topic_ids = case content
                when Topic then [content.id]
                when Question then content.topic_ids
                when Answer then content.question.topic_ids
                else []
                end
    return GroupInvitation.create(:entry => content,
                                  :share_type => share_type,
                                  :slug => "#{share_type}_#{content.id}_#{user_id}",
                                  :sharer => user,
                                  :message => message,
                                  :topic_ids => topic_ids)
  end
end
