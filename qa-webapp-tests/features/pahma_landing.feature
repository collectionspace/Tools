Feature: PAHMA landing page

Scenario: Checks that the landing page has the correct apps displayed when User signs in and signs out
    Given I am on the "pahma" homepage 
    Then I will see all available webapps "imagebrowser, imaginator, ireports, search, toolbox, uploadmedia"
    Then I sign out
    Then I see "imaginator, search" 
