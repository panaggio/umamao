require "nokogiri"
require "curl"
require "json"

class WikipediaArticle
  WIKIPEDIA_URL = "http://en.wikipedia.org/wiki/"
  WIKIPEDIA_CURID_URL = "http://en.wikipedia.org/w/index.php?curid="
  
  def self.url
    WIKIPEDIA_URL
  end

  def self.id_url
    WIKIPEDIA_CURID_URL
  end

  def initialize(id_or_slug)
    case id_or_slug
    when String
      @slug = id_or_slug
    when Integer
      @id = id_or_slug
    end

    article
  end

  def url
    @url ||= 
      if @slug
        "#{self.class.url}#{slug}"
      else
        "#{self.class.id_url}#{id}"
      end
  end

  def article
    @article ||= curl(url)
  end

  def parsed_article
    @parsed_article ||= Nokogiri::HTML(article)
  end

  def media_wiki_info
    json = parsed_article.search("script")[1].  # get target script
      children.to_s.split("\n")[1].             # get the first line of it
      sub(/.*config\.set\(/,"").sub(/\);$/,"")  # keep only the json object
    @media_wiki_info = JSON.parse json if json
  end

  def description
    # grab the first paragraph from wikipedia article and remove note references from it
    @description ||= parsed_article.search("#bodyContent > p:first").text.gsub(/\[.*?\]/, "")
  end

  def id
    @id ||= media_wiki_info["wgArticleId"]
  end

  def slug
    @slug ||= (@media_wiki_info["wgPageName"] if @media_wiki_info) || 
      parsed_article.search(".printfooter > a").text.sub(/.*\//, "")
      # http://pt.wikipedia.org/wiki/Astronomia => Astronomia
  end

  protected
  def curl(url)
    Curl::Easy.http_get(url){ |easy| 
      easy.useragent = "UmamãoBot/0.1 (+http://umamao.com/)"
    }.body_str
  end
end

class WikipediaPtArticle < WikipediaArticle
  WIKIPEDIA_PT_URL = "http://pt.wikipedia.org/wiki/"
  WIKIPEDIA_PT_CURID_URL = "http://pt.wikipedia.org/w/index.php?curid="
  
  def self.url
    WIKIPEDIA_PT_URL
  end

  def self.id_url
    WIKIPEDIA_PT_CURID_URL
  end
end
