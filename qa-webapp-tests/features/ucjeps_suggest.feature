Feature: The UCJEPS Portal

Scenario: Test autocomplete functionalities when making a query in the Portal (Search)
    Given I am on the "ucjeps" homepage 
    Then I will click the "search" feature
    When I enter "Arc" in the "locality" field
    Then I click on "Arch Beach" in the dropdown menu and search
    Then I find "Arch Beach" in "Locality" field
    Then I sign out
    