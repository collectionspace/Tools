Feature: The BAMPFA Portal

Scenario: Test autocomplete functionalities when making a query in the Portal (Search)
    Given I am on the "bampfa" homepage 
    Then I will click the "search" feature
    When I enter "Te" in the "title" field
    Then I click on "Greek Temple at Aegina" in the dropdown menu and search
    Then I find "Greek Temple at Aegina" in "Title" field
    Then I sign out
    