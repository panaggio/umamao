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
      @article = {}
      @inside_page = true
    when "revision"
      @inside_revision = true
    when "redirect"
      @redirects = true
    end
  end

  def end_element(element)
    @inside = nil
    case element
    when "page"
      if not @redirects and @article
        send_outside @article
        @article = nil
      end
      @redirects = false
      @inside_page = false
    when "revision"
      @inside_revision = false
    end
  end
  
  def characters(text)
    if ["title", "id"].include? @inside and @inside_page and not @inside_revision
      @article[@inside] = (@article[@inside] || "") << text
    end
  end

  protected
  def set_internals(status)
    @inside_page, @inside_revision, @redirects = status, status, status
  end

  def send_outside article
    WikipediaTopicCreator.enqueue_article article
  end

  def finish_processing
    WikipediaTopicCreator.pull_articles
  end
end

module WikipediaTopicCreator
  WINDOW_SIZE = 10_000

  def self.enqueue_article(article)
    title = article.delete("title")
    @articles ||= {}
    @articles[title] = article
    self.create_topics if @articles.size > WINDOW_SIZE
  end

  def self.pull_articles
    self.create_topics unless @articles.empty?
  end

  def self.create_topics
    titles = @articles.keys.map{ |t| t.dup }

    Topic.from_titles!(titles).each do |topic|
      begin
        article = @articles.delete(topic.title)
        topic.wikipedia_pt_id = article["id"]
        topic.save
      rescue
        topic.wikipedia_import_status =
          if article.nil?
            "parse error: empty article"
          else
            "unkown error"
          end
        topic.save
      end
    end

    @articles = {}
  end

  def self.fillin_topics(topic, article)
    q = Freebase::MidQuery[article["id"].to_i].results[0]

    topic.freebase_mids = q.mids
    topic.wikipedia_pt_key = q.pt_article.slug
    topic.description = q.pt_article.description

    topic.save
  end
end
