Feature: Test image uploading functionalities in PAHMA's uploadmedia

Scenario: Search for the website        
    Given I am on the "pahma" homepage for "-dev"
    Then I will click the "uploadmedia" feature
    Then I will select a file "test.jpg, test2.jpg" to upload
    Then I will click the 1 "createmedia"
    Then I see the file is uploaded
    Then I will click the 2 "uploadmedia"
    Then I see a table with 7 headers "File Name, Object Number, File Size, Date Created, Creator, Contributor, Rights Holder" and 2 rows "test.jpg, test2.jpg"
    Then sign out
