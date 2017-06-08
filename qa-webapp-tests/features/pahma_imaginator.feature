Feature: The PAHMA imaginator application

Scenario: Test the Imaginator by checking queries made with "Search the Metadata" and "Search for Images".      
    Given I am on the "pahma" homepage
    When I click "login"
    Then I will sign in 
    Then I click "imaginator"
    Then I will enter "keyword" "augustus" in the "Search the Metadata" field
    Then I click "2-13166" 
    Then I find the content "LatLong, Object Type,  Context of Use, Dimensions, Comment, Collection Date" in "div#content"
    Then I will enter "keyword" "1144-3742" in the "Search for Images" field 
    Then I click "1-11978" 
    Then I find the content "LatLong, Object Type,  Context of Use, Dimensions, Comment, Collection Date" in "div#content"
    When I click "logout"    
    Then I see "search" in "div#content-main"