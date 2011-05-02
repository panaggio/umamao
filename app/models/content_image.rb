# Images uploaded to questions and answers.

class ContentImage < UploadedFile

  key :entry_id, String
  key :entry_type, String
  belongs_to :entry, :polymorphic => true

  def self.maxsize
    10 * 1024 * 1024
  end

  def self.uploader
    ContentImageUploader
  end

  def filename
    "#{self.id}.#{self.extension}"
  end

  def url(version = :original)
    # Return the thumbnail when told so.
    case version
    when :thumb
      self.mount.thumb.url
    when :original
      self.mount.url
    end
  end

end

