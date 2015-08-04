Feature: the BAMPFA Portal (Search) application

Scenario: Find and use the keyword search feature 
    Given I am on the "bampfa" homepage 
    Then I will click the "search" feature
    Then I verify the search fields "ID Number, Other Number, Item class, Artist birth Date, Artist death Date, Artist origin, Title, Keyword, Credit line, Permission to reproduce, Copyright credit, Photo credit, Date Made, Measurement, Materials, Date Acquired, Provenance, Cataloger" in "div#searchfieldsTarget"
    When I enter "dynasty" in the Keyword "text" and click "Search"
    Then I see a table with 5 headers "ID Number, Item class, Artist, Title, Measurement" and 5 rows "1999.24, 2000.55.6, 2002.43.68, 2002.43.69, 2002.43.70" 
    Then I will click the arrows to toggle between pages
    Then I will click the up and down arrows beside the headers
    Then I click the button "download selected as csv" and download the csv file
    When I click the "Maps" tab 
    Then I see two buttons
    When I click the "Statistics" tab
    Then I will select "ID Number" under Select field to summarize on
    Then I will see a table with the headers "ID Number, Count"
    Then I click the button "downloadstats" and download the csv file
    When I click the "Facets" tab
    Then I see the headers "Item class, Artist, Measurement, Materials, Cataloger"
    Then I will click the up and down arrows beside the headers without knowing table name
    Then I will click on a value "Jade seal" and see it appear in the field "materials"    
    Then I will click "Reset" and the "materials" field should have ""
    When I enter "Azumaji" in the Keyword "title" and click "Full"
    Then I will click the arrows to toggle between pages
    Then I click the button "download selected as csv" and download the csv file
    And I verify the contents of the page
    Then I sign out