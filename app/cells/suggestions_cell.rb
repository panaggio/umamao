# Used to display suggestions to user, allowing to follow or refuse
# them.

class SuggestionsCell < Cell::Rails
  include Devise::Controllers::Helpers
  helper UsersHelper

  def topics
    if options.present? and options[:single_column]
      topic_suggestions = current_user.topic_suggestions[0 .. 6]
      @suggested_topics =
        Topic.query(:id.in => topic_suggestions.map(&:entry_id))
    else
      # Calculate the bounds to each column
      left_last = [6, (current_user.topic_suggestions.length/2.0).ceil - 1].min
      right_first = [7, (current_user.topic_suggestions.length/2.0).ceil].min
      right_last = [13, current_user.topic_suggestions.length].min

      topic_suggestions_left = current_user.topic_suggestions[0 .. left_last]
      topic_suggestions_right = current_user.topic_suggestions[right_first .. right_last]
      @suggested_topics_left =
        Topic.query(:id.in => topic_suggestions_left.map(&:entry_id))
      @suggested_topics_right =
        Topic.query(:id.in => topic_suggestions_right.map(&:entry_id))
    end
    render
  end

  def users
    @user_suggestions = current_user.user_suggestions[0 .. 6]
    @suggested_users =
      User.query(:id.in => @user_suggestions.map(&:entry_id))
    render
  end
end
