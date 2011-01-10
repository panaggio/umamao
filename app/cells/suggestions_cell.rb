# Used to display suggestions to user, allowing to follow or refuse
# them.

class SuggestionsCell < Cell::Rails
  include Devise::Controllers::Helpers

  def topics
    @user = @opts[:user]
    @suggested_topics = @user.suggested_topics
    render
  end

  def users
    @user = @opts[:user]
    @suggested_users = @user.suggested_users.select do |user|
      !@user.following?(user) && !@user.uninteresting_user_ids.include?(user.id)
    end
    render
  end
end
