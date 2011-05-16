Factory.define :question_list do |ql|
  ql.sequence :title do |n|
    "Question list #{n}"
  end
  ql.association :main_topic
  ql.association :user
  ql.topics{ |topics| [topics.association(:topic)] }
end
