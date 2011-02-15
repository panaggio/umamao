# Manage synchronization between our models and the search index.

require 'net/http'
require 'builder'

module Support::Search

  # Send a post request to the server updating the entry.
  def self.update_search_index(entry)
    Net::HTTP.start(AppConfig.search["host"],
                    AppConfig.search["port"]) do |http|
      req = Net::HTTP::Post.new("/solr/update?commit=true")
      req.basic_auth AppConfig.search["user"], AppConfig.search["password"]
      req.content_type = "app/xml"
      response = http.request(req, entry)
    end
  end

  # This module expects the following methods to be implemented by the
  # including class:
  #
  #  - search_entry : returns a hash with the fields that should go into
  #    the search server.
  #
  #  - needs_to_update_search_index? : whether or not a search index
  #    update is needed.
  #
  module Searchable
    def self.included(klass)
      klass.class_eval do
        include InstanceMethods
        after_save :update_search_index
      end
    end

    module InstanceMethods
      # Convert the hash representation of the object returned by
      # #search_entry into the format understood by Solr.
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

      # after_save callback that propagates changes to the object to
      # the search index when needed.
      def update_search_index
        if self.needs_to_update_search_index?
          Support::Search.update_search_index self.serialize_for_search_server
        end
      end
    end
  end
end
