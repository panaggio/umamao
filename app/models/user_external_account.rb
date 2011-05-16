class UserExternalAccount < ExternalAccount
  key :user_id, String, :required => true
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => :provider

  after_save :update_search_index
  after_destroy :update_search_index
  after_create :suggest, :if => lambda { |ext_account|
    ["facebook", "twitter"].include? ext_account.provider
  }

  # We force an update on the search index if the user's external
  # accounts change.
  def update_search_index
    self.user.update_search_index(true) if self.user
  end

  def suggest
    self.user.suggestion_list.suggest_from_outside({self.provider => true})
    self.user.suggestion_list.save
  end
  handle_asynchronously :suggest
end
