Feature: The UCJEPS Portal

Scenario: Test autocomplete functionalities when making a query in the Portal (Search)
    Given I am on the "ucjeps" homepage 
    When I click "login"
    Then I will sign in 
    Then I will click the "search" feature
    When I enter "Arc" in the "locality" field
    Then I click on "Arch Beach" in the dropdown menu and search
    Then I find the content "Arch Beach" in "input#locality"
    When I click "logout"    
    Then I see "eloan, publicsearch" 