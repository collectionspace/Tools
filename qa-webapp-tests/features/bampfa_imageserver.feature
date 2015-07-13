Feature: Find and use the keyword search feature of the BAMPFA development server to test imageserver.

Scenario: Search for the website        
    Given I am on the "bampfa" homepage for "-dev"
    Then I will click the "search" feature
    When I enter "glass" in the Keyword "materials" and click "Search"
    Then I see a table with 5 headers "ID Number, Item class, Artist, Title, Measurement" and 4 rows "1965.31, 1966.15, 1970.83, 1971.55" 
    Then I will click Grid and see a page of images.
    Then I will click an image with id "e5477fd9-61a1-4474-a9af/derivatives/Medium/content" and observe url contains imageserver
    Then I will navigate to a bad id "e5477fd9-61a1-4474-a9af/derivatives/Medium/content" and observe the 'image not available' jpg
    