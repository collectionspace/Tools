Feature: The PAHMA Portal

Scenario: Test autocomplete functionalities when making a query in the Portal (Search)
    Given I am on the "pahma" homepage 
    Then I will click the "search" feature
    When I enter "Ch" in the "culturetree" field
    Then I click on "Chinese" in the dropdown menu and search
    Then I find "Chinese" in "Culture" field
    Then I sign out
    