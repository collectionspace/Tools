Feature: The BAMPFA uploadmedia application
Background:

Scenario: Test image uploading functionalities in uploadmedia with both Upload... NOW and Upload... LATER       
    Given I am on the "bampfa" homepage
    When I click "login"
    Then I will sign in
    Then I will click the "uploadmedia" feature
    When I click "View the Job Queue" 
    Then I will see a table with the headers "Job Number, Job Summary, Job Errors, Job Flag, Download Job Files" 
    When I click "logout"
    Then I find the content "No Apps" in "div#content"