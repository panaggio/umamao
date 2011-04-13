# Files uploaded to the site by the users.

class UploadedFile
  include MongoMapper::Document

  timestamps!

  key :original_filename, String, :required => true

  belongs_to :user, :required => true

  belongs_to :group, :required => true

  attr_reader :file

  validate :check_file_presence, :if => lambda { |uf| uf.new? }
  validate :check_file_size, :if => lambda { |uf| uf.file.present? }

  after_create :store_file!

  before_destroy :remove_file_from_storage!

  MAXSIZE = 20 * 1024 * 1024 # 20MB

  def initialize(args)
    @file = args.delete :file
    self.original_filename =
      if @file.respond_to? :original_filename
        File.basename @file.original_filename
      else
        File.basename @file.path
      end
    super
  end

  # Return the file's extension
  def extension
    self.original_filename.match(/\.\w+$/)[0]
  end

  # The url to the file in storage
  def url
    uploader = FileUploader.new(self)
    # This actually doesn't retrieve the file on the server, but sets
    # the uploader's state so we can get the url.
    uploader.retrieve_from_store!(self.original_filename)
    uploader.url
  end

  def can_be_destroyed_by?(user)
    self.user == user || user.owner_of?(self.group)
  end

  # Remove the corresponding file from storage
  def remove_file_from_storage!
    uploader = FileUploader.new(self)
    uploader.retrieve_from_store!(self.original_filename)
    uploader.remove!
  end

  def store_file!
    # TODO: destroy self if upload doesn't work
    uploader = FileUploader.new(self)
    uploader.store!(@file)
  end

  # Check that a file was given upon creation
  def check_file_presence
    if @file.blank?
      self.errors.add(:file, I18n.t("uploaded_files.errors.blank"))
      return false
    end
    true
  end

  # Check that the given file is not too large
  def check_file_size
    size =
      # File instances in 1.8.7 do not respond to :size
      if @file.respond_to? :size
        @file.size
      else
        File.size(@file.path)
      end
    if size > MAXSIZE
      self.errors.add(:file, I18n.t("uploaded_files.errors.size"))
      return false
    end
    true
  end

end
