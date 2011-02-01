module Support
  module NewsExpirer
    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
        include InstanceMethods
      end
    end
  end

  module InstanceMethods
  end

  module ClassMethods
    def expire_news_fragments(q)
      User.all.each do |u|
        if u.news_items.include? q
          expire_fragment("user_news_items_#{u.id}")
        end
      end
    end
  end
end
