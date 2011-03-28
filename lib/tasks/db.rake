namespace :db do
  task :config => :environment do
    CFG = YAML.load_file(Rails.root + "config/database.yml")
  end

  task :drop_dump => :config do
    db = Mongo::Connection.new

    puts "Cleaning old DB..."
    db.drop_database CFG['dump']
  end

  desc "Downloads a dump of the database"
  task :dump => [:config, :drop_dump] do
    db = Mongo::Connection.new

    puts "Downloading DB dump..."
    db.copy_database(
      CFG['production']['database'],
      CFG['dump'],
      "#{CFG['production']['host']}:#{CFG['production']['port']}",
      CFG['production']['username'],
      CFG['production']['password']
    )
  end

  task :import => :config do
    db = Mongo::Connection.new

    puts "Importing binary dump..."
    db.copy_database(
      CFG['dump'],
      CFG['development']['database']
    )

    # ensures that group is set up properly
    umamao = Group.first
    umamao.domain = "localhost.lan"
    umamao.save!
  end
end
