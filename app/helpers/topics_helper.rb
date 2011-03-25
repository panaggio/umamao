module TopicsHelper

  # Small topic container used throughout the site.
  def topic_box(topic, question = nil, options = {})
    "<li><div class='topic'><span class='topic-title'>#{
      if options[:logged_in] or (self.respond_to?(:logged_in?) and logged_in?)
        if question && options[:ajax_add]
          "<a class='remove' href='#{question_url(question)}/unclassify?topic=#{h(topic.title)}'>✕</a>"
        else
          "<input type='hidden' name='question[topics][]' value='#{topic.title}'/><span class='remove'>✕</span>"
        end
      end
    }#{link_to_topic(topic)}</span></div></li>"
  end

  # this should be defined as
  # link_to_topic(topic, text, options)
  # but as ruby1.8 doesn't support named parameters,
  # this workaround was done
  def link_to_topic(topic, *parameters)
    case parameters.size
    when 1:
      if parameters[0].is_a? String
        text = parameters[0]
      elsif parameters[0].is_a? Hash
        options = parameters[0]
      end
    when 2:
      text = parameters[0]
      options = parameters[1]
    end

    text ||= topic.title
    options ||= {}

    link_to h(text), topic_url(topic), :data => h(topic_tooltip(topic, options))
  end

  def topic_tooltip(topic, options = {})
    options.reverse_merge! :render_follow_button => true

    "<div class='tooltip topic-tooltip'><span class='followers-count'>#{
        t('followable.followers', :count => topic.followers_count)
    }</span>#{
      if options[:render_follow_button]
        render(
          :partial => "topics/follow",
          :locals => {:topic => topic, :block => "block"})
      end
    }<hr/>#{
      if topic.description.present?
        "<div class='description'>#{
          desc = strip_tags(markdown(topic.description, :render_links => false))
          link_to truncate_words(desc), topic_path(topic)
        }</div>"
      else
        link_to t('topics.tooltip.describe', :title => topic.title), edit_topic_path(topic)
      end
    }</div>"
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
