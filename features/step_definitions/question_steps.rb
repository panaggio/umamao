When /^I post a question "([^"]*)"$/ do |question|
  fill_in "search-field", :with => question
  And 'I press "Perguntar"'
  And 'I press "question_submit"'
  @question = Question.find_by_title(question)
  assert(@question)
end

Given /^I follow a question$/ do
  other_user = User.first(:id.ne => @my_user.id)
  @question ||= FactoryGirl.create(:question,
                                   :title => "What does X mean?",
                                   :user_id => other_user.id)
  @question.add_watcher(@my_user)
end

Given /^there are no questions$/ do
  Question.delete_all
end

When /^"([^"]*)" posts an answer to that question$/ do |user|
  @user = User.find_by_name(user)
  @answer = Answer.create!(:body => "O RLY?",
                           :question => @question,
                           :user => @user,
                           :group => Group.first)
end

When /^I post an answer to that question$/ do
  @answer = Answer.create!(:body => "O RLY?",
                           :question => @question,
                           :user => @my_user,
                           :group => Group.first)
end

