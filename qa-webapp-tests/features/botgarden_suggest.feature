Feature: The Botgarden Portal 

Scenario: Test autocomplete functionalities when making a query in the Portal (Search)
    Given I am on the "botgarden" homepage 
    Then I will click the "search" feature
    When I enter "Az" in the "fcpverbatim" field
    Then I click on "Azores, Pico, Santa Luzia" in the dropdown menu and search
    Then I find "Azores, Pico" in "Field Place Name" field
    Then I sign out