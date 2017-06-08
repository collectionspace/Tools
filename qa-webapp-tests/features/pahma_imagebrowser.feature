Feature: The PAHMA imagebrowser

Scenario: Find and use the imagebrowser feature, including making searches, verifying headers, downloading .csv files, and clicking tabs.       
    Given I am on the "pahma" homepage 
    When I click "login"
    Then I will sign in 
    Then I click "imagebrowser"
    When I search for "textile" in "keyword" and enter "10"
    Then I click "1-13841"
    Then I find the content "Cradle frame" in "div#content"
    When I click "logout"    
    Then I see "search" in "div#content-main"