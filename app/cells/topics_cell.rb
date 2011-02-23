class TopicsCell < Cell::Rails
  include Devise::Controllers::Helpers
  include AuthenticatedSystem
  helper ApplicationHelper
  helper_method :current_user

  cache :small_list do |cell, options|
    user = cell.options[:user]
    "user/#{user.id}/topics/#{Topic.query(:follower_ids => user.id).count}"
  end

  # Used in settings page.
  def followed
    @topic = options[:topic]
    render
  end

  def small_list
    @user = options[:user]
    @topics = Topic.query(:follower_ids => @user.id, :limit => 7)
    render
  end

end
