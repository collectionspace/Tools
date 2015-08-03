Feature: The BAMPFA uploadmedia application

Scenario: Test image uploading functionalities in uploadmedia with both Upload... NOW and Upload... LATER       
    Given I am on the "bampfa" homepage
    Then I will click the "uploadmedia" feature
    When I click the "View the Job Queue" button
    Then I will see a table with the headers "Job Number, Job Summary, Job Errors, Job Flag, Download Job Files" 
    Then I sign out