require 'digest/sha1'

class University
  include MongoMapper::Document
  include Scopes
  include MongoMapperExt::Filter

  key :name,                      String, :limit => 100,
                                          :null => false,
                                          :index => true
                                                         
  key :sig,						  String, :limit => 20,
                                          :null =>false,
                                          :index => true
                                                         
  key :state,					  String, :limit => 20,  :null =>false
  key :open_for_signup,			  Boolean
  key :validation_type,			  String
  key :domain,		  String
  
  has_many :affiliation, :dependent => :destroy
  
  timestamps!

  validates_presence_of     :name
  validates_uniqueness_of   :name
  validates_length_of       :name, :maximum => 100
  filterable_keys           :name, :sig

  validates_presence_of     :sig
  validates_length_of       :sig, :maximum => 20
  validates_length_of       :state, :maximum => 20

  def email_regexp
	Regexp.new "[.@]"+self.domain+"$" if !self.domain.nil? && !self.domain.empty?
  end
  
  def self.find_id_by_email_domain(email)
	University.all.each { |u|
		return u._id if email =~ u.email_regexp
	}
	return nil
  end

#  validates_uniqueness_of   :academic_email, :if => lambda { |u| u.new_record? && u.confirmed_at.blank? }
#  validates_format_of       :academic_email, :with => /([.@]unicamp.br$)|([.@]usp.br$)/,
#                            :if => lambda { |u| u.new_record? && u.confirmed_at.blank? }

end
