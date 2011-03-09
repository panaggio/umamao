class Course < Topic
  include MongoMapper::Document

  key :code, String, :length => 15, :index => true, :required => true,
    :unique => true
  key :name, String, :length => 500, :index => true, :required => true,
    :unique => true
  key :summary, String
  key :undergrad, Boolean, :default => true

  key :university_id, ObjectId, :required => true
  belongs_to :university

  key :prereq_ids, Array, :index => true
  has_many :prereqs, :class_name => 'Course', :in => :prereq_ids

  slug_key :title, :unique => true, :min_length => 3

  timestamps!

end
