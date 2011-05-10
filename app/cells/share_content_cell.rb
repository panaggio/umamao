class ShareContentCell < Cell::Rails
  helper ApplicationHelper
  helper TopicsHelper

  # Displays a dialog box to share content
  # (questions, answers, ...) on other site.
  def display
    @body = options[:body]
    @content = options[:content]
    @class_name = options[:class_name]
    @where = options[:where]
    @link = options[:link]
    @maxlength = {"twitter" => 140, "facebook" => 420}
    default_url_options[:host] = AppConfig.domain
    render
  end

end
