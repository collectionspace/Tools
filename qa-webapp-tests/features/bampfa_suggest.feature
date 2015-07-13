Feature: Test autocomplete functionalities when making a query in the BAMPFA Search app

Scenario: Search for the Website
    Given I am on the "bampfa" homepage for "-dev"
    Then I will click the "search" feature
    When I enter "Te" in the "title" field
    Then I click on "Greek Temple at Aegina" in the dropdown menu and search
    Then I find "Greek Temple at Aegina" in "Title" field
    Then sign out
    