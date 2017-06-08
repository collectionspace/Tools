Feature: The PAHMA imageserver application.

Scenario: Find and use the keyword search feature to test the imageserver application.             
    Given I am on the "pahma" homepage 
    When I click "login"
    Then I will sign in 
    Then I click "search"
    When I enter "taiwan doll" in "keyword" and click "Search"
    Then I will click Grid and see a page of images.
    Then I will click the arrows to toggle between pages
    Then I will click an image with id "704a8cbc-8ac5-419d-960e/derivatives/OriginalJpeg/content" and observe url contains imageserver