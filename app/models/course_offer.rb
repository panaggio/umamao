class CourseOffer < Topic
  include MongoMapper::Document

  key :code, String, :length => 15
  key :year, Integer
  key :semester, Integer

  key :course_id, ObjectId
  belongs_to :course

  key :student_ids, Array
  has_many :students, :class_name => 'Student', :in => :student_ids

  validates_presence_of  :code, :year, :semester, :course_id

  validates_uniqueness_of   :code, :scope => [:year, :semester, :course_id]

  slug_key :title, :unique => true, :min_length => 3

  ensure_index([[:course_id, 1], [:code, 1], [:year, 1], [:semester, 1]])

  timestamps!

end
