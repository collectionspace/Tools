Feature: the UCJEPS PublicSearch application

Scenario: Find and use the publicsearch feature, including making queries, verifying results and table headers, clicking buttons and tabs, downloading csv files, and logging out.  
    Given I am on the "ucjeps" homepage 
    Then I check for the user icon
    Then I will click the "publicsearch" feature
    When I enter "mint" in the Keyword "keyword" and click "Search"
    Then I find the content "Searching..." in "div#waitingImage"
    Then I see a table with 9 headers "Specimen ID, Scientific Name, Collector, Collection Date, Collection No., County/Prov, State, Country, Locality" and 4 rows "JEPS17761, UC284735, UC284978, UC741160" 
    Then I will click the up and down arrows beside the headers
    Then I click the button "download selected as csv" and download the csv file
    When I click the "Maps" tab 
    Then I see two buttons
    When I click the "map selected with Google staticmaps API" button
    Then I find the content "selected objects in result set examined." in "div#maps"   
     When I click the "map selected with Berkeley Mapper" button
    Then the url contains "http://berkeleymapper.berkeley.edu"
    When I click the "Facets" tab
    Then I see the headers "determination, majorgroup, collector, county, state, country"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "Arenaria macradenia S. Watson var. macradenia" and see it appear in the field "determination"
    Then I will click "Reset" and the "text" field should have "" 
    When I click the "Help" tab
    Then I find the content "Some fields have an option of searching as either "keyword", "phrase", or "exact"." in "div#helpTarget"
    When I click the "Credits" tab
    Then I find the content "For questions about the content, and to access content beyond what is provided here, please contact David Baxter, dbaxter@berkeley.edu." in "div#creditsTarget"
    When I click the "Terms" tab
    Then I find the content "Terms of Use" in "span.pageName"