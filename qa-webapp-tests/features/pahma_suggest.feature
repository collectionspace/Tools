Feature: Test autocomplete functionalities when making a query in the PAHMA Search app

Scenario: Search for the Website
    Given I am on the "pahma" homepage for "-dev"
    Then I will click the "search" feature
    When I enter "Ch" in the "culturetree" field
    Then I click on "Chinese" in the dropdown menu and search
    Then I find "Chinese" in "Culture" field
    Then sign out
    