# This controller is used to share topics on other websites

class ShareTopicController < ShareContentController
  CONTENT_CLASS = Topic

  def default_body
    args = {
      :site => AppConfig.application_name,
      :title => @content.title
    }
    body = t("topics.share_body.#{self.content_class_str}", args)
    { 'facebook' => body, 'twitter' => body }
  end
end
