require "nokogiri"

class WikipediaPagesArticleDumpParser < Nokogiri::XML::SAX::Document
  def start_document
    set_internals false
  end

  def end_document
    set_internals nil
    finish_processing
  end

  def start_element(element, attributes = [])
    @inside = element
    case element
    when "page"
      @topic = {}
      @inside_page = true
    when "revision"
      @inside_revision = true
    end
  end

  def end_element(element)
    @inside = nil
    case element
    when "page"
      unless @topic.nil?
        send_outside @topic
        @topic = nil
      end
      @inside_page = false
    when "revision"
      @inside_revision = false
    end
  end
  
  def characters(text)
    if ["title", "id"].include? @inside and @inside_page and not @inside_revision
      @topic[@inside] = (@topic[@inside] || "") << text
    end

    if @inside == "text" and @inside_revision
      @topic = nil if text.include? "#REDIRECT"
    end
  end

  protected
  def set_internals(status)
    @inside_page, @inside_revision = status, status
  end

  def send_outside article
    WikipediaTopicCreator.enqueue_topic article
  end

  def finish_processing
    WikipediaTopicCreator.pull_topics
  end
end

module WikipediaTopicCreator
  WINDOW_SIZE = 100

  def self.enqueue_topic(article)
    @topics ||= {}
    title = article.delete("title")
    @topics["title"] = article
    create_topics if @topics.size > WINDOW_SIZE
  end

  def self.pull_topics
    create_topics unless @topics.empty?
  end

  def self.create_topics
    Topic.from_titles!(@topics).each do |topic|
      topic.wikipedia_pt_id = article["id"]

      #q = Freebase::MidQuery[article["id"]].results[0]
      #topic.freebase_mids = q.mids
      #topic.wikipedia_pt_key = q.pt_article.slug
      #topic.description = q.pt_article.description

      topic.save
    end
    p "created #{@topics.size} topics @ #{Time.now}"

    @topics = {}
  end
end
