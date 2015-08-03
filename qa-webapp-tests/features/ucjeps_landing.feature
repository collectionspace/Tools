Feature: UCJEPS landing page

Scenario: Checks that the landing page has the correct apps displayed when User signs in and signs out
    Given I am on the "ucjeps" homepage 
    Then I will see all available webapps "eloan, publicsearch, search"
    Then I sign out
    Then I see "eloan, publicsearch" 
