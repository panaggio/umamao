class AutocompleteItem
  # umbrella class to index every searchable class in the same search
  include MongoMapper::Document
  include MongoMapperExt::Filter

  key :title, String
  key :entry_id
  key :entry_type, String

  filterable_keys :title

  belongs_to :entry, :polymorphic => true
end
