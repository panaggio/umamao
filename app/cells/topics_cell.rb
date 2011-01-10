class TopicsCell < Cell::Rails
  include Devise::Controllers::Helpers
  helper ApplicationHelper

  # Used in settings page.
  def followed
    @topic = @opts[:topic]
    render
  end

end
