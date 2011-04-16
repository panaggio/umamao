class TopicsCell < Cell::Rails
  include Devise::Controllers::Helpers
  include AuthenticatedSystem
  helper ApplicationHelper
  helper TopicsHelper
  helper FollowableHelper
  helper_method :current_user

  before_filter :define_domain

  def define_domain
    default_url_options[:host] = request.host_with_port
  end

  # Used in settings page.
  def followed
    @topic = options[:topic]
    render
  end

  def small_list
    @user = options[:user]
    @topics = Topic.query(:follower_ids => @user.id, :limit => 14)
    @path = topics_user_path @user
    render
  end

end
