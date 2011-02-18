require 'digest/sha1'

class ProgramClass < Topic
  include MongoMapper::Document

  key :program_id, ObjectId
  belongs_to :program

  key :year, Integer

  key :student_ids, Array
  has_many :students, :class_name => 'Student', :in => :student_ids

  validates_presence_of :program_id
  validates_presence_of :year

  validates_uniqueness_of :year, :scope => :program_id
end
