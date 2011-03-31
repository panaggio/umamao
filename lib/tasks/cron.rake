task :cron => :environment do
  Rake::Task["cron_tasks:refresh_related_topics"].execute
  Rake::Task["suggestions:refresh"].execute
end

namespace :cron_tasks do
  desc "Refreshes each topic's list of related topics"
  task :refresh_related_topics => :environment do
    Rails.logger.info "Refreshing list of related topics..."
    Topic.find_each do |topic|
      next if topic.questions_count == 0
      topic.find_related_topics
      topic.save :validate => false
    end
  end
end
