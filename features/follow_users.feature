Feature: Follow users
  In order to stay up to date on the activities of other users
  as a logged-in user
  I want to be able to follow them

  Scenario: Seeing profile of user not currently being followed
    Given I don't follow the user Adam
    When I go to Adam's profile
    Then I should see the button "follow"

  Scenario: Seeing profile of user currently being followed
    Given I don't follow the user Adam
    When I go to Adam's profile
    Then I should see the button "unfollow"

  Scenario: Seeing follower's picture in my profile
    Given Adam follows me
    When I go to my profile
    Then I should see Adam's picture under "followers"

  Scenario: Seeing followee's picture in my profile
    Given I follow the user Adam
    When I go to my profile
    Then I should see Adam's picture under "following"

  Scenario: Seeing my picture in followee's profile
    Given I follow the user Adam
    When I go to Adam's profile
    Then I should see my picture under "followers"
