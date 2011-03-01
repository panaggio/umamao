require 'curb'
require 'json'
require 'nokogiri'
require "lib/wikipedia"

module Freebase
  API_URI = 'https://api.freebase.com/api'
  MQLREAD_URL = '/service/mqlread'
  QUERY = 'query='
  QUERIES = 'queries='

  DUMP_URL = 'http://download.freebase.com/datadumps/latest/'
  SIMPLE_TOPIC_DUMP_FILE = 'freebase-simple-topic-dump.tsv'
  BZIPED_SIMPLE_TOPIC_DUMP_FILE = "#{SIMPLE_TOPIC_DUMP_FILE}.bz2"
  DOWNLOAD_DIRECTORY = 'tmp/'
  MIDS_FILE = 'mids'

  # we can do 100_000 requests per day according to
  # http://wiki.freebase.com/wiki/FAQ#What_are_the_limits_on_use_of_your_API.3F
  DAILY_MAX_REQS = 100_000
  MIN_REQS = 10_000

  def self.download_simple_topic_dump
    `curl #{DUMP_URL}#{BZIPED_SIMPLE_TOPIC_DUMP_FILE} -o #{DOWNLOAD_DIRECTORY}#{BZIPED_SIMPLE_TOPIC_DUMP_FILE}`
    exit($?.exitstatus) unless $?.success?
    `bunzip2 #{DOWNLOAD_DIRECTORY}#{BZIPED_SIMPLE_TOPIC_DUMP_FILE}`
    exit($?.exitstatus) unless $?.success?
  end

  def self.extract_mids_file_from_simple_topic_dump
    File.open("#{DOWNLOAD_DIRECTORY}#{MIDS_FILE}","w") do |mids_file|
      mids = ""
      File.open("#{DOWNLOAD_DIRECTORY}#{SIMPLE_TOPIC_DUMP_FILE}").each_line do |line|
        mids << "#{line[/.+?(?=\t)/]}\n"
      end
      mids_file.print mids
    end
  end

  def self.read_mids_file
    File.read("#{DOWNLOAD_DIRECTORY}#{MIDS_FILE}").split("\n")
  end

  # FIXME: This methods is not fully tested
  def self.create_topics(mids)
    window_size = [(mids.size.to_f / DAILY_MAX_REQS).ceil, MIN_REQS].max

    while mids.any?
      window_mids = mids.shift(window_size)
      pt_titles = {}
      WikipediaQuery[window_mids].results.each do |r|
        pt_titles[r.pt_title] = r if r.ok? and r.pt_title.present?
      end

      size = pt_titles.size
      Topic.from_titles!(pt_titles.keys).each do |topic|
        q = pt_titles[topic.title]

        topic.freebase_mids = q.mids
        topic.freebase_guid = q.guid
        topic.wikipedia_pt_id = q.pt_id
        topic.wikipedia_pt_key = q.pt_key
        topic.description = q.pt_description
        topic.save
      end
    end
  end

  # query examples (from http://www.freebase.com/docs/mqlread)
  #
  # single query example:
  # {
  #   "query": [{
  #     "id": "/topic/en/edinburgh",
  #     "key": [{
  #       "namespace": "/wikipedia/en_id",
  #       "value":null
  #     }]
  #   }]
  # }
  #
  # multiple query example
  # {
  #   "q0": {
  #     "query": [{
  #       "id": "/topic/en/edinburgh",
  #       "key": [{
  #         "namespace": "/wikipedia/en_id",
  #         "value": null
  #       }]
  #     }]
  #   },
  #   "q1": {
  #     "query": [{
  #       "id": "/topic/en/hamster",
  #       "key": [{
  #         "namespace": "/wikipedia/en_id",
  #         "value":null
  #       }]
  #     }]
  #   }
  # }

  class StubQuery
    OK_CODE   = "/api/status/ok"

    attr_reader :code

    def initialize
      raise NotImplementedError
    end

    def ok?
      @code == OK_CODE
    end
  end

  class SubQuery < StubQuery
    def result
      return nil if @result.nil? or @result["result"].nil? or @result["result"][0].nil?
      @result["result"][0]
    end

    def initialize(hash)
      @result = hash
      @code = hash["code"]
    end
  end

  class Query < StubQuery
    OK_STATUS = "200 OK"

    attr_reader :status, :transaction_id

    def self.[](ids)
      self.new ids
    end

    def initialize(ids)
      q =
        case ids
        when Array
          x = _multi_query(ids)
        when String
          x = { "q" => _single_query(ids) }
        end
      @query = q.to_json
    end

    def results
      @results || results!
    end

    def results!
      @results = JSON.parse(Curl::Easy.http_post("#{API_URI}#{MQLREAD_URL}", "#{QUERIES}#{@query}").body_str)
      parse
    end

    def parse
      @code, @status, = @results["code"], @results["status"]
      @transaction_id = @results["transaction_id"]
      @results.reject!{ |k,v| ["code", "status", "transaction_id"].include? k }
      parse_sub
    end

    def ok?
      @status == OK_STATUS and super
    end

    protected
    def parse_sub
      @results = @results.map do |k,v|
        if block_given?
          yield v
        else
          SubQuery.new(v)
        end
      end
    end

    def _multi_query(ids)
      queries = {}
      ids.each_with_index do |id,i|
        queries["q#{i}"] = _single_query(id)
      end
      queries
    end

    def _single_query(hash)
      { "query" => [hash] }
    end
  end

  class WikipediaSubQuery < SubQuery
    def pt_title
      return @pt_title if @pt_title

      names = result["name"] if result
      if names
        names.each do |h|
          return @pt_title = h["value"] if h["lang"] == "/lang/pt" and pt_id
        end
      end

      if pt_key and pt_article
        @pt_title = pt_article.search("h1").text
      end
    end

    def mids
      @mids ||= result["mid"] if result
    end

    def guid
      @guid ||= result["guid"] if result
    end

    def pt_key
      @pt_key ||= _pt_key "/wikipedia/pt"
    end

    def pt_id
      @pt_id ||= _pt_key "/wikipedia/pt_id"
    end

    def pt_description
      pt_article.description
    end

    def pt_article
      @pt_article ||= WikipediaPtArticle.new(pt_key || pt_id.to_i)
    end

    protected
    def _pt_key(key)
      keys = result["key"] if result
      if keys
        keys.each do |h|
          return h["value"] if h["namespace"] == key
        end
      end

      nil
    end
  end

  class WikipediaQuery < Query
    protected
    # creates a query to get wikipedia info
    # example of query:
    #
    # "query": [{
    #   "id": "/m/0h1lf",
    #   "guid": [{"value": null}],
    #   "mid": [{"value": null}],
    #   "key": [{"namespace": null, "value": null}],
    #   "name": [{"lang": null, "value": null}]
    # }]
    def _single_query(id_or_hash)
      case id_or_hash
      when Hash
        super
      else
        super({
          "id" => id,
          "mid" => [{"value" => nil}],
          "guid" => [{"value" => nil}],
          "key" => [{
            "namespace" => nil,
            "value" => nil
          }],
          "name" => [{
            "lang" => nil,
            "value" => nil
          }]
        })
      end
    end

    def parse_sub
      super { |v| WikipediaSubQuery.new(v) }
    end
  end

  class MidQuery < Query
    protected
    # creates a query to get the freebase mid
    # based on the wikipedia pt id
    # example of query:
    #
    # "query": [{
    #   "mid": [{"value": null}],
    #   "key": [{"namespace": "/wikipedia/pt_id", "value": 220}],
    # }]
    def _single_query(id)
      super({
        "mid" => [{"value" => nil}],
        "key" => [{
          "namespace" => "/wikipedia/pt_id",
          "value" => "#{id}"
        }]
      })
    end

    def parse_sub
      super { |v| WikipediaSubQuery.new(v) }
    end
  end
end
