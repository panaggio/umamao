namespace :deploy do

  task :environment do
    require 'grit'
    Repo = Grit::Repo.new '.'
  end

  task :update_production_branch => :environment do
    master = Repo.commits("master").first
    production = Repo.commits("production").first

    if production
      last_commit = (production.tree / "COMMIT").data
    else
      last_commit = nil
      production = master
    end

    if last_commit == master.id
      puts "Warning: deploying commit #{last_commit} again!"
    end

    idx = Grit::Index.new(Repo)
    idx.current_tree = master.tree

    # Add config files to the repository.
    puts "Config files."
    idx.add("config/shapado.yml", File.read("config/shapado.yml"))
    idx.add("config/database.yml", File.read("config/database.yml"))

    # Add assets
    puts "Assets."
    `compass compile`
    Rake::Task["generate_assets"].invoke
    Dir["public/assets/**"].each do |file|
      idx.add(file, File.read(file))
    end

    # Fill base commit number
    idx.add("COMMIT", master.id)

    idx.commit("Based on #{master.id}.", :head => "production",
               :parents => [production])
  end

end

