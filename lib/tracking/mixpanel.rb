#Encapsulates the Mixpanel API as a Ruby (Rails) model.
#See http://www.bingocardcreator.com/articles/tracking-with-mixpanel.htm for usage notes.
#This code is copyright Patrick McKenzie, 2009.
#It is released under the MIT license (same as Rails).
#Short version: do whatever you want, just don't sue me.
#Long version: http://www.opensource.org/licenses/mit-license.php

module Tracking
class Mixpanel
  require 'net/http'

  attr_accessor :options
  attr_accessor :event

  #This is the URL for the mixpanel API call.  It is frozen when track! is called on this object.
  #The reasons for this are subtle, and mostly related to delayed_job serialization.
  attr_accessor :saved_url_params

  def self.logger
    Rails.logger
  end

  def self.log_event(event, user_id, ip, opts = {})
    opts.merge!({:event => event, :id => user_id, :ip => ip})
    logged_event = Mixpanel.new(opts)
    self.logger.info "Mixpanel: #{logged_event.inspect}, #{logged_event.url_params}"
    logged_event.track!
  end

  def initialize(opts = {})
    @options = {}
    @options['ip'] = opts[:ip] unless opts[:ip].nil?
    @options['time'] = Time.now.to_i
    @options['token'] = TOKEN
    @options['distinct_id'] = opts[:id] unless opts[:id].blank?
    @event = opts[:event] unless opts[:event].nil?
    opts.each do |key, value|
      unless [:ip, :id, :event].include? key
        @options[key.to_s] = value.to_s
      end
    end
  end

  def raw_data
    hash = {}
    hash['event'] = @event
    hash['properties'] = @options
    ActiveSupport::JSON.encode(hash)
  end

  def serialize_data
    Base64.encode64s(raw_data)
  end

  def url_params
    "data=#{serialize_data}".tap { |params|
      params << '&ip=1' if (@options['ip'].nil?)
      params << '&test=1' if !Rails.env.production?
    }
  end

  def track!()
    @saved_url_params = url_params

    #If you have DelayedJob installed, this will use it, otherwise it fires the request *immediately*.
    #This is a very bad idea for most uses because it will result in *your* site blocking while waiting
    #for the Mixpanel API to return.  Be smart: install DelayedJob.
    if (respond_to? :send_later)
      dj = send_later :access_api!
      dj.priority = -1 #This puts the Mixpanel DJs on the lowest priority so that
      dj.save          #they don't block print jobs on BCC if Mixpanel times out.
    else
      access_api!
    end
  end

  def access_api!
    if Rails.env.production?
      res = Net::HTTP.start("api.mixpanel.com", 80) {|http|
        http.read_timeout = 60
        http.request_post("/track/", @saved_url_params)
      }
    end
  end
end
end
