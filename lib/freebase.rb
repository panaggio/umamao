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
  MIN_REQS = 1_000

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

  # pseudo_query should have keys and values for the information
  # that is known and keys and nils as values for the information
  # that is desired
  #
  # known keys are:
  #   :id: freebase id of the topic
  #   :guid: freebase guid of the topic
  #   :mid: freebase mid of the topic
  #   :pt_name: Name (title?) of the topic
  #   :wikipedia_pt_id:
  #     Wikipedia's id of the topic
  #   :wikipedia_pt:
  #     Wikipedia slug of the topic
  #
  # only one of wikipedia_pt_id and wikipedia_pt
  # should be used at once
  def self.query(pseudo_query)
    case pseudo_query
    when Array
      query = pseudo_query.map! { |pq| self.process_pseudo_query pq }
    when Hash
      query = self.process_pseudo_query(pseudo_query)
    end

    Query.new(query)
  end

  protected
  def self.process_pseudo_query(pseudo_query)
    query = {}

    pseudo_query.each do |key, expected_value|
      skey = key.to_s
      case skey
      when 'id'
        query['id'] = expected_value
      when 'guid', 'mid'
        query[skey] = [{'value' => expected_value}]
      when 'pt_name'
        query['name'] = [{
          'lang' => "/lang/#{skey[0..1]}",
          'value' => expected_value
        }]
      when /^wikipedia_pt(_id)?$/
        query['key'] = [
          if query['key']
            {'namespace' => nil, 'value' => nil}
          else
            {
              'namespace' => "/wikipedia/#{skey.sub('wikipedia_','')}",
              'value' => expected_value
            }
          end
        ]
      end
    end

    query
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
  #
  #
  # Examples of queries that may be of interest:
  #
  # Query Wikipedia content:
  #   creates a query to get wikipedia info
  #
  # example of query (in JSON):
  # "query": [{
  #   "id": "/m/0h1lf",
  #   "guid": [{"value": null}],
  #   "mid": [{"value": null}],
  #   "key": [{"namespace": null, "value": null}],
  #   "name": [{"lang": null, "value": null}]
  # }]
  #
  # the same query, as a Ruby hash:
  # {
  #   "id" => "/m/0h1lf",
  #   "mid" => [{"value" => nil}],
  #   "guid" => [{"value" => nil}],
  #   "key" => [{
  #     "namespace" => nil,
  #     "value" => nil
  #   }],
  #   "name" => [{
  #     "lang" => nil,
  #     "value" => nil
  #   }]
  # }
  #
  # Query Freebase content:
  #   creates a query to get the freebase mid
  #   based on the wikipedia pt id
  #
  # example of query (in JSON):
  # "query": [{
  #   "mid": [{"value": null}],
  #   "key": [{"namespace": "/wikipedia/pt_id", "value": 220}],
  # }]
  #
  # the same query, as a Ruby hash:
  # {
  #   "mid" => [{"value" => nil}],
  #   "key" => [{
  #     "namespace" => "/wikipedia/pt_id",
  #     "value" => "220"
  #   }]
  # }

  class StubQuery
    OK_CODE   = "/api/status/ok"
    @@q_id = 0

    attr_reader :code

    def initialize
      raise NotImplementedError
    end

    def ok?
      @code == OK_CODE
    end
  end

  class SubQuery < StubQuery
    def initialize(id, hash)
      @result = hash
      @q_id = id
      @code = hash.delete("code")
    end

    def ok?
      super and @result.any? and @result['result'].any? and @result['result'][0].any?
    end

    def result
      @result['result'][0]
    end

    def id
      @id ||= self.result['id']
    end

    def pt_title
      return @pt_title if @pt_title

      self.fillin_titles
      @pt_title
    end

    def mids
      @mids ||= self.result['mid'][0]['value']
    end

    def guid
      @guid ||= self.result['guid'][0]['value']
    end

    def pt_key
      return @pt_key if @pt_key
      fillin_keys
      @pt_key
    end

    def pt_id
      return @pt_id if @pt_id
      fillin_keys
      @pt_id
    end

    protected
    def fillin_titles
      names = self.result['name']

      if names.any?
        names.each do |h|
          case h['lang']
          when '/lang/pt'
            @pt_title = h['value'] if self.pt_id
          end
        end
      end
    end

    def fillin_keys
      keys = result['key']
      if keys
        keys.each do |h|
          case h['namespace']
          when '/wikipedia/pt'
            @pt_key = h['value']
          when '/wikipedia/pt_id'
            @pt_id = h['value']
          end
        end
      end

      nil
    end
  end

  class Query < StubQuery
    OK_STATUS = "200 OK"

    attr_reader :status, :transaction_id

    def self.[](ids)
      self.new ids
    end

    def initialize(raw_query)
      @query =
        case raw_query
        when Array
          multi_query(raw_query)
        when Hash
          multi_query([raw_query])
        end.to_json

      results
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
      @results = @results.map do |k,v|
        SubQuery.new(k,v)
      end
    end

    def ok?
      @status == OK_STATUS and super and results.any?
    end

    protected
    def multi_query(array_of_queries)
      queries = {}
      array_of_queries.each do |q|
        queries["q#{@@q_id}"] = { 'query' => [q] }
        @@q_id += 1
      end
      queries
    end
  end
end
