Feature: the PAHMA Portal (Search) application

Scenario: Find and use the keyword search feature 
    Given I am on the "pahma" homepage
    When I click "login"
    Then I will sign in 
    Then I click "search" 
    Then I verify the search fields "Keyword, Museum Number, Alternate Number, Accession Number, Object Name, Description, Collection Place, Culture, Materials, Inscription, Collector, Object Type, Ethnographic File Code, Production Date, Collection Date, Acquisition Date, Accession Date" in "div#searchfieldsTarget"
    
    When I enter "Oyo" in the "fcp" field
    Then I click on "Oyo, Nigeria, Western Africa" in the dropdown menu and search    
    Then I verify the table headers "Museum Number, Object Name, Ethnographic File Code, Culture, Collector, Collection Date" 
    Then I will click the arrows to toggle between pages
    Then I click the button "download selected as csv" and download the csv file
    Then I mark the checkboxes "pixonly, locsonly"
    
    When I click "Maps"
    Then I verify the maps buttons
    When I click "map-google"
    Then I find the content "selected objects in result set examined." in "div#maps"
    When I click "map-bmapper"
    Then the url contains "http://berkeleymapper.berkeley.edu"
    
    When I click "Statistics"
    Then I will select "Museum Number" under Select field to summarize on
    Then I find the content "Museum Number, Count" in "div#statsresults"
    Then I click the button "downloadstats" and download the csv file
    
    When I click "Facets"
    Then I find the content "Object Name, Object Type, Collection Place, Ethnographic File Code, Culture, Materials, Collection Date" in "div#tabs"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "textile fragments" and see it appear in the field "name"    
    Then I will click "Reset" and the "name" field should have ""
    
    When I enter "jade seal" in "keyword" and click "Full"
    Then I will click the arrows to toggle between pages
    Then I click the button "download selected as csv" and download the csv file
    And I verify the contents of the page
    Then I find the content "Current time:" in "div#container" 
    When I find the content "About, Help, Credits, Terms" in "div.unitnav"
    When I click "logout"    
    Then I see "search" in "div#content-main"