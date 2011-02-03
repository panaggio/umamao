class ShareQuestionCell < Cell::Rails
  helper ApplicationHelper

  # Displays a dialog box to share a question on other site.
  def display
    @question = options[:question]
    @where = options[:where]
    @link = options[:link]
    @maxlength = case @where
    when"twitter"
      140
    when "facebook"
      420
    end
    render
  end

end
