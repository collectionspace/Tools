Feature: the UCJEPS PublicSearch application

Scenario: Find and use the publicsearch feature, including making queries, verifying results and table headers, clicking buttons and tabs, downloading csv files, and logging out.  
    Given I am on the "ucjeps" homepage 
    When I click "login"
    Then I will sign in 
    Then I check for "usericon.jpg"
    Then I click "publicsearch"

    Then I mark the checkboxes "typesonly, cultivated"
    Then I find the content "Current time:" in "div.time-rev"
    When I enter "mint" in "keyword" and click "Search"
    Then I mark the checkboxes "select-item"
    Then I mark the checkboxes "pixonly, locsonly"
    Then I verify the table headers "Specimen ID, Scientific Name, Collector, Collection Date, Collection No., County/Prov, State, Country, Locality" 
    Then I find the content "100" in "select#maxresults"
    Then I click the button "download selected as csv" and download the csv file

    When I click "Maps" 
    Then I verify the maps buttons
    When I click "map-google"
    Then I find the content "selected objects in result set examined." in "div#maps"
    When I click "map-bmapper"
    Then the url contains "http://berkeleymapper.berkeley.edu"

    When I click "Facets"
    Then I find the content "determination, majorgroup, collector, county, state, country" in "div#tabs"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "Arenaria macradenia S. Watson var. macradenia" and see it appear in the field "determination"
    Then I will click "Reset" and the "keyword" field should have "" 
    
    When I click "Help"
    Then I find the content "Some fields have an option of searching as either "keyword", "phrase", or "exact"." in "div#helpTarget"
    When I click "Credits"
    Then I find the content "For questions about the content, and to access content beyond what is provided here, please contact David Baxter, dbaxter@berkeley.edu." in "div#creditsTarget"
    When I click "Terms"
    Then I find the content "Terms of Use" in "span.pageName"
    When I go back 
    When I click "logout"