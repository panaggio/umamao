Factory.define :question do |q|
  q.sequence(:title) do |n|
    "Is this the #{n}th question?"
  end
  q.association :user
  q.association :group
end
