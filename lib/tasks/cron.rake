namespace :cron do
  desc "Refreshes suggestions for all users"
  task :refresh_suggestions => :environment do
    Rails.logger.info "Refreshing suggestions for users..."
    User.query.each do |user|
      puts user.name
      user.refresh_suggestions
      user.save :validate => false
    end
  end

  desc "Refreshes each topic's list of related topics"
  task :refresh_related_topics => :environment do
    Rails.logger.info "Refreshing list of related topics..."
    Topic.query.each do |topic|
      puts topic.name
      next if topic.questions_count == 0
      topic.find_related_topics
      topic.save :validate => false
    end
  end
end
