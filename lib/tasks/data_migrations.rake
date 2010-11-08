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

    desc "Rebuild filter indexes for questions, users and topics"
    task :rebuild_indexes => :environment do
      Question.all.each {|q| q.save :validate => false}
      Topic.all.each {|q| q.save :validate => false}
      User.all.each {|q| q.save :validate => false}
    end

    desc "Migrate news items to polymorphic version"
    task :remake_news_items => :environment do
      NewsItem.all.each {|i| i.recipient_type = "User"; i.save}
    end
  end
end
