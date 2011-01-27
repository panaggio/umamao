require 'digest/sha1'

class University
  include MongoMapper::Document
  include Scopes
  include MongoMapperExt::Filter

  key :name, String, :limit => 100, :null => false, :index => true
  key :short_name, String, :limit => 20, :null =>false, :index => true
  key :state, String, :limit => 20,  :null =>false
  key :open_for_signup, Boolean
  key :validation_type, String
  key :domains, Array

  has_many :affiliation, :dependent => :destroy

  timestamps!

  validates_presence_of     :name
  validates_uniqueness_of   :name
  validates_length_of       :name, :maximum => 100
  filterable_keys           :name, :short_name

  validates_presence_of     :short_name
  validates_length_of       :short_name, :maximum => 20
  validates_length_of       :state, :maximum => 20

  # Topics we want to suggest to affiliated users initially. We do not
  # include here subject topics, only topics of general
  # interest.
  key :university_topic_ids, Array, :default => []
  has_many :university_topics, :class_name => "Topic",
    :in => :university_topic_ids

  scope :open_for_signup, where(:open_for_signup => true).sort(:short_name.asc)

  def email_regexp
    if self.domains.present?
      Regexp.new "([.@]" + self.domains.join("$)|([.@]") + "$)"
    end
  end

  def self.find_id_by_email_domain(email)
    University.all.each { |u|
      return u._id if email =~ u.email_regexp
    }
    return nil
  end

end
