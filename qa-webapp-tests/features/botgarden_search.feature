Feature: the Botgarden Portal (Search) application

Scenario: Find and use the keyword search feature 
    Given I am on the "botgarden" homepage 
    When I click "login"
    Then I will sign in 
    Then I will click the "search" feature
    Then I verify the search fields "Accession Number, Scientific Name, Family, Collector Number, Collection Date, Field Place Name, County, State, Country, Flower Color, Flowering, Fruiting, Elevation, Habitat, Keyword, Garden Location, Geographic Place Name, Rare?, Conservation Organization, Has Vouchers, Dead?, Authors (parsed), Bracket Authorship, Canonical Name Complete, Genus or above, Infraspecific Epithet, Rank Marker, Specific Epithet" in "div#searchfieldsTarget"
    When I enter "arabica" in the Keyword "text" and click "Search"
    Then I find the content "Searching..." in "div#waitingImage"
    Then I see a table with 10 headers "Accession Number, Scientific Name, Collector, Collector Number, Country, Family, Garden Location, Rare?, Dead?, Flower Color" and 7 rows "2001.0086, 2012.0151, 2012.0719, 67.0394, 67.0394, 76.0795, 87.0915" 
    Then I will click the arrows to toggle between pages
    Then I will click the up and down arrows beside the headers
    Then I click the button "download selected as csv" and download the csv file
    Then I mark the checkboxes "pixonly, locsonly"
    When I click "Maps" 
    Then I see two buttons
    When I click "map selected with Google staticmaps API"
    Then I find the content "selected objects in result set examined." in "div#maps"
    When I click "Statistics"
    Then I will select "Accession Number" under Select field to summarize on
    Then I will see a table with the headers "Accession Number, Count"
    Then I click the button "downloadstats" and download the csv file
    When I click "Facets"
    Then I see the headers "Collector Number, County, State, Country, Family, Garden Location, Rare?, Dead?, Flower Color"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "s.n." and see it appear in the field "collectornumber"
    Then I will click "Reset" and the "collectornumber" field should have ""
    When I enter "NURS, California Cultivar Gdn" in the Keyword "gardenlocation" and click "Full"
    Then I will click the arrows to toggle between pages
    Then I click the button "download selected as csv" and download the csv file
    And I verify the contents of the page
    Then I find the content "Current time:" in "div#container"
    When I click "logout"  
    Then I find the content "No Apps" in "div#content"