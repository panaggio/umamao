Factory.define :user do |u|
  u.name 'John Doe'
  u.password 'test1234'
  u.password_confirmation 'test1234'
  u.confirmed_at Time.now
  u.has_been_through_wizard true
  u.agrees_with_terms_of_service true
  u.sequence(:email) do |n|
    "r#{n}@example.com"
  end
end

Factory.define :affiliated_user, :parent => :user do |u|
  u.association :affiliations
end

Factory.define :admin, :parent => :user do |a|
  a.role 'admin'
end
