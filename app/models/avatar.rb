class Avatar < UploadedFile

  def self.maxsize
    4 * 1024 * 1024
  end

  def self.uploader
    AvatarUploader
  end

  def filename
    "#{self.id}.#{self.extension}"
  end

  def url(version = nil)
    # Return the thumbnail when told so.
    case version
    when :thumb
      self.mount.thumb.url
    else
      self.mount.large.url
    end
  end

end
