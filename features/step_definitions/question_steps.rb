When /^I post a question "([^"]*)"$/ do |question|
  fill_in "search-field", :with => question
  And 'I press "Perguntar"'
  And 'I press "Criar"'
end
