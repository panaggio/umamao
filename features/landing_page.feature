Feature: Landing page
  In order to see what my app is about
  a logged-out user
  wants to be able to see the landing page

  Scenario: Visiting the site for the first time
    Given I am on the home page
    Then I should see "Fazer cadastro"
