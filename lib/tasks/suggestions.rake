namespace :suggestions do
  desc "Remove suggestions whose suggested entry doesn't exist anymore"
  task :prune => :environment do
    Suggestion.query.each do |suggestion|
      if suggestion.entry.blank?
        puts "Removing blank suggestion #{suggestion.id} " +
          "of #{suggestion.entry_type} #{suggestion.entry_id}"
        suggestion.user.remove_suggestion(suggestion)
      end
    end
  end

  desc "Refreshes suggestions for all users"
  task :refresh => :environment do
    Rails.logger.info "Refreshing suggestions for users..."
    User.query.each do |user|
      puts user.name
      user.refresh_suggestions
      user.save!
    end
  end
end
