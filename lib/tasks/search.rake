class Buffer
  def initialize
    @buf = []
  end

  def send(entry)
    @buf << entry.serialize_for_search_server
    self.flush if @buf.size > 100
  end

  def flush
    Support::Search.update_search_index("<update>#{@buf.join ""}</update>")
    @buf = []
  end
end

namespace :search do

  desc "Empty the search index"
  task :clear => :environment do
    puts "Clearing index..."
    Support::Search.update_search_index("<delete><query>*</query></delete>")
  end

  desc "Cleans data in the search index and repopulates it"
  task :reset => :environment do
    buffer = Buffer.new
    Rake::Task["search:clear"].invoke
    puts "Exporting topics..."
    Topic.query.each{|topic| buffer.send(topic)}
    puts "Exporting users..."
    User.query.each{|user| buffer.send(user)}
    puts "Exporting questions..."
    Question.query.each{|question| buffer.send(question)}
    buffer.flush
  end

end
