Feature: Find and use the keyword search feature of the BAMPFA development server.

Scenario: Search for the website        
    Given I am on the "bampfa" homepage for ""
    Then I will click the "search" feature
    When I enter "dynasty" in the Keyword "text" and click "Search"
    Then I see a table with 5 headers "ID Number, Item class, Artist, Title, Measurement" and 5 rows "1999.24, 2000.55.6, 2002.43.68, 2002.43.69, 2002.43.70" 
    Then I will click the arrows to toggle between pages
    Then I will click the up and down arrows beside the headers
    Then I click the button "download selected as csv" and download the csv file
    When I click the "Facets" tab
    Then I see the headers "Item class, Artist, Measurement, Materials, Cataloger"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "Jade seal" and see it appear in the field "materials"
    Then I will click on the "Maps" tab and see two buttons
    When I click the "Statistics" tab
    Then I will select "ID Number" under Select field to summarize on
    Then I will see a table with the headers "ID Number, Count"
    Then I click the button "downloadstats" and download the csv file
    Then I will click "Reset" and the "text" field should have ""
    When I enter "Azumaya" in the Keyword "title" and click "Full"
    Then I will click the arrows to toggle between pages
    Then I click the button "download selected as csv" and download the csv file
    Then I verify the contents of the page
    Then sign out

