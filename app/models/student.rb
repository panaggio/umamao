class Student
  include MongoMapper::Document

  key :code, String, :index => true
  key :name, String

  key :program_class_id, String
  belongs_to :program_class

  key :registered_course_ids, Array
  has_many :registered_courses, :class_name => 'CourseOffer', :in => :registered_course_ids

  validates_presence_of     :code
  validates_length_of       :code, :maximum => 15

  validates_presence_of     :name
  validates_length_of       :name, :maximum => 100

  timestamps!

end
