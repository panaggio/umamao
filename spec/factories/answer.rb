Factory.define :answer do |a|
  a.body "answer"
  a.association :user
  a.association :question
  a.association :group
end
