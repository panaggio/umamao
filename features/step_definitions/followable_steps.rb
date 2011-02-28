require File.dirname(__FILE__) + "/step_helper"

Then /^I should see my picture in the followers box$/ do
  assert has_css?(".followers[data-entry-type=question] " +
                  "img[alt=\"#{@my_user.name}\"]")
end

Given /^I do not follow a question$/ do
  @question =
    Question.all.find{|question| !question.watchers.include?(@my_user.id)}
  if !@question
    user = User.first(:id.ne => @my_user.id)
    @question = Question.create!(:title => "What does Y mean?",
                                 :user => user, :group => Group.first)
  end
  assert(@question)
end

Then /^I should not see my picture in the followers box$/ do
  assert !has_css?(".followers[data-entry-type=question] " +
                   "img[alt=\"#{@my_user.name}\"]")
end

Given /^I don't follow the user Adam$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I should see the button "([^"]*)"$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end

Given /^Adam follows me$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^I should see Adam's picture under "([^"]*)"$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then /^I should see my picture under "([^"]*)"$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end
