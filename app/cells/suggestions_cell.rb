# Used to display suggestions to user, allowing to follow or refuse
# them.

class SuggestionsCell < Cell::Rails
  include Devise::Controllers::Helpers
  helper UsersHelper

  def topics
    @suggested_topics = current_user.suggestion_list.suggested_topics
    render
  end

  def users
    @suggested_users = current_user.suggestion_list.suggested_users
    render
  end
end
