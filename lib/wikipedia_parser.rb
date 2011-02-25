require "nokogiri"

class WikipediaPagesArticleDumpParser < Nokogiri::XML::SAX::Document
  def  start_document
    @inside = {
      "page" => false,
      "title" => false,
      "id" => false
    }

    @topics = []
  end

  def end_document
    File.open("tmp/wikipedia_hash_dump", "w") do |f|
      f.write(YAML.dump @topics)
    end
  end

  def start_element(element, attributes = [])
    @inside[element] = true
    @topic = {} if element == "page"
  end

  def end_element(element)
    @inside[element] = false
    @topics << @topic if element == "page"
  end
  
  def characters(text)
    state = @inside.select{|s,status| status}[0]
    if ["title", "id"].include? state
      @topic[state] = text
    end
  end
end

parser = Nokogiri::XML::SAX::Parser.new(WikipediaPagesArticleDumpParser.new)
parser.parse(File.open(ARGV[0]))
