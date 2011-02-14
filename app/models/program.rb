require 'digest/sha1'

class Program < Topic
  include MongoMapper::Document

  key :code, String, :limit => 15, :null => false
  key :name, String, :limit => 100, :null => false

  key :university_id, String, :null => false
  belongs_to :university

  timestamps!

  validates_presence_of     :name
  validates_length_of       :name, :maximum => 100

  validates_presence_of     :code
  validates_length_of       :code, :maximum => 15

  validates_presence_of     :university_id

  validates_uniqueness_of   :code, :scope => :university_id
end
