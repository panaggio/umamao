Factory.sequence(:email) do |n|
  "r#{n}@example.com"
end

Factory.define :user do |u|
  u.name
  u.password 'test1234'
  u.password_confirmation 'test1234'
  u.confirmed_at Time.now
  u.has_been_through_wizard true
  u.agrees_with_terms_of_service true
  u.email { Factory.next(:email) }
end
