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
  has_many :registered_courses, :class_name => 'CourseOffer',
    :in => :registered_course_ids

  # Denormalized association with users
  belongs_to :user

  # Denormalized; see #check_whether_has_been_invited below.
  key :has_been_invited, Boolean, :default => false

  validates_presence_of     :code
  validates_length_of       :code, :maximum => 15

  validates_presence_of     :name
  validates_length_of       :name, :maximum => 100

  timestamps!

  def is_registered?
    return Affiliation.count(:student_id => self.id) > 0
  end

  # FIXME: This should work for every university, not only Unicamp.
  def academic_email
    if university.short_name == "Unicamp"
      "#{self.name[0..0].downcase}#{self.code}@dac.unicamp.br"
    else
      nil
    end
  end

  # Check whether there is an invitation to this student's academic
  # email. This is denormalized in the has_been_invited key.
  def check_whether_has_been_invited
    Invitation.find_by_recipient_email(self.academic_email).present?
  end

  def self.find_by_email(email)
    domain = email.match(/@([^@]*)$/)[1]
    if university = University.find_by_email_domain(domain)
      university.find_student_by_email(email)
    end
  end

end
