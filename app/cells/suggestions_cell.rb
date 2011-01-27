# Used to display suggestions to user, allowing to follow or refuse
# them.

class SuggestionsCell < Cell::Rails
  include Devise::Controllers::Helpers
  helper UsersHelper

  def topics
    @topic_suggestions = current_user.topic_suggestions[0 .. 6]
    @render_links = @opts[:render_links]
    render
  end

  def users
    @user_suggestions = current_user.user_suggestions[0 .. 6]
    render
  end
end
