module FreebaseImporter
  def self.build_query_from_topic(topic)
    {
      :pt_title => topic.title,
      :mid => nil, :guid => :guid,
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
      topic.each_with_index do |topic, i|
        if q[i].ok? and topic.wikipedia_import_status == Wikipedia::ImportStatus::OK
          topic.freebase_mids     = q[i].mids
          topic.freebase_guid     = q[i].guid
          topic.wikipedia_pt_key  = q[i].pt_key

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
  end

  def self.fillin_topics(topics)
    topics.each do |topic|
      self.fillin_topic topic
    end
  end
end

