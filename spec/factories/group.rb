FactoryGirl.define do
  factory :group do
    name 'default_group'
    subdomain 'default'
    domain AppConfig.domain
    description "question-and-answer website"
    legend "question and answer website"
    state "active"
  end
end
