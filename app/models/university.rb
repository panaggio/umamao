require 'digest/sha1'

class University
  include MongoMapper::Document
  include Scopes
  include MongoMapperExt::Filter

  key :_id,                       String
  key :name,                      String, :limit => 100, :null => false, :index => true
  key :sig,						  String, :limit => 20, :null =>false, :index => true
  key :state,					  String, :limit => 20, :null =>false
  key :open_for_signup,			  Boolean
  key :validation_type,			  String
  key :email_regexp,			  String
  
  timestamps!

  validates_presence_of     :name
  validates_uniqueness_of   :name
  validates_length_of       :name, :maximum => 100
  filterable_keys           :name

  validates_presence_of     :sig
  validates_length_of       :sig, :maximum => 20
  validates_length_of       :state, :maximum => 20

#  validates_uniqueness_of   :academic_email, :if => lambda { |u| u.new_record? && u.confirmed_at.blank? }
#  validates_format_of       :academic_email, :with => /([.@]unicamp.br$)|([.@]usp.br$)/,
#                            :if => lambda { |u| u.new_record? && u.confirmed_at.blank? }

end
