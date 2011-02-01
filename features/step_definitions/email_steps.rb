Then /^a confirmation email should be sent to "([^"]*)"$/ do |address|
  assert(find_confirmation_email(address))
end

