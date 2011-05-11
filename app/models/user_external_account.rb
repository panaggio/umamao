class UserExternalAccount < ExternalAccount
  key :user_id, String, :required => true
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => :provider

  after_save :update_search_index
  after_destroy :update_search_index

  # We force an update on the search index if the user's external
  # accounts change.
  def update_search_index
    self.user.update_search_index(true) if self.user
  end

end
