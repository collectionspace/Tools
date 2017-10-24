Feature: The UCJEPS imageserver application.

Scenario: Find and use the keyword search feature to test the imageserver application.             
    Given I am on the "ucjeps" homepage 
    When I click "login"
    Then I will sign in 
    Then I click "search" 
    When I enter "cubensis" in "keyword" and click "Search"
    Then I will click Grid and see a page of images.
    Then I will click an image with id "972d18bc-543f-442d-a643/derivatives/Medium/content" and observe url contains imageserver