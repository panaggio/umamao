require 'mm-paginate'

config_file = "#{Rails.root}/config/database.yml"

options = (File::exists?(config_file) ?
           YAML.load_file(config_file) :
           YAML.load(ENV["DATABASE_YML"]))

MongoMapper.setup(options,
                  Rails.env, { :logger => Rails.logger, :passenger => false })

MongoMapperExt.init

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    MongoMapper.connection.connect if forked
  end
end

Dir.glob("#{Rails.root}/app/javascripts/**/*.js") do |js_path|
  code = File.read(js_path)
  name = File.basename(js_path, ".js")

  # HACK: looks like ruby driver doesn't support this
  MongoMapper.database.eval("db.system.js.save({_id: '#{name}', value: #{code}})")
end

require 'support/versionable'
require 'support/voteable'
