Feature: Find and use the keyword search feature of the UCJEPS dev server.

Scenario: Search for the website        
    Given I am on the "ucjeps" homepage for ""
    Then I will click the "publicsearch" feature
    When I enter "mint" in the Keyword "keyword" and click "Search"
    Then I see a table with 9 headers "Specimen ID, Scientific Name, Collector, Collection Date, Collection No., County/Prov, State, Country, Locality" and 4 rows "JEPS17761, UC284735, UC284978, UC741160" 
    Then I will click the up and down arrows beside the headers
    Then I click the button "download selected as csv" and download the csv file
    When I click the "Facets" tab
    Then I see the headers "determination, majorgroup, collector, county, state, country"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "Arenaria macradenia S. Watson var. macradenia" and see it appear in the field "determination"
    Then I will click on the "Maps" tab and see two buttons
    When I click the "map selected with Google staticmaps API" button
    Then I find the content "0 points plotted. all 3 selected objects in result set examined."
    When I click the "map selected with Berkeley Mapper" button
    Then the url contains "http://berkeleymapper.berkeley.edu"
    Then I will click "Reset" and the "text" field should have ""
    Then sign out