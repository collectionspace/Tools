Feature: Test image uploading functionalities in BAMPFA's uploadmedia with both Upload... NOW and Upload... LATER

Scenario: Search for the website        
    Given I am on the "bampfa" homepage for "-dev"
    Then I will click the "uploadmedia" feature
    Then I will click the "View the Job Queue" button
    Then I will see a table with the headers "Job Number, Job Summary, Job Errors, Job Flag, Download Job Files" 
    Then sign out
