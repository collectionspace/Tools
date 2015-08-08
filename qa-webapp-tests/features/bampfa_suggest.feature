Feature: The BAMPFA Portal

Scenario: Test autocomplete functionalities when making a query in the Portal (Search)
    Given I am on the "bampfa" homepage 
    When I click "login"
    Then I will sign in 
    Then I will click the "search" feature
    When I enter "Te" in the "title" field
    Then I click on "Greek Temple at Aegina" in the dropdown menu and search
    Then I find the content "Greek Temple at Aegina" in "input#title"
    When I click "logout"
    Then I find the content "No Apps" in "div#content"