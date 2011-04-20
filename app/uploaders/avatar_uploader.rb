class AvatarUploader < FileUploader

  def store_dir
    "avatars/#{model.user_id}"
  end

  def filename
    "#{self.model.id}.#{self.model.extension}"
  end

end
