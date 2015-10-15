Feature: The BAMPFA imaginator application

Scenario: Test the Imaginator by checking queries made with "Search the Metadata" and "Search for Images". 
    Given I am on the "bampfa" homepage 
    When I click "login"
    Then I will sign in 
    Then I click "imaginator" 
    Then I will enter "keyword" "greek" in the "Search the Metadata" field
    Then I click "1943.29" 
    Then I find the content "Item class, Artist, Artist origin, Artist birth Date, Title, Credit line, Permission to reproduce, Date Made, Measurement, Materials, Date Acquired, Cataloger, Current location, Current crate" in "div#content"
    Then I will enter "keyword" "morning" in the "Search for Images" field
    Then I verify a page only listing images
    Then I click "1966.45" 
    Then I find the content "Item class, Artist, Artist origin, Artist birth Date, Title, Credit line, Permission to reproduce, Date Made, Measurement, Materials, Date Acquired, Cataloger, Current location, Current crate" in "div#content"
    When I click "logout"
    Then I find the content "No Apps" in "div#content"