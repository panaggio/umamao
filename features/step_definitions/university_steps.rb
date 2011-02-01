Given /^a university "([^"]*)" with domain "([^"]*)"$/ do |name, domain|
  @university = University.first(:name => name) ||
    University.create!(:name => name,
                       :short_name => name,
                       :domains => [domain])
end

Given /^the university is open for signup$/ do
  @university.open_for_signup = true
  @university.save!
end

