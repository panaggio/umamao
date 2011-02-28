require "nokogiri"

class WikipediaPagesArticleDumpParser < Nokogiri::XML::SAX::Document
  def start_document
    set_internals false
  end

  def end_document
    set_internals nil, nil
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
        title  = @topic.delete "title"
        yield @topic
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
end

# parser = Nokogiri::XML::SAX::Parser.new(WikipediaPagesArticleDumpParser.new)
# parser.parse(File.open(filename)
