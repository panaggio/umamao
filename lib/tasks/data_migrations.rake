# -*- coding: utf-8 -*-
namespace :data do
  namespace :migrate do
    desc "Move tags from an array of strings into their own (Topic) model"
    task :tags_to_topics => :environment do
      Topic.delete_all

      # Create topics
      tags = Question.find_tags(/.*/, {}, 0)
      tags.each do |tag|
        topic = Topic.new(:title => tag['name'])
        puts "Could not import tag #{tag.inspect}" unless topic.save
      end

      # Assign topics to questions
      questions = Question.query
      questions.each do |question|
        topics = question.tags.map { |tag|
          topic = Topic.find_by_title(tag)
          topic.questions_count += 1
          topic.save
          topic
        }
        question.set(:topic_ids => topics.map(&:id).uniq)
      end

      # Text transformations on topics
      Topic.query.each do |topic|
        title = topic.title.gsub(/-/, ' ').capitalize
        title = title.gsub(/cao$/, 'ção')
        title = title.gsub(/ao$/, 'ão')
        if title =~ /\w{1,2}\d{3}/
          title = title.upcase + ' (Unicamp)'
        end
        topic.title = title
        topic.send(:generate_slug)
        topic.save
      end
    end
  end
end
