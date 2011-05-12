Factory.define :group do |g|
  g.sequence :name do |n|
    "group#{n}"
  end
  g.sequence :subdomain do |n|
    "subdomain#{n}"
  end
  g.domain AppConfig.domain
  g.description "question-and-answer website"
  g.legend "question and answer website"
  g.state "active"
end
