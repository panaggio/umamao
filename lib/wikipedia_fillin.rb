module FreebaseImporter
  def self.build_query_from_topic(topic)
    {
      :pt_name => topic.title,
      :mid => nil, :guid => nil,
      :wikipedia_pt => nil
    }
  end

  def self.fillin_topic(topic)
    self.fillin_topics([topic])
  end

  def self.fillin_topics(topics)
    query = topics.map do |topic|
      self.build_query_from_topic topic
    end

    q = Freebase.query(query)
    if q.ok?
      r = q.results.sort_by{|q| q.q_id[1..-1].to_i}
      topics.each_with_index do |topic, i|
        if r[i].ok?
          topic.freebase_mids     = r[i].mids
          topic.freebase_guid     = r[i].guid
          topic.wikipedia_pt_key  = Freebase.decode r[i].pt_key

          topic.save
        else
          Rails.logger.info "Topic '#{topic.title}' couldn't be imported"
        end
      end
    end
  end
end

module WikipediaImporter
  def self.fillin_topic(topic)
    article = WikipediaPtArticle.new(topic.wikipedia_pt_id.to_i)
    topic.description = article.description
    topic.save
  end

  def self.fillin_topics(topics)
    topics.each do |topic|
      self.fillin_topic topic
    end
  end
end

