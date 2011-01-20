namespace :cron do
  desc "Refreshes suggestions"
  task :refresh_suggestions => :environment do
    User.query.each do |user|
      puts user.name
      user.refresh_suggestions
      begin
        user.save!
      rescue
        puts "Error while saving user #{user.name}"
      end
    end
  end

  desc "Refreshes each topic's list of related topics"
  task :refresh_related_topics => :environment do
    Topic.query.each do |topic|
      puts topic.name
      next if topic.questions_count == 0
      topic.find_related_topics
      begin
        topic.save!
      rescue
        puts "Error while saving topic #{topic.name}"
      end
    end
  end
end
