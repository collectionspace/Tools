Feature: The BAMPFA imagebrowser

Scenario: Find and use the imagebrowser feature, including making searches, verifying headers, downloading .csv files, and clicking tabs.
    Given I am on the "bampfa" homepage 
    When I click "login"
    Then I will sign in
    Then I click "imagebrowser"
    When I search for "wolf" in "keyword" and enter "10"
    Then I click "1995.46.437.48"
    Then I find the content "keywords, maximum number of objects to retrieve" in "div#content"
    When I click "logout"
    Then I find the content "No Apps" in "div#content"