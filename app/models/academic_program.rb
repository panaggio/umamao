require 'digest/sha1'

class AcademicProgram < Topic
  include MongoMapper::Document

  key :code, String, :limit => 15, :null => false
  key :name, String, :limit => 100, :null => false
  key :undergrad, Boolean, :default => true

  key :university_id, ObjectId, :null => false
  belongs_to :university

  timestamps!

  validates_presence_of     :name
  validates_length_of       :name, :maximum => 100

  validates_presence_of     :code
  validates_length_of       :code, :maximum => 15
  validates_uniqueness_of   :code, :scope => :university_id

  validates_presence_of     :university_id

  slug_key :title, :unique => true, :min_length => 3
end
