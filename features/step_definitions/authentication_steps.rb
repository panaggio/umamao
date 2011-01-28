Given /^I am logged in as "([^"]+)"$/ do |name|
  @my_user = User.find_by_name(name) ||
    FactoryGirl.create(:user, :name => name, :email => "#{name.downcase}@example.com")
  Given 'I go to the login page'
  fill_in "user_email", :with => @my_user.email
  fill_in "user_password", :with => "test1234"
  click_button "Entrar"
end

Given /^I am not signed in$/ do
  sign_in_as nil
end
