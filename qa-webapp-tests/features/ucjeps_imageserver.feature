Feature: Find and use the keyword search feature of the UCJEPS development server to test imageserver.

Scenario: Search for the website        
    Given I am on the "ucjeps" homepage for ""
    Then I will click the "search" feature
    When I enter "cubensis" in the Keyword "keyword" and click "Search"
    Then I see a table with 9 headers "Specimen ID, Scientific Name, Collector(s) (verbatim), Collection Number, Date Collected, Locality, County, State, Country" and 4 rows "UC153077, UC1624977, UC1624978, UC1624979" 
    Then I will click Grid and see a page of images.
    Then I will click an image with id "972d18bc-543f-442d-a643/derivatives/Medium/content" and observe url contains imageserver
    Then I will navigate to a bad id "972d18bc-543f-442d-a643/derivatives/Medium/content" and observe the 'image not available' jpg
