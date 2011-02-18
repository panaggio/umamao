class Student
  include MongoMapper::Document

  key :code, String, :index => true
  key :name, String
  key :undergrad, Boolean, :default => true

  key :university_id, ObjectId
  belongs_to :university

  key :academic_program_class_id, ObjectId
  belongs_to :academic_program_class

  key :registered_course_ids, Array
  has_many :registered_courses, :class_name => 'CourseOffer', :in => :registered_course_ids

  validates_presence_of     :code
  validates_length_of       :code, :maximum => 15

  validates_presence_of     :name
  validates_length_of       :name, :maximum => 100

  timestamps!

end
