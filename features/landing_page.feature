Feature: Landing page
  In order to see what this app is about
  as a logged-out user
  I want to be able to see the landing page

  Scenario: Visiting the site for the first time
    Given I am on the home page
    Then I should see "Fazer cadastro"
