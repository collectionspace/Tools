Feature: Checks that Botgarden's dev server's landing page has the correct apps displayed when User signs in and signs out

Scenario: Search for the website
    Given I am on the "botgarden" homepage for ""
    Then I will see all available webapps "imaginator, ireports, search"
    Then sign out
    Then I see No apps 
