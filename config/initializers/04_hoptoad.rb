HoptoadNotifier.configure do |config|
  config.api_key = AppConfig.hoptoad['api_key']
  config.ignore << 'Goalie::NotFound'
end
