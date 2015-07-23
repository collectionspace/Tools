Feature: Find and use the keyword search feature of the PAHMA development server.

Scenario: Search for the website        
    Given I am on the "pahma" homepage for ""
    Then I will click the "search" feature
    When I enter "taiwan puppet" in the Keyword "text" and click "Search"
    Then I see a table with 6 headers "Museum Number, Object Name, Ethnographic File Code, Culture, Collector, Collection Date" and 4 rows "9-5793a, 9-5794a 9-5795a 9-5796a" 
    Then I will click the arrows to toggle between pages
    Then I will click the up and down arrows beside the headers
    Then I click the button "download selected as csv" and download the csv file
    When I click the "Facets" tab
    Then I see the headers "Object Name, Object Type, Collection Place, Ethnographic File Code, Culture, Materials, Collection Date"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "Puppet" and see it appear in the field "name"
    Then I will click on the "Maps" tab and see two buttons
    When I click the "map-google" button
    Then I find the content "5 points plotted. all 5 selected objects in result set examined."
    When I click the "map-bmapper" button
    Then the url contains "http://berkeleymapper.berkeley.edu"
    When I click the "Statistics" tab
    Then I will select "Museum Number" under Select field to summarize on
    Then I will see a table with the headers "Museum Number, Count"
    Then I click the button "downloadstats" and download the csv file
    Then I will click "Reset" and the "text" field should have ""
    When I enter "jade seal" in the Keyword "text" and click "Full"
    Then I will click the arrows to toggle between pages
    Then I click the button "download selected as csv" and download the csv file
    Then I verify the contents of the page
    Then sign out
