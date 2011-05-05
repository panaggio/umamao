class ContentImageUploader < FileUploader

  include CarrierWave::RMagick

  version :large do
    process :resize_to_fit => [500, 300]
  end

  def store_dir
    "images/#{model.user_id}"
  end

  def extension_whitelist
    %w(jpg jpeg png gif)
  end

end
