# Used to display suggestions to user, allowing to follow or refuse
# them.

class SuggestionsCell < Cell::Rails
  include Devise::Controllers::Helpers
  include AuthenticatedSystem
  helper ApplicationHelper
  helper UsersHelper
  helper TopicsHelper
  helper FollowableHelper
  helper_method :current_user

  before_filter :define_domain

  def define_domain
    default_url_options[:host] = request.host_with_port
  end

  def topics
    if options.present? and options[:single_column]
      user_suggestions = UserSuggestion.query(
        :accepted_at => nil, :rejected_at => nil, :user_id => current_user.id)
      @suggested_topics = user_suggestions.map(&:entry).uniq.first(7)
      @suggested_topics.map! do |entry|
        [ entry,
          user_suggestions.select{ |s| s.entry_id == entry.id }.map(&:origin) ]
      end

      topic_suggestions = current_user.topic_suggestions[0 .. 7 - @suggested_topics.size]
      @suggested_topics +=
        Topic.all(:id.in => topic_suggestions.map(&:entry_id))
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
    if options.present? and options[:single_column]
      user_suggestions = current_user.user_suggestions[0 .. 3]
      @suggested_users =
        User.query(:id.in => user_suggestions.map(&:entry_id))
    else
      left_last = [3, (current_user.user_suggestions.length/2.0).ceil - 1].min
      right_first = [4, (current_user.user_suggestions.length/2.0).ceil].min
      right_last = [7, current_user.user_suggestions.length, right_first + left_last].min
      user_suggestions_left = current_user.user_suggestions[0 .. left_last]
      user_suggestions_right = current_user.user_suggestions[right_first .. right_last]
      @suggested_users_left =
        User.query(:id.in => user_suggestions_left.map(&:entry_id))
      @suggested_users_right =
        User.query(:id.in => user_suggestions_right.map(&:entry_id))
    end
    render
  end
end
