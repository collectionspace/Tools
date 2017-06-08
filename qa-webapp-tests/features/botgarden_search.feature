Feature: the Botgarden Portal (Search) application

Scenario: Test the search form and tab features
    Given I am on the "botgarden" homepage 
    When I click "login"
    Then I will sign in 
    Then I click "search"
    Then I verify the search fields "Accession Number, Scientific Name, Family, Collector Number, Collection Date, Field Place Name, County, State, Country, Flower Color, Flowering (months), Fruiting (months), Keyword, Garden Location, Geographic Place Name, Rare?, Conservation Organization, Has Vouchers, Dead?" in "div#searchfieldsTarget"
    
    When I enter "Az" in the "fcpverbatim" field
    Then I click on "Azores, Pico, Santa Luzia" in the dropdown menu and search
    Then I find the content "Azores, Pico" in "input#fcpverbatim"
    Then I will click "Reset" and the "fcpverbatim" field should have ""

    When I enter "arabica" in "keyword" and click "Search"
    Then I find the content "Searching..." in "div#waitingImage"
    Then I verify the table headers "Accession Number, Scientific Name, Collector, Collector Number, Family, Garden Location, Rare?, Dead?, Flower Color" 
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
    Then I will select "Accession Number" under Select field to summarize on
    Then I find the content "Accession Number, Count" in "div#statsresults"
    Then I click the button "downloadstats" and download the csv file

    When I click "Facets"
    Then I find the content "Collector Number, County, State, Country, Family, Garden Location, Rare?, Dead?, Flower Color" in "div#tabs"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "s.n." and see it appear in the field "collectornumber"
    Then I will click "Reset" and the "collectornumber" field should have ""

    When I enter "NURS, California Cultivar Gdn" in "gardenlocation" and click "Full"
    Then I will click the arrows to toggle between pages
    Then I click the button "download selected as csv" and download the csv file
    And I verify the contents of the page
    Then I find the content "Current time:" in "div#container" 
    When I find the content "About, Help, Credits, Terms" in "div.unitnav"
    When I click "logout"  
    Then I find the content "No Apps" in "div#content"