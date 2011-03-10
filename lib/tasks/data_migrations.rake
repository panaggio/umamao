# -*- coding: utf-8 -*-
require 'mechanize'
require 'rubygems'
require 'ccsv'
require 'lib/freebase'
require 'lib/wikipedia_parser'

namespace :data do
  namespace :migrate do
    desc "Fully migrate question versions"
    task :migrate_question_versions do
      Rake::Task["data:migrate:replace_topics_in_versions"].invoke
      Rake::Task["data:migrate:migrate_tags_in_versions"].invoke
    end

    desc "Convert :tags in old versions to topics"
    task :migrate_tags_in_versions => :environment do

      # Look for all tags occuring in versions
      versions_count = 0
      found_tags = Set.new
      Question.query.each do |question|
        question.versions.each do |version|
          if version.data[:tags].present?
            found_tags += version.data[:tags].map(&:strip)
            versions_count += 1
          end
        end
      end
      puts "Found #{versions_count} versions with tag content"

      # Look for an equivalent topic for each tag
      tag_mapping = {}
      look_later = {}
      found_tags.each do |tag|
        if tag == "c"
          # Hacky, but necessary
          new_tag = "C (Linguagem de programação)"
        else
          new_tag = tag
        end
        new_tag = new_tag.gsub(/(\w)-(\w)/, '\\1 \\2')
        new_tag = new_tag.gsub(/(\w)(cao)\b/, '\\1ção')
        new_tag_re = /^#{Regexp.escape new_tag}/i
        topics = Topic.query(:title.in => [new_tag_re]).all
        if topics.present?
          tag_mapping[tag] = topics.first.id
        else
          look_later[tag] = new_tag_re
        end
      end

      puts "Look harder..."
      # Tags we haven't found should be looked ignoring accents
      Topic.query.each do |topic|
        no_accents = topic.title.strip_accents
        look_later.each do |tag, re|
          if no_accents =~ re
            tag_mapping[tag] = topic.id
          end
        end
      end

      puts "Rebuilding versions..."
      Question.query.each do |question|
        changed = false
        question.versions.each do |version|
          if version.data[:tags].present?
            changed = true
            version.data[:topic_ids] =
              version.data[:tags].map{ |tag| tag_mapping[tag] }.compact
            version.data.delete :tags
          end
        end
        if changed
          question.save!
        end
      end
    end

    desc "Replace :topics by :topic_ids in question versions"
    task :replace_topics_in_versions => :environment do
      Question.query.each do |question|
        question.versions.each do |version|
          version.data.delete :topics
          version.data[:topic_ids] = []
        end
        question.save!
      end
    end

    desc "Remove erroneously added topics from Wikipedia articles"
    task :remove_non_global_wikipedia_articles => :environment do
      Topic.find_each(:created_at.gt => (Time.now - 12.hour), :followers_count => 0, :questions_count => 0) do |t|
        t.destroy
      end
    end

    desc "Create a DJ to import Wikipedia"
    task :launch_wp => :environment do
      Rails.logger.info "Trying to launch"
      Rake::Task["data:migrate:do_launch_wp"].delay.invoke
    end

    desc "Actually execute the Wikipedia import"
    task :do_launch_wp => :environment do
      Rails.logger.info "Downloading Wikipedia"
      Rake::Task["data:migrate:download_wikipedia_articles"].invoke
      Rails.logger.info "Exporting Wikipedia"
      Rake::Task["data:migrate:import_wikipedia_articles"].invoke
    end

    desc "Add max_votes, min_votes and is_open fields to Questions"
    task :add_votes_and_is_open_to_questions => :environment do
      Question.query.each do |q|
        q.max_votes, q.min_votes = 0, 0
        q.is_open = true

        q.answers.each do |a|
          v = a.votes_count
          q.max_votes = v if v > q.max_votes
          q.min_votes = v if v < q.min_votes

          if q.max_votes > 0
            q.is_open = false
            q.news_update.on_question_status_change false
          else
            q.news_update.on_question_status_change true
          end
        end

        q.save
      end
    end

    desc "Download Freebase simple topic dump"
    task :download_freebase_topics do
      Freebase.download_simple_topic_dump
    end

    desc "Download Wikipedia article dump"
    task :download_wikipedia_articles do
      Wikipedia.download_wikipedia_articles_dump
    end

    desc "Import Wikipedia articles as topics"
    task :import_wikipedia_articles => :environment do
      parser = Nokogiri::XML::SAX::Parser.new(WikipediaPagesArticleDumpParser.new)
      parser.parse(File.open("#{Wikipedia::DOWNLOAD_DIRECTORY}#{Wikipedia::ARTICLES_XML}"))
    end

    desc "Extract mid's from Freebase simple topic dump"
    task :extract_freebase_mids do
      Freebase.extract_mids_file_from_simple_topic_dump
    end

    # This task is not fully tested
    desc "Import Freebase topics"
    task :import_freebase_topics => :environment do
      mids = Freebase.read_mids_file
      Freebase.create_topics mids
    end

    desc "Remove \"empty\" Questions"
    task :remove_empty_questions => :environment do
      Question.query.each do |q|
        q.destroy if q.title.nil?
      end
    end

    desc "Regenerate Questions NewsItems"
    task :regenerate_questions_news_items => :environment do
      Question.query.each do |q|
        nu = q.news_update

        if nu != nil and nu.entry_type == "Question"
          if nu.news_items.nil?
            NewsItem.from_news_update! nu
          else
            nu.news_items.each do |ni|
              ni.open_question = nu.entry.is_open
              ni.news_update_entry_type = "Question"
              ni.save
            end
          end
        end

      end
    end

    desc "Recalculate votes average"
    task :recalculate_votes_average => :environment do
      Comment.query.each do |voteable|
        score = 0
        voteable.votes.each do |v|
          score += v.value
        end
        voteable.votes_count = voteable.votes.count
        voteable.votes_average = score
        voteable.save :validate => false
      end
    end

    desc "Add default topics to each university"
    task :add_default_topics_to_universities => :environment do

      # Topics of interest to everyone
      shared_topics = []
      ["Moradia", "Bolsas",
       "Consumo consciente",
       "Iniciação científica", "Intercâmbio",
       "Assistência estudantil", "Entrega em domicílio",
       "Esporte", "Aprendizado de idiomas", "Aluguel",
       "Bicicleta"].each do |title|
        topic = Topic.find_by_title(title)
        if topic.blank?
          puts "Topic \"#{title}\" not found!"
        else
          shared_topics << topic
        end
      end

      University.query.each do |university|
        name = university.short_name || university.name
        if university.university_topics.blank?
          puts "Populating topics for #{name}"
          own_topic = Topic.find_by_title(name)
          if own_topic.blank?
            puts "Creating topic \"#{name}\""
            own_topic = Topic.create!(:title => name)
          end

          university.university_topics << own_topic
          shared_topics.each do |topic|
            university.university_topics << topic
          end
          university.save :validate => false
        else
          puts "Skipping #{name}"
        end
      end
    end

    desc "Add the user's university to his short bio"
    task :add_university_to_short_bio => :environment do
      User.query.each do |user|
        if user.bio.blank? && user.affiliations.present?
          university = user.affiliations.first.university
          puts ("Populating short bio for user \"#{user.name}\" " +
                "from #{university.short_name}")
          user.bio = university.short_name
          user.save :validate => false
        else
          puts "Skipping user \"#{user.name}\""
        end
      end
    end

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

    desc 'Remove html code from Topic\'s description'
    task :remove_html_code_topic_description => :environment do
      Topic.all(:description => {"$ne" => nil}).each do |t|
        if t.description.present?
          t.description.gsub!(/<strong>([^<]*)<\/strong>/, '**\1**')

          t.description.gsub!(/<code>([^<]*)<\/code>/, '`\1`')

          if /<a/ =~ t.description
            # Find the greatest index for link
            max = 0
            t.description.scan(/\[(\d*)\]: .*/).each do |number|
              if number.to_i > max
                max = number.to_i
              end
            end

            # Change the anchor to markdown format
            new_links = ""
            t.description.scan(/<a href="([^"]*)">([^<]*)<\/a>/).each do |link|
              max = max + 1
              t.description.gsub!("<a href=\"#{link[0]}\">#{link[1]}</a>", "[#{link[1]}][#{max}]")
              new_links += "\n  [#{max}]: #{link[0]}"
            end
            t.description += new_links

          end

          t.save(:validate => false)
        end
      end
    end

    def get_university(old_university)
      if t = Topic.find_by_title(old_university["short_name"])
        Topic.set(t.id, :_type => "University")
        u = University.find_by_id(t.id)
      else
        u = University.new()
        u.title = old_university["short_name"]
      end
      old_university.delete "_id"
      u.update_attributes(old_university)
      u.save!
      u
    end

    desc "Make Universities be topics"
    task :make_university_as_topic => :environment do
      # Import Universities
      MongoMapper.database['universities'].find({}).to_a.each do |old_university|
        # Print a status information
        print '-'

        old_id = old_university["_id"]
        u = get_university(old_university)

        AcademicProgram.query(:university_id => old_id).each do |ap|
          ap.university_id = u.id
          ap.save(:validate => false)
        end

        Affiliation.query(:university_id => old_id).each do |a|
          a.university_id = u.id
          a.save(:validate => false)
        end

        Course.query(:university_id => old_id).each do |c|
          c.university_id = u.id
          c.save(:validate => false)
        end

        Student.query(:university_id => old_id).each do |s|
          s.university_id = u.id
          s.save(:validate => false)
        end

      end
      print "\n"
    end
  end
end
