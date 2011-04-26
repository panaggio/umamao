class AvatarUploader < FileUploader

  include CarrierWave::RMagick

  version :large do
    process :resize_to_fit => [200, 200]
  end

  version :thumb do
    process :resize_to_fill => [50, 50]
  end

  def store_dir
    "avatars/#{model.user_id}"
  end

  def extension_whitelist
    %w(jpg jpeg png gif)
  end

end
