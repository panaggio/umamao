namespace :db do
  desc "Downloads a dump of the database"
  task :dump => :environment do
    cfg = YAML.load_file(Rails.root + "config/database.yml")["production"]
    puts "Cleaning old DB..."
    `mongo --eval 'db.getSisterDB("shapado-development").dropDatabase()'`
    puts "Downloading DB dump..."
    `mongo --eval 'db.copyDatabase("#{cfg["database"]}", "shapado-development", "#{cfg["host"]}:#{cfg["port"]}", "#{cfg["username"]}", "#{cfg["password"]}")'`
    puts "Exporting binary dump..."
    `mongodump -db shapado-development`

    umamao = Group.first
    umamao.domain = "localhost.lan"
    umamao.save!
  end

  desc "Imports mongodb dump from dump/"
  task :import => :environment do
    puts "Cleaning old DB..."
    `mongo --eval 'db.getSisterDB("shapado-development").dropDatabase()'`
    puts "Restoring from binary dump..."
    `mongorestore dump`

    umamao = Group.first
    umamao.domain = "localhost.lan"
    umamao.save!
  end

  desc "Cleans the DB"
  task :clean do
    `mongo --eval 'db.getSisterDB("shapado-development").dropDatabase()'`
  end
end
