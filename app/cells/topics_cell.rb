class TopicsCell < Cell::Rails
  include Devise::Controllers::Helpers
  helper ApplicationHelper

  def suggestions
    @user = @opts[:user]
    @topics = @user.suggested_topics
    render
  end

  # Bulk-following of topics (user settings, signup wizard, etc)
  def follow
    @user = @opts[:user]
    @topics = Topic.query(:follower_ids => @user.id).
      paginate(:per_page => 100, :page => @opts[:page] || 1)
    render
  end

  def followed
    @topic = @opts[:topic]
    render
  end

end
