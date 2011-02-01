Given /^I have signed up with email "([^"]*)"$/ do |affiliation_email|
  @affiliation_email = affiliation_email
  visit path_to("the home page")
  fill_in("affiliation_email", :with => @affiliation_email)
  click_button("affiliation_submit")
end

When /^I wait "([^"]*)" seconds$/ do |seconds|
  sleep seconds.to_i
end
