class ProgramCourse
  include MongoMapper::Document

  key :semester, Integer
  key :year_catalog, Integer

  key :program_id, ObjectId
  belongs_to :program

  key :course_id, ObjectId
  belongs_to :course

  ensure_index([[:semester, 1], [:program_id, 1], [:course_id, 1], [:year_catalog, 1]],
                               :unique => true)
  validates_uniqueness_of   :course_id, :scope => [:year_catalog, :semester, :program_id, :course_id]
  

  timestamps!

end
