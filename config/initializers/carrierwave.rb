# Set up file upload config.

CarrierWave.configure do |config|
  config.permissions = 0666
  config.fog_credentials = {
    :provider => 'Rackspace',
    :rackspace_username => AppConfig.rackspace["cloudfiles"]["username"],
    :rackspace_api_key => AppConfig.rackspace["cloudfiles"]["api_key"]
  }
  config.fog_directory =
    AppConfig.rackspace["cloudfiles"]["containers"]["uploads"]["name"]
  config.fog_host =
    AppConfig.rackspace["cloudfiles"]["containers"]["uploads"]["url"]
end
