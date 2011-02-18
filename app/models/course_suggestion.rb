class CourseSuggestion
  include MongoMapper::Document

  key :semester, Integer
  key :catalog_year, Integer

  key :academic_program_id, ObjectId
  belongs_to :academic_program

  key :course_id, ObjectId
  belongs_to :course

  ensure_index([[:semester, 1], [:academic_program_id, 1], [:course_id, 1], [:catalog_year, 1]],
                               :unique => true)

  timestamps!

end
