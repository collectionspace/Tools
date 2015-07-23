Feature: Find and use the keyword search feature of the UCJEPS dev server.

Scenario: Search for the website        
    Given I am on the "ucjeps" homepage for ""
    Then I will click the "search" feature
    When I enter "cubensis" in the Keyword "keyword" and click "Search"
    Then I see a table with 9 headers "Specimen ID, Scientific Name, Collector(s) (verbatim), Collection Number, Date Collected, Locality, County, State, Country" and 4 rows "UC153077, UC1624977, UC1624978, UC1624979" 
    Then I will click the arrows to toggle between pages
    Then I will click the up and down arrows beside the headers
    Then I click the button "download selected as csv" and download the csv file
    When I click the "Facets" tab
    Then I see the headers "Scientific Name, Major Group, Family, Collector(s), County, State, Country"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "Barbella cubensis (Mitt.) Broth." and see it appear in the field "determination"
    Then I will click on the "Maps" tab and see two buttons
    When I click the "map selected with Google staticmaps API" button
    Then I find the content "0 points plotted. all 4 selected objects in result set examined."
    When I click the "map-bmapper" button
    Then the url contains "http://berkeleymapper.berkeley.edu"
    When I click the "Statistics" tab
    Then I will select "Specimen ID" under Select field to summarize on
    Then I will see a table with the headers "Specimen ID, Count"
    Then I click the button "downloadstats" and download the csv file
    Then I will click "Reset" and the "keyword" field should have ""
    When I enter "UC1624979" in the Keyword "accession" and click "Full"
    Then I will click the arrows to toggle between pages
    Then I click the button "download selected as csv" and download the csv file
    Then I verify the contents of the page
    Then sign out
