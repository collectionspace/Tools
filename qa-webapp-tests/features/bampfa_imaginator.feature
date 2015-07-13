Feature: Test the BAMPFA Imaginator app by checking queries made with "Search the Metadata" and "Search for Images".

Scenario: Search for the website        
    Given I am on the "bampfa" homepage for "-dev"
    Then I will click the "imaginator" feature
    Then I will enter "greek" in the Search the Metadata field
    Then I will select the item "1943.29" and results displayed include the following "Item class, Artist, Artist origin, Artist birth Date, Title, Credit line, Permission to reproduce, Date Made, Measurement, Materials, Date Acquired, Cataloger, Current location, Current crate"
    When I enter "morning" in the Search for Images
    Then I see page only listing images
    When I click an image with "idnumber=1966.45"
    Then I will select the item "1966.45" and results displayed include the following "Item class, Artist, Artist origin, Artist birth Date, Title, Credit line, Permission to reproduce, Date Made, Measurement, Materials, Date Acquired, Cataloger, Current location, Current crate"
    Then sign out
