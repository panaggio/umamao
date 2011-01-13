class ShareQuestionCell < Cell::Rails
  helper ApplicationHelper

  # Displays a dialog box to share a question on other site.
  def display
    @question = @opts[:question]
    @recently_connected_to = @opts[:recently_connected_to]
    render
  end

end
