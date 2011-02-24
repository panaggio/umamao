class TopicsCell < Cell::Rails
  include Devise::Controllers::Helpers
  include AuthenticatedSystem
  helper ApplicationHelper
  helper_method :current_user

  # Used in settings page.
  def followed
    @topic = options[:topic]
    render
  end

  def small_list
    @user = options[:user]
    @topics = Topic.query(:follower_ids => @user.id, :limit => 7)
    @path = topics_user_path @user
    render
  end

end
