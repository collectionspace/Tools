Feature: Find and use the keyword search feature of the Botgarden development server.

Scenario: Search for the website        
    Given I am on the "botgarden" homepage for "-dev"
    Then I will click the "search" feature
    When I enter "arabica" in the Keyword "text" and click "Search"
    Then I see a table with 10 headers "Accession Number, Scientific Name, Collector, Collector Number, Country, Family, Garden Location, Rare?, Dead?, Flower Color" and 7 rows "2001.0086, 2012.0151, 2012.0719, 67.0394, 67.0394, 76.0795, 87.0915" 
    Then I will click the up and down arrows beside the headers
    Then I download the csv file
    When I click the Facets tab
    Then I see the headers "Collector Number, County, State, Country, Family, Garden Location, Rare?, Dead?, Flower Color"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "s.n." and see it appear in the field "collectornumber"
    Then I will click on the "Maps" tab and see two buttons
    When I click the google map I see "0 points plotted. all 4 selected objects in result set examined."
    When I click the bmapper, the url contains "http://berkeleymapper.berkeley.edu"
    When I will click the Statistics tab
    Then I will select "Accession Number" under Select field to summarize on
    Then I will see a table with the headers "Accession Number, Count"
    Then I will click "Reset" and the "text" field should be empty
    Then sign out

