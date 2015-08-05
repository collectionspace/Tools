Feature: the UCJEPS PublicSearch application

Scenario: Find and use the publicsearch feature, including making queries, verifying results and table headers, clicking buttons and tabs, downloading csv files, and logging out.  
    Given I am on the "ucjeps" homepage 
    When I click "login"
    Then I will sign in 
    Then I check for the user icon
    Then I will click the "publicsearch" feature
    When I enter "mint" in the Keyword "keyword" and click "Search"
    Then I find the content "Searching..." in "div#waitingImage"
    Then I see a table with 9 headers "Specimen ID, Scientific Name, Collector, Collection Date, Collection No., County/Prov, State, Country, Locality" and 4 rows "JEPS17761, UC284735, UC284978, UC741160" 
    Then I will click the up and down arrows beside the headers
    Then I click the button "download selected as csv" and download the csv file
    When I click "Maps" 
    Then I see two buttons
    When I click "map selected with Google staticmaps API"
    Then I find the content "selected objects in result set examined." in "div#maps"   
    When I click "map selected with Berkeley Mapper"
    Then the url contains "http://berkeleymapper.berkeley.edu"
    When I click "Facets"
    Then I see the headers "determination, majorgroup, collector, county, state, country"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "Arenaria macradenia S. Watson var. macradenia" and see it appear in the field "determination"
    Then I will click "Reset" and the "text" field should have "" 
    When I click "Help"
    Then I find the content "Some fields have an option of searching as either "keyword", "phrase", or "exact"." in "div#helpTarget"
    When I click "Credits"
    Then I find the content "For questions about the content, and to access content beyond what is provided here, please contact David Baxter, dbaxter@berkeley.edu." in "div#creditsTarget"
    When I click "Terms"
    Then I find the content "Terms of Use" in "span.pageName"