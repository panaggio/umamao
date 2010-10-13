class Topic
  include MongoMapper::Document
  include MongoMapperExt::Slugizer
  include Support::Versionable

  key :title, String, :required => true, :index => true, :unique => true
  key :description, String
  key :questions_count, :default => 0

  key :updated_by_id, String
  belongs_to :updated_by, :class_name => "User"

  slug_key :title, :unique => true, :min_length => 3

  timestamps!

  versionable_keys :title, :description
end
