class ExternalAccount
  include MongoMapper::Document
  # These keys are from the OmniAuth hash schema
  # https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema
  key :provider, String
  key :uid, String
  key :user_info, Hash
  key :credentials, Hash
  key :extra, Hash

  ensure_index([[:provider, 1], [:uid, 1]], :unique => true)

  validates_presence_of :uid, :provider
  validates_uniqueness_of :uid, :scope => :provider

  def self.find_from_hash(hash)
    self.first(:provider => hash['provider'], :uid => hash['uid'])
  end

  def self.create_from_hash(hash, user = nil)
    # access_token comes from twitter and is not serializable by
    # mongomapper. We don't need it because it's already in
    # :credentials.
    hash['extra'].delete('access_token')

    self.create(hash.merge(:user => user))
  end

end
