module TopicsHelper

  # Small topic container used throughout the site.
  def topic_box(topic)
    '<li><div class="topic"><span class="topic-title">' +
      (link_to h(topic.title), topic_url(topic)) +
      '</span></div></li>'
  end
end
