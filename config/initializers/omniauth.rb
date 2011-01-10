Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, AppConfig.twitter['key'], AppConfig.twitter['secret'], :sign_in => false
  provider :facebook, AppConfig.facebook['app_id'], AppConfig.facebook['secret'], :scope => 'email,offline_access,publish_stream'
end
