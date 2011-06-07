Factory.define :waiting_user do |wu|
  wu.sequence(:email) do |n|
    "wu#{n}@example.com"
  end
end
