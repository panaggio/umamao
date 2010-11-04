Feature: News feed
  In order to receive relevant content
  as a logged-in user
  I want to have a personal news feed

  Scenario: Not following any users
    Given I don't follow any users
    When I go to the home page
    Then I should not see news items from users
    And I should see a link to follow users

  Scenario: Not following any topics
    Given I don't follow any topics
    When I go to the home page
    Then I should not see news items from topics
    And I should see a link to follow topics

  Scenario: Followed user posts a question
    Given I follow the user Adam
    And Adam creates a question
    When I go to the home page
    Then I should see a news item referring to the creation of that question

  Scenario: New question on followed topic
    Given I follow the topic Algorithms
    And a question is posted on the topic Algorithms
    When I go to the home page
    Then I should see a news item referring to the creation of that question
