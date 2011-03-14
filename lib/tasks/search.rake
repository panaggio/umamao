class Buffer

  BUFFER_SIZE = 10_000

  def initialize
    @buf = []
  end

  def send(entry)
    @buf << entry.serialize_for_search_server
    self.flush if @buf.size > BUFFER_SIZE
  end

  def flush
    Support::Search.delay.
      send_command_to_search_server("<update>#{@buf.join ""}</update>")
    @buf = []
    print '.'
  end
end

namespace :search do

  desc "Empty the search index"
  task :clear => :environment do
    puts "Clearing index..."
    Support::Search.
      send_command_to_search_server("<delete><query>*</query></delete>")
  end

  desc "Cleans data in the search index and repopulates it"
  task :reset => :environment do
    buffer = Buffer.new
    Rake::Task["search:clear"].invoke
    puts "Exporting users..."
    User.find_each{ |user| buffer.send(user) }
    puts "Exporting questions..."
    Question.find_each{ |question| buffer.send(question) }
    puts "Exporting topics..."
    Topic.find_each{ |topic| buffer.send(topic) }
    buffer.flush
  end

end
