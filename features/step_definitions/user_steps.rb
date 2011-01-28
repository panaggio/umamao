Given /^a user "([^"]*)"$/ do |name|
  User.find_by_name(name) ||
    Factory(:user, :name => name, :email => "#{name.downcase}@example.com")
end

Given /^there are no users$/ do
  User.delete_all
end

Given /^there is no user with email "([^"]*)"$/ do |email|
  if user = User.first(:email => email)
    user.destroy
  end
  if affiliation = Affiliation.first(:email => email)
    affiliation.destroy
  end
end
