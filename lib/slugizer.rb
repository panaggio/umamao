module Slugizer
  def self.included(klass)
    klass.class_eval do
      include MongoMapperExt::Slugizer
      include ClassMethods
    end
  end

  module ClassMethods
    def generate_slug
      return false if self[self.class.slug_key].blank?
      self.slug = self[self.class.slug_key].to_s.gsub(" ", "_")
    end
  end
end
