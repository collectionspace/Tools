Feature: Botgarden landing page

Scenario: Checks that the landing page has the correct apps displayed when User signs in and signs out
    Given I am on the "botgarden" homepage 
    Then I will see all available webapps "imaginator, ireports, search"
    Then I sign out
    Then I see No apps 
