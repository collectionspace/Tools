Feature: The BAMPFA imagebrowser

Scenario: Find and use the imagebrowser feature, including making searches, verifying headers, downloading .csv files, and clicking tabs.
    Given I am on the "bampfa" homepage 
    When I click "login"
    Then I will sign in
    Then I will click the "imagebrowser" feature
    When I search for "wolf" and enter "20"
    Then I see "8" images displayed
    When I click on museum number "1995.46.437.48"
    Then I see a page with these headers "Results, Facets, Maps, Statistics"
    Then I click the button "download selected as csv" and download the csv file
    When I click "Facets"
    Then I see a table with 6 headers "Item class, Artist, Measurement, Materials, Cataloger" and 2 cols "Value, F" 
    When I click "logout"
    Then I find the content "No Apps" in "div#content"