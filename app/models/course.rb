class Course < Topic
  include MongoMapper::Document

  key :code, String, :limit => 15, :null => false, :index => true
  key :name, String, :limit => 100, :null => false, :index => true
  key :summary, String

  key :university_id, String
  belongs_to :university

  key :prereq_ids, Array, :index => true
  has_many :prereqs, :class_name => 'Course', :in => :prereq_ids

  validates_presence_of     :code
  validates_uniqueness_of   :code
  validates_length_of       :code, :maximum => 15

  validates_presence_of     :name
  validates_length_of       :name, :maximum => 100
  
  validates_presence_of     :university_id

  timestamps!

end
