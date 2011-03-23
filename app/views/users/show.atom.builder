atom_feed do |feed|
  title = t("users.show.atom.title",
            :site_name => AppConfig.application_name,
            :user => @user.name)
  # title = "#{AppConfig.domain} - #{@user.name}'s Updates"
  feed.title(title)
  unless @items.empty?
    feed.updated(@items.first.updated_at)
  end

  for item in @items
    next if item.nil? || item.updated_at.blank?

    url = nil
    case item.entry_type
    when "Question"
      kind = t("users.show.atom.question")
      question = item.entry
      url = question_url(question)
      body = question.body
    when "Answer"
      kind = t("users.show.atom.answer")
      answer = item.entry
      question = answer.question
      url = question_answer_url(question, answer)
      body = answer.body
    end
    next if url.nil?

    feed.entry(item, :url => url) do |entry|
      entry.title("#{kind} #{question.title}")
      entry.content(markdown(body), :type => 'html')
      entry.author do |author|
        author.name(item.author.name)
      end
    end
  end
end
