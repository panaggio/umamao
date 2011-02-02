class ShareQuestionCell < Cell::Rails
  helper ApplicationHelper

  # Displays a dialog box to share a question on other site.
  def display
    @question = options[:question]
    @where = options[:where]
    render
  end

end
