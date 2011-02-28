Then /^a confirmation email should be sent to "([^"]*)"$/ do |address|
  assert(find_confirmation_email(address))
end

Then /^I should receive an answer notification email$/ do
  assert(find_answer_notification_email_to(@my_user.email))
end

Then /^I should not receive an answer notification email$/ do
  assert(!find_answer_notification_email_to(@my_user.email))
end

