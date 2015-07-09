Feature: Use suggest through testing of Search webapp

Scenario: Search for the Website
    Given I am on the "pahma" homepage for "-dev"
    Then I will click the "search" feature
    When I enter "Ch" in Culture field
    Then I should find Chinese in the dropdown menu.
    When I click on "Chinese" and search
    Then I should find "Chinese" in Culture field
    Then sign out
    