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

  desc "Import development DB from dump"
  task :import, :from, :needs => :config do |t, args|
    db = Mongo::Connection.new

    from = args[:from] == "clean" ? "#{CFG['dump']}-clean" : CFG['dump']

    puts "Dropping current DB..."
    db.drop_database CFG['development']['database']

    puts "Importing binary dump..."
    db.copy_database(
      from,
      CFG['development']['database']
    )

    # ensures that group is set up properly
    umamao = Group.first
    umamao.domain = "localhost.lan"
    umamao.save!
  end

  desc "Create a copy of the dump DB without empty topics"
  task :clean_dump => :config do
    db = Mongo::Connection.new
    clean_dump = "#{CFG['dump']}-clean"

    puts "Dropping old version of the dump..."
    db.drop_database clean_dump

    puts "Importing raw dump..."
    db.copy_database CFG['dump'], clean_dump

    puts "Reset MongoMapper connection..."
    dump_cfg = {'database' => clean_dump}.reverse_merge CFG['development']
    MongoMapper.setup({'development' => dump_cfg}, 'development')

    puts "Remove empty topics..."
    Topic.find_each("$or" => [{:questions_count => 0},
                              {:questions_count => nil}]) do |topic|
      if UserTopicInfo.count(:topic_id => topic.id) == 0
        topic.delete
      end
    end
  end
end
