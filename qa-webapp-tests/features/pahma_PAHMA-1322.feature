Feature: Test whether paging through the back and next buttons work

@javascript
Scenario: Search for the website        
    Given I am on the "pahma" homepage for "-dev"
    Then I will click the "search" feature
    When I enter "taiwan puppet" in the Keyword "text" and click "Grid"
    Then I will click the arrows to toggle between pages
    Then sign out