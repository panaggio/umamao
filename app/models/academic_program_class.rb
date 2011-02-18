require 'digest/sha1'

class AcademicProgramClass < Topic
  include MongoMapper::Document

  key :academic_program_id, ObjectId
  belongs_to :academic_program

  key :year, Integer

  key :student_ids, Array
  has_many :students, :class_name => 'Student', :in => :student_ids

  validates_presence_of :academic_program_id, :year

  validates_uniqueness_of :year, :scope => :academic_program_id
end
