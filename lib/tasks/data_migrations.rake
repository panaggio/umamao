# -*- coding: utf-8 -*-
require 'mechanize'
require 'rubygems'
require 'ccsv'

namespace :data do
  namespace :migrate do
    desc "Add question authors as watchers"
    task :add_question_authors_as_watchers => :environment do
      Question.query.each do |question|
        if question.user_id.blank?
          puts "Missing author in \"#{question.title}\""
          next
        elsif !question.watchers.include?(question.user_id)
          puts "Added user \"#{question.user.name}\" in \"#{question.title}\""
          question.add_watcher(question.user)
        else
          puts "Skipped \"#{question.title}\""
        end
      end
    end

    desc "Find topics related to Unicamp."
    task :populate_unicamp_topics => :environment do
      unicamp = University.find_by_short_name("Unicamp")
      topic_names = ["Unicamp",
                     "Barão Geraldo", "Campinas",
                     "DAC (Unicamp)", "SAE Unicamp",
                     "CECOM (Unicamp)",
                     "Restaurante Universitário da Unicamp (Bandejão)",
                     "Bolsas-auxílio (Unicamp)",
                     "Comida na Unicamp", "Moradia Estudantil da Unicamp",
                     "DCE da Unicamp", "Sistema de Bibliotecas da Unicamp",
                     "Restaurantes da Unicamp", "Intercâmbio"]
      topic_names.each do |topic_name|
        puts topic_name
        topic = Topic.find_by_title(topic_name)
        if topic.blank?
          puts "Could not find topic \"#{topic_name}\""
        else
          unicamp.university_topics << topic
        end
      end
      unicamp.save!
    end

    desc "Calculate each topic's followers count"
    task :calculate_followers_count => :environment do
      Topic.query.each do |topic|
        next if topic.follower_ids.blank?
        topic.followers_count = topic.follower_ids.length
        topic.save :validate => false
      end
    end

    desc "Create suggestion lists for all users."
    task :create_suggestion_lists => :environment do
      User.query.each do |user|
        if user.suggestion_list.blank?
          puts user.name
          user.suggestion_list = SuggestionList.new(:user => user)
          user.save :validate => false
        else
          puts "User #{user.name} had already a suggestion list"
        end
      end
    end

    desc "Delete a question's news items if it has already been answered."
    task :delete_duplicate_news_items => :environment do
      Question.query.each do |question|
        if !question.answers.blank? && question.news_update
          NewsItem.query(:news_update_id => question.news_update.id).each do |item|
            item.destroy
          end
        end
      end
    end

    desc "Create missing news items for topics."
    task :create_news_items_for_topics => :environment do
      Question.query.each do |question|
        next if !question.news_update

        question.topics.each do |topic|
          if NewsItem.query(:recipient_id => topic.id,
                            :recipient_type => "Topic",
                            :news_update_id => question.news_update.id).count == 0
            NewsItem.notify!(question.news_update, topic, topic, question.news_update.created_at)
          end

          question.answers.each do |answer|
            next if !answer.news_update # This shouldn't happen.
            if NewsItem.query(:recipient_id => topic.id,
                              :recipient_type => "Topic",
                              :news_update_id => answer.news_update.id).count == 0
              NewsItem.notify!(answer.news_update, topic, topic, answer.news_update.created_at)
            end
          end
        end
      end
    end

    desc "Update old users format (academic e-mail inside users model) to the new one (user affiliation university)"
    task :move_user_academic_email_to_affiliation => :environment do

      unconfirmed_users = 0

      User.where(:academic_email.ne => nil).each do |user|
        if Affiliation.find_by_email(user.academic_email).present?
          puts "Skipping email #{user.academic_email}"
          next
        end
        puts "Creating affiliation for #{user.academic_email}"
        a = Affiliation.new
        a.user = user
        unconfirmed = false

        if !(a.confirmed_at = user.confirmed_at)
          puts "Unconfirmed affiliation for #{user.academic_email}"
          unconfirmed = true

          # HACK: We do not want to send emails to old unconfirmed
          # users.  The confirmation step is ignored if the
          # affiliation has a confimation date, so we set it now and
          # unset it later.
          a.confirmed_at = Time.now
          unconfirmed_users += 1
        end

        a.email = user.academic_email
        short_name = /[.@]unicamp.br$/ =~ a.email ? "Unicamp" : "USP"
        a.university = University.where(:short_name => short_name).first

        a.save!
        if unconfirmed
          # This will avoid the after_create hook.
          a.confirmed_at = nil
          a.save!
        end

        user.save :validate => false
      end

      puts "There were #{unconfirmed_users} unconfirmed users"
    end

    desc "(USING THIS WILL REMOVE DOMAINS!) fix csv file from uni2.csv to uni.csv"
    task :fix_csv_file => :environment do
      f = File.new("data/uni.csv", "w")
      Ccsv.foreach("data/uni2.csv") do |row|
        name      = row[0].split('-')[0].tr("\"", "")

        short_name   = row[1].tr("\"", "")
        state     = row[2].tr("\"", "")

        if row[3] == "TRUE" then
          open_for_signup = "TRUE"
        else
          open_for_signup = "FALSE"
        end
        f.puts("\"#{name}\", \"#{short_name}\", \"#{state}\", \"#{open_for_signup}\", \"\"")
      end
      f.close
    end

    desc "Import Universities from a csv file in the format [name, short_name,
 state, V, domain] where V is TRUE if the university is open for signup or
 FALSE otherwise"
    task :import_universities => :environment do
      Ccsv.foreach("data/uni.csv") do |row|
        a = University.new
        a.name = row[0].split('-')[0].tr("\"", "")
        a.name.downcase_with_accents!
        a.name = a.name.phrase_ucfirst.strip

        a.short_name = row[1].tr("\"", "").strip
        a.state = row[2].tr("\"", "").strip

        a.open_for_signup = (row[3].tr("\"", "").strip == "TRUE")
        a.validation_type = "email"
        a.domains = row[4].tr("\"", "").strip.split(" ")
        a.save!
        nil
      end
    end

    desc "Create news updates for entries that don't have one"
    task :create_old_news_updates => :environment do
      Question.query.each do |question|
        if !question.news_update
          question.create_news_update
        end
      end

      Answer.query.each do |answer|
        if !answer.news_update
          answer.create_news_update
        end
      end
    end

    desc "Update questions count in topics"
    task :update_topic_questions_count => :environment do
      Topic.query.each do |topic|
        topic.questions_count = Question.query(:topic_ids => topic.id,
                                               :banned => false).count
        topic.save
      end
    end

    desc "Remove duplicate votes"
    task :remove_dup_votes => :environment do
      dups = Vote.all.group_by{|v| [v.user_id, v.voteable_id, v.voteable_type]}.
        to_a.each{|g| g[1][1..-1].map {|v| v.destroy}}

      if Vote.all.group_by{|v| [v.user_id, v.voteable_id, v.voteable_type]}.
          to_a.select{|g| g[1].length > 1}.length == 0
        puts "Success!"
      else
        puts "Error"
      end
    end

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

    desc 'Import courses from Unicamp into topics'
    task :import_unicamp_courses => :environment do
      agent = Mechanize.new
      pagelist = agent.get('http://www.dac.unicamp.br/sistemas/catalogos/grad/catalogo2010/ementas/')

      pagelist.links.select{|l| l.href.include?('todas')}.each do |link|
        courses = []
        course = {}
        link.click

        # the first 4 items are just page header information
        text_items = agent.page.search('font[size="-1"]').map{|el| el.text.strip}[4..-1]

        text_items.each do |item|
          case item
          when /^(\w+\d+) (.*)/ # e.g.: AD012 Ateliê de Prática em Dança II
            if course.present?
              courses << course
              print '-' # progress indicator
              course = {}
            end

            course[:code] = $1
            course[:title] = $2

          when /^Pré-Req\.: (.*)/ # e.g.: Pré-Req.: AD011 F 429
            course[:pre_reqs] = $1.scan(/([A-Za-z]+\d+)|([fF] \d+)/).flatten.compact

          when /^Ementa: (.*)/
            course[:syllabus] = $1.strip
          end
        end

        courses << course
        print '-' # progress indicator

        courses.each do |course|
          topic = Topic.find_or_create_by_title("#{course[:code]} (Unicamp)")

          pre_req_links = course[:pre_reqs].present? ?
          "<strong>Pré-requisitos</strong>: " + course[:pre_reqs].map { |code|
            "<a href=\"/topics/#{code.tr(' ', '-')}-Unicamp\">#{code}</a>"
          }.join(', ') + "\n\n" : ''


          topic.description = "# #{course[:code]}: #{course[:title]}\n\n"
          topic.description << pre_req_links + (course[:syllabus] || '')
          topic.save
          print '.' # progress indicator
        end

        sleep 1
      end

    end
  end
end
