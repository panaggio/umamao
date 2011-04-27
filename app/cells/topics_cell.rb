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
    @user_topics = UserTopicInfo.query(:user_id => @user.id, :following => true,
                                  :order => :answers_count.desc,
                                  :limit => 7)

    @path = topics_user_path @user
    render
  end

end
