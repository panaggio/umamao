class ShareContentCell < Cell::Rails
  helper ApplicationHelper

  # Displays a dialog box to share content
  # (questions, answers, ...) on other site.
  def display
    @body = options[:body]
    @content = options[:content]
    @class_name = options[:class_name]
    @where = options[:where]
    @link = options[:link]
    @show_tabs = options[:show_tabs]
    @maxlength = case @where
    when"twitter"
      140
    when "facebook"
      420
    end
    render
  end

end
