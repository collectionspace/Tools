Feature: Test whether paging through the back and next buttons work

@javascript
Scenario: Search for the website        
    Given I am on the "pahma" homepage 
    Then I will click the "search" feature
    When I enter "mask" in the Keyword "text" and click "Grid"
    Then I click the button "download selected as csv" and download the csv file
    Then I will click the arrows to toggle between pages
    Then I sign out