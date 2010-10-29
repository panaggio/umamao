Given /^I am signed in as ([^\"]+)$/ do |name|
  user = User.find_by_name(name) || Factory(:user, :name => name)
  Given 'I go to the login page'
  fill_in :email, :with => user.email
  fill_in :password, :with => user.password
  click_button
end

Given /^I am not signed in$/ do
  sign_in_as nil
end
