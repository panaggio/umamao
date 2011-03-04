module TopicsHelper

  def topic_help_text(topic)
    if topic.description.present?
      cut_description(remove_links(topic.description))
    else
      topic.title
    end
  end

  private

  def remove_links(description)
    description.gsub(/\[([^\]]*)\]\[\d*\]/, '\1').gsub(/\[\d*\]: [^ ]*/, '').gsub(/ +/, " ").gsub(/[\r\n]/, '')
  end

  def cut_description(description)
    if description.length > 100
      "#{description[0, 97]}..."
    else
      description
    end
  end
end
