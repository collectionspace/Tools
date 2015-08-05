Feature: The PAHMA Portal

Scenario: Test autocomplete functionalities when making a query in the Portal (Search)
    Given I am on the "pahma" homepage 
    When I click "login"
    Then I will sign in 
    Then I will click the "search" feature
    When I enter "Ch" in the "culturetree" field
    Then I click on "Chinese" in the dropdown menu and search
    Then I find the content "Chinese" in "input#culturetree"
    When I click "logout"    
    Then I see "imaginator, search" 