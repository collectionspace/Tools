Feature: Find and use the keyword search feature of the PAHMA development server to test imageserver.

Scenario: Search for the website        
    Given I am on the "pahma" homepage for ""
    Then I will click the "search" feature
    When I enter "taiwan doll" in the Keyword "text" and click "Search"
    Then I see a table with 6 headers "Museum Number, Object Name, Ethnographic File Code, Culture, Collector, Collection Date" and 4 rows "9-13106, 9-13107, 9-13108, 9-13109, 9-13110" 
    Then I will click Grid and see a page of images.
    Then I will click the arrows to toggle between pages
    Then I will click an image with id "704a8cbc-8ac5-419d-960e/derivatives/OriginalJpeg/content" and observe url contains imageserver
    Then I will navigate to a bad id "704a8cbc-8ac5-419d-960e/derivatives/OriginalJpeg/content" and observe the 'image not available' jpg
