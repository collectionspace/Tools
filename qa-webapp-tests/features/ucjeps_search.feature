Feature: the UCJEPS Portal (Search) application

Scenario: Find and use the keyword search feature 
    Given I am on the "ucjeps" homepage 
    When I click "login"
    Then I will sign in 
    Then I will click the "search" feature
    Then I verify the search fields "Scientific Name, Collector(s), Locality, County, Major Group, Date Collected, Associated Taxa, Keyword, Collection Number, Specimen ID, Country" in "div#searchfieldsTarget"
    When I enter "cubensis" in the Keyword "keyword" and click "Search"
    Then I find the content "Searching..." in "div#waitingImage"
    Then I see a table with 9 headers "Specimen ID, Scientific Name, Collector(s) (verbatim), Collection Number, Date Collected, Locality, County, State, Country" and 4 rows "UC153077, UC1624977, UC1624978, UC1624979" 
    Then I will click the arrows to toggle between pages
    Then I will click the up and down arrows beside the headers
    Then I click the button "download selected as csv" and download the csv file
    Then I mark the checkboxes "pixonly, locsonly"
    When I click "Maps" 
    Then I see two buttons
    When I click "map selected with Google staticmaps API"
    Then I find the content "selected objects in result set examined." in "div#maps"
    When I click "map-bmapper"
    Then the url contains "http://berkeleymapper.berkeley.edu"
    When I click "Statistics"
    Then I will select "Specimen ID" under Select field to summarize on
    Then I will see a table with the headers "Specimen ID, Count"
    Then I click the button "downloadstats" and download the csv file
    When I click "Facets"
    Then I see the headers "Scientific Name, Major Group, Family, Collector(s), County, State, Country"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "Barbella cubensis (Mitt.) Broth." and see it appear in the field "determination"
    Then I will click "Reset" and the "keyword" field should have ""
    When I enter "UC1624979" in the Keyword "accession" and click "Full"
    Then I will click the arrows to toggle between pages
    Then I click the button "download selected as csv" and download the csv file
    And I verify the contents of the page
    Then I find the content "Current time:" in "div#container"
    When I click "logout"    
    Then I see "eloan, publicsearch" 