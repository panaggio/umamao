module Support::Autocompletable
  # Adds the class to a central index for autocompletion

  def self.included(klass)
    klass.class_eval do
      klass.extend ClassMethods
      after_save :update_autocomplete_item
    end
  end

  module ClassMethods
    def autocompletable_key(key)
      define_method(:update_autocomplete_item) do
        # Builds or updates the corresponding entry in the search index
        autocomplete_item = AutocompleteItem.find_by_entry_id_and_entry_type(self.id, self.class.to_s)
        if autocomplete_item
          if self.send((key.to_s + "_changed?").to_sym)
            autocomplete_item.title = self.send key.to_sym
            autocomplete_item.save!
          end
        else
          AutocompleteItem.create :title => self.send(key.to_sym), :entry => self
        end
      end

    end
  end

end
