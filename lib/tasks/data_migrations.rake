# -*- coding: utf-8 -*-
namespace :data do
  namespace :migrate do
    desc "Move tags from an array of strings into their own (Topic) model"
    task :tags_to_topics => :environment do
      Topic.delete_all

      questions = Question.query
      questions.each do |question|
        topics = question.tags.map { |tag|
          topic = Topic.find_by_title(tag)

          if !topic
            topic = Topic.create(:title => tag)
            topic.set(:created_at => question.created_at)
          end

          topic.set(:questions_count => topic.questions_count + 1)
          topic
        }
        question.set(:topic_ids => topics.map(&:id).uniq)
      end

      # Text transformations on topics
      Topic.query.each do |topic|
        title = topic.title.split('-').map { |w|
          word = w[0..0].upcase + w[1..-1]
          word.gsub!(/cao$/, 'ção')
          word.gsub!(/ao$/, 'ão')
          word
        }.join(' ')

        if title =~ /^\w{1,2}\d{3}$/
          title = title.upcase + ' (Unicamp)'
        end

        topic.set(:title => title)
        # we want the slug to be generated from the new title
        topic.reload
        topic.send(:generate_slug)
        topic.set(:slug => topic.slug)
      end
    end

    desc "Create autocomplete index for questions, users and topics"
    task :create_autocomplete_index => :environment do
      Question.all.each &:update_autocomplete_item
      Topic.all.each &:update_autocomplete_item
      User.all.each &:update_autocomplete_item
    end
  end
end
