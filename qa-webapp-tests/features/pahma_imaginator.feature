Feature: The PAHMA imaginator application

Scenario: Test the Imaginator by checking queries made with "Search the Metadata" and "Search for Images".      
    Given I am on the "pahma" homepage
    When I click "login" 
    Then I will sign in 
    Then I will click the "imaginator" feature
    Then I will enter "augustus" in the Search the Metadata field
    Then I will select the item "2-13166" and results displayed include the following "LatLong, Museum Number, Object Name, Ethnographic File Code, Culture, Collector, Collection Date"
    When I enter "augustus" in the Search for Images
    Then I verify a page only listing images
    When I click an image with "musno=8-3989"
    Then I will select the item "8-3989" and results displayed include the following "LatLong, Museum Number, Object Name, Ethnographic File Code, Culture, Collector, Collection Date"
    When I click "logout"    
    Then I see "imaginator, search" 