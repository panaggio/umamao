require "nokogiri"
require "curl"
require "json"

module Wikipedia
  module ImportStatus
    OK = 'imported'
    UNKNOWN_ERROR = 'unknown error'
    EMPTY_ARTICLE = 'parse error: empty article'
  end

  DOWNLOAD_DIRECTORY = "tmp/"

  DUMP_URL = "http://dumps.wikimedia.org/ptwiki/latest/"
  ARTICLES_XML = "ptwiki-latest-pages-articles.xml"
  BZIPED_ARTICLES_XML = "#{ARTICLES_XML}.bz2"

  OFFICIAL_NAMESPACES = [
    'Discussão', 'Usuário', 'Usuário_Discussão', 'Wikipédia', 'Wikipédia_Discussão',
    'Ficheiro', 'Ficheiro_Discussão', 'MediaWiki', 'MediaWiki_Discussão',
    'Predefinição', 'Predefinição_Discussão', 'Ajuda', 'Ajuda_Discussão', 'Categoria',
    'Categoria_Discussão', 'Portal', 'Portal_Discussão', 'Anexo', 'Anexo_Discussão'
  ]

  OFFICIAL_PSEUDO_NAMESPACES = [ 'WP', 'A', 'C', 'P', 'U' ]

  NAMESPACES = OFFICIAL_NAMESPACES + OFFICIAL_PSEUDO_NAMESPACES + [ 'Wikipedia', 'Wp' ]

  def self.download_wikipedia_articles_dump
    `curl #{DUMP_URL}#{BZIPED_ARTICLES_XML} -o #{DOWNLOAD_DIRECTORY}#{BZIPED_ARTICLES_XML}`
    raise "Download failed with status #{$?.exitstatus}" unless $?.success?
    `bunzip2 #{DOWNLOAD_DIRECTORY}#{BZIPED_ARTICLES_XML}`
    raise "bunzip2 failed with status #{$?.exitstatus}" unless $?.success?
  end

  def self.decode(str)
    str.gsub(/\%[0-9a-fA-F]{2}/){|s| s[1..-1].to_i(16).chr}
  end
end

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
      if @slug
        "#{self.class.url}#{@slug}"
      else
        "#{self.class.id_url}#{@id}"
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
    return @description if @description

    self.slug

    nodes = []
    parsed_article.search("#bodyContent > *").each do |node|
      break if node.name =='h2'

      if node.name == 'p'
        node.search('a').each do |a|
          case a['href']
          when /^#/
            a['href'] = self.url << a['href']
          when /^\/wiki\//
            a['href'] = "http://pt.wikipedia.org" << a['href']
          end
        end
        nodes << node.to_html
      end

    end

    @description =
      if nodes.any?
        nodes.join <<
          Nokogiri::HTML::Builder.new do |doc|
            doc.p {
              doc.text "Fonte: "
              doc.a('href' => self.class.url, 'target' => '_blank') {
                doc.text "Wikipédia"
              }
              doc.text ". Leia o "
              doc.a('href' => self.url, 'target' => '_blank') {
                doc.text "artigo completo"
              }
              doc.text "."
            }
          end.doc.search('p').to_html
      else
        ''
      end
  end

  def id
    @id ||= media_wiki_info["wgArticleId"]
  end

  def slug
    @slug ||= Wikipedia.decode((@media_wiki_info["wgPageName"] if @media_wiki_info) ||
      parsed_article.search(".printfooter > a").text.sub(/.*\//, ""))
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
