# Files uploaded to the site by the users.

class UploadedFile
  include MongoMapper::Document

  timestamps!

  key :original_filename, String

  belongs_to :user

  after_create :store_file!

  def initialize(args)
    @file = args.delete :file
    self.original_filename = File.basename @file.original_filename
    super
  end

  def extension
    self.original_filename.match(/\.\w+$/)[0]
  end

  def filename
    self.id.to_s + self.extension
  end

  def url
    uploader = FileUploader.new
    # This actually doesn't retrieve the file on the server, but sets
    # the uploader's state so we can get the url.
    uploader.retrieve_from_store!(self.filename)
    uploader.url
  end

  def store_file!
    # TODO: destroy self if upload doesn't work
    uploader = FileUploader.new(self)
    uploader.store!(@file)
  end

end
