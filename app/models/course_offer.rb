class CourseOffer < Topic
  include MongoMapper::Document

  key :code, String, :limit => 15, :null => false, :index => true
  key :year, Integer, :null => false, :index => true
  key :semester, Integer, :null => false, :index => true

  key :course_id, String
  belongs_to :course

  key :student_ids, Array
  has_many :students, :class_name => 'Student', :in => :student_ids

  validates_presence_of     :code
  validates_presence_of     :year
  validates_presence_of     :semester
  validates_presence_of     :course_id

  validates_uniqueness_of   :code, :scope => [:year, :semester, :course_id]

  slug_key :title, :unique => true, :min_length => 3

  timestamps!

end
