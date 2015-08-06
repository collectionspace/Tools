Feature: The PAHMA imagebrowser

Scenario: Find and use the imagebrowser feature, including making searches, verifying headers, downloading .csv files, and clicking tabs.       
    Given I am on the "pahma" homepage 
    When I click "login"
    Then I will sign in 
    Then I will click the "imagebrowser" feature
    When I search for "textile" and enter "20"
    Then I see "24" images displayed
    When I click on museum number "1-13841"
    Then I see a page with these headers "Results, Facets, Maps, Statistics"
    Then I click the button "download selected as csv" and download the csv file
    When I click "Facets"
    Then I see a table with 6 headers "Object Name, Object Type, Collection Place, Ethnographic File Code, Culture, Materials, Collection Date" and 2 cols "Value, F" 
    When I click "logout"    
    Then I see "imaginator, search" 