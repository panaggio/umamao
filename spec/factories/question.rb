Factory.define :question do |q|
  q.sequence(:title) do |n|
    "Question #{n}"
  end
  q.association :user
  q.group Group.first
end
