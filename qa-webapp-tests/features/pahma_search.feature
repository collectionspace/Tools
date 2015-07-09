Feature: Find and use the keyword search feature of the PAHMA development server.

Scenario: Search for the website        
    Given I am on the "pahma" homepage for "-dev"
    Then I will click the "search" feature
    When I enter "taiwan doll" in the Keyword "text" and click "Search"
    Then I see a table with 6 headers "Museum Number, Object Name, Ethnographic File Code, Culture, Collector, Collection Date" and 4 rows "9-13106, 9-13107, 9-13108, 9-13109, 9-13110" 
    Then I will click the up and down arrows beside the headers
    Then I download the csv file
    When I click the Facets tab
    Then I see the headers "Object Name, Object Type, Collection Place, Ethnographic File Code, Culture, Materials, Collection Date"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "doll" and see it appear in the field "name"
    Then I will click on the "Maps" tab and see two buttons
    When I click the google map I see "5 points plotted. all 5 selected objects in result set examined."
    When I click the bmapper, the url contains "http://berkeleymapper.berkeley.edu"
    When I will click the Statistics tab
    Then I will select "Museum Number" under Select field to summarize on
    Then I will see a table with the headers "Museum Number, Count"
    Then I will click "Reset" and the "text" field should have ""
    Then sign out
