Feature: Checks that BAMPFA's dev server's landing page has the correct apps displayed when User signs in and signs out

Scenario: Search for the website
    Given I am on the "bampfa" homepage for "-dev"
    Then I will see all available webapps "imagebrowser, imaginator, ireports, search, uploadmedia"
    Then sign out
    Then I see No apps 
