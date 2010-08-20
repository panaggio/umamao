atom_feed do |feed|
  title = "#{AppConfig.domain} - #{@user.name}'s Questions"
  feed.title(title)
  unless @questions.empty?
    feed.updated(@questions.first.updated_at)
  end

  for question in @questions
    next if question.nil? || question.updated_at.blank?
    feed.entry(question, :url => question_url(question)) do |entry|
      entry.title(question.title)
      entry.content(markdown(question.body), :type => 'html')
      entry.author do |author|
        author.name(question.user.name)
      end
    end
  end
end
