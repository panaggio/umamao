class Avatar < UploadedFile

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
      self.mount.url
    end
  end

end
