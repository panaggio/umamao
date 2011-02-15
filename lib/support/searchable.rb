require 'net/http'
require 'builder'

module Support::Searchable
  def self.included(klass)
    klass.class_eval do
      include InstanceMethods
    end
  end

  module InstanceMethods
    def serialize_for_search_server
      data = Builder::XmlMarkup.new
      data.add {
        data.doc {
          self.search_entry.each do |k, v|
            data.field(v.to_s, :name => k.to_s)
          end
        }
      }
    end

    def update_search_index
      Net::HTTP.start(AppConfig.search["host"], AppConfig.search["port"]) do |http|
        req = Net::HTTP::Post.new("/solr/update?commit=true")
        req.basic_auth AppConfig.search["user"], AppConfig.search["password"]
        req.content_type = "app/xml"
        response = http.request(req, self.serialize_for_search)
      end
    end
  end
end
