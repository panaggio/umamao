class TopicsCell < Cell::Rails
  include Devise::Controllers::Helpers
  helper ApplicationHelper

  def suggestions
    @user = @opts[:user]
    @topics = @user.suggested_topics
    render
  end

end
