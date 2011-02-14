class Offer < Topic
  include MongoMapper::Document

  key :code, String, :limit => 15, :null => false, :index => true
  key :year, Integer, :null => false, :index => true
  key :semester, Integer, :null => false, :index => true

  key :course_id, String
  belongs_to :course

  validates_uniqueness_of   :code, :scope => [:year, :semester]

  timestamps!

end
