module TopicsHelper

  # Small topic container used throughout the site.
  def topic_box(topic)
    '<li><div class="topic"><span class="topic-title">' +
      (link_to h(topic.title), topic_url(topic)) +
      '</span></div></li>'
  end

  def link_to_topic(topic, text = nil)
    text ||= topic.title
    link_to h(text), topic, :title => topic_help_text(topic)
  end

  def topic_help_text(topic)
    if topic.description.present?
      truncate_words(remove_links(topic.description), 100)
    else
      topic.title
    end
  end

  private

  def remove_links(description)
    description.gsub(/\[([^\]]*)\]\[\d*\]/, '\1').gsub(/\[\d*\]: [^ ]*/, '').gsub(/ +/, " ").gsub(/[\r\n]/, '')
  end

end
