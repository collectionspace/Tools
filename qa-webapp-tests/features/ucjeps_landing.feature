Feature: Checks that UCJEP's dev server's landing page has the correct apps displayed when User signs in and signs out

Scenario: Search for the website
    Given I am on the "ucjeps" homepage for ""
    Then I will see all available webapps "eloan, publicsearch, search"
    Then sign out
    Then I see "eloan, publicsearch" 
