Feature: Signup
  In order to use the website
  I want to be able to signup

  Background: Unicamp
    Given a university "Unicamp" with domain "unicamp.br"
    And the university is open for signup

  Scenario: First time signup with academic email
    Given there is no user with email "fulano@unicamp.br"
    And I am on the home page
    When I fill in "affiliation_email" with "fulano@unicamp.br"
    And I press "affiliation_submit"
    Then I should see "Obrigado"
    And a confirmation email should be sent to "fulano@unicamp.br"

  Scenario: First time signup with "wrong" academic email
    Given there is no user with email "joao@unicamp.br"
    And I am on the home page
    When I fill in "affiliation_email" with "joao@unicamp.br   "
    And I press "affiliation_submit"
    Then I should see "Obrigado"
    And a confirmation email should be sent to "joao@unicamp.br"

  Scenario: University affiliation confirmation
    Given there is no user with email "fulano2@unicamp.br"
    And I have signed up with email "fulano2@unicamp.br"
    When I go to the confirmation page
    And I wait "1" seconds
    And I fill in "user[email]" with "fulano2@unicamp.br"
    And I fill in "user[password]" with "asdfasdf"
    And I fill in "user[password_confirmation]" with "asdfasdf"
    And I fill in "user[name]" with "Fulano"
    And I check "user[agrees_with_terms_of_service]"
    And I press "Criar conta"
    And I follow "Próxima"
    And I follow "Terminar"
    Then I should see "Leia"
