module Support
module TokenConfirmable
  def self.included(klass)
    klass.class_eval do
      extend ClassMethods
      include InstanceMethods
      before_create :generate_confirmation_token
    end
  end

  module ClassMethods
    def token_confirmable_key(key)
      @@token_confirmable_key = key
    end

    def generate_token
      loop do
        token = ActiveSupport::SecureRandom.base64(15).tr('+/=', '-_ ').strip.
          delete("\n")

        if self.where(@@token_confirmable_key => token).count == 0
          break token
        end
      end
    end
  end

  module InstanceMethods
    def generate_confirmation_token
      self.send(self.class.class_eval("@@token_confirmable_key").to_s + '=', self.class.generate_token)
      self.sent_at = Time.now.utc
    end

    def generate_confirmation_token!
      self.generate_confirmation_token && self.save(:validate => false)
    end
  end
end
end
