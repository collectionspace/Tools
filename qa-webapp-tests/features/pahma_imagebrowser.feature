Feature: Find and use the imagebrowser feature of the PAHMA development server.

Scenario: Search for the website        
    Given I am on the "pahma" homepage for "-dev"
    Then I will click the "imagebrowser" feature
    When I search for "textile" and enter "20"
    Then I see "20" objects out of however many there are
    When I click on musueum number "1-13841"
    Then I see a page with these headers "Results, Facets, Maps, Statistics"
    When I download the csv file
    When I click on Facets Tab
    Then I see a table with 6 headers "Object Name, Object Type, Collection Place, Ethnographic File Code, Culture, Materials, Collection Date" and 2 cols "Value, F" 
    Then sign out
