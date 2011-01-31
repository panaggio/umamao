require 'uri'
require 'cgi'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

module WithinHelpers
  def with_scope(locator)
    locator ? within(locator) { yield } : yield
  end

  def find_confirmation_email(address)
    sleep 1
    Delayed::Worker.new.work_off
    sleep 1
    ActionMailer::Base.deliveries.find{|message|
      message.to.include?(address) &&
      message.subject =~ /confirme/i
    }
  end

end
World(WithinHelpers)

