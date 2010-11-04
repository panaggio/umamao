module Scopes

  def self.included(klass)
    klass.class_eval do
      klass.extend ClassMethods

      scope :latest, sort(:created_at.desc)

      # Receives one or two Time arguments
      # One argument: list users created _after_ time
      # Two arguments: list users created in time range
      scope :created, lambda { |*args|
        gte, lte = args.size > 1 ? args : [args.first, nil]
        where(:created_at.gte => gte.utc,
              :created_at.lte => lte ? lte.utc : Time.now.utc)
      }
    end
  end

  module ClassMethods
    def method_missing(method, *args, &block)
      if method.to_s =~ /^by_(.*)/ && args.size == 1 && block.nil?
        all($1.to_sym => args.first)
      else
        super(method, args, block)
      end
    end
  end
end

