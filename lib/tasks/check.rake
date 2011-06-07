namespace :check do
  desc 'Check UserTopicInfo for inconsistencies'
  task :user_topic_info => :environment do
    UserTopicInfo.find_each do |ut|
      if ut.topic.nil? || ut.user.nil?
        p ut
      end
    end
  end
end
