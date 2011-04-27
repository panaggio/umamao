class Course < Topic
  include MongoMapper::Document

  key :code, String, :length => 15, :index => true
  key :name, String, :length => 500, :index => true, :required => true
  key :summary, String
  key :undergrad, Boolean, :default => true

  key :university_id, ObjectId, :required => true
  belongs_to :university

  key :prereq_ids, Array, :index => true
  has_many :prereqs, :class_name => 'Course', :in => :prereq_ids

  slug_key :title, :unique => true, :min_length => 3

  timestamps!

  def allow_question_lists
    true
  end

  validates_uniqueness_of :code, :scope => :university_id, :allow_blank => true

  # Return all students which are currently enrolled in this course
  # but don't correspond to an existing user and haven't been invited yet.
  def unregistered_students
    id_offers =
      CourseOffer.all(:course_id => self.id, :select => [:id]).map(&:id)
    Student.all(
      :registered_course_ids.in => id_offers).select{|s|
      Affiliation.first(:student_id => s.id).nil? &&
        Invitation.count(:recipient_email => s.academic_email) == 0}
  end

end
