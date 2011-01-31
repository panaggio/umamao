FactoryGirl.define do
  factory :question do
    title
    user_id
    group Group.first
  end
end
