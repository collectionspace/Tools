Feature: Find and use the imagebrowser feature of the BAMPFA development server.

Scenario: Search for the website        
    Given I am on the "bampfa" homepage for "-dev"
    Then I will click the "imagebrowser" feature
    When I search for "wolf" and enter "20"
    Then I see "8" images displayed
    When I click on museum number "1995.46.437.48"
    Then I see a page with these headers "Results, Facets, Maps, Statistics"
    Then I click the button "download selected as csv" and download the csv file
    When I click the "Facets" tab
    Then I see a table with 6 headers "Item class, Artist, Measurement, Materials, Cataloger" and 2 cols "Value, F" 
    Then sign out
