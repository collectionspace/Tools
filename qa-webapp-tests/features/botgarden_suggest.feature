Feature: The Botgarden Portal 

Scenario: Test autocomplete functionalities when making a query in the Portal (Search)
    Given I am on the "botgarden" homepage 
    When I click "login"
    Then I will sign in 
    Then I will click the "search" feature
    When I enter "Az" in the "fcpverbatim" field
    Then I click on "Azores, Pico, Santa Luzia" in the dropdown menu and search
    Then I find the content "Azores, Pico" in "input#fcpverbatim"
    When I click "logout"  
    Then I find the content "No Apps" in "div#content"