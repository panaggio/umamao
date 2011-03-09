require 'digest/sha1'

class AcademicProgram < Topic
  include MongoMapper::Document

  key :code, String, :length => 15, :required => true
  key :name, String, :length => 100, :required => true
  key :undergrad, Boolean, :default => true

  key :university_id, ObjectId, :required => true
  belongs_to :university

  timestamps!

  validates_uniqueness_of   :code, :scope => :university_id

  slug_key :title, :unique => true, :min_length => 3
end
