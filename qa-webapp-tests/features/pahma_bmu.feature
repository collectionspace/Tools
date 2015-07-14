Feature: Test image uploading functionalities in PAHMA's uploadmedia with both Upload... NOW and Upload... LATER

Scenario: Search for the website        
    Given I am on the "pahma" homepage for "-dev"
    Then I will click the "uploadmedia" feature
    Then I will select a file "test.jpg" to upload
    Then I will click the 1 "createmedia"
    Then I see a table with 7 headers "File Name, Object Number, File Size, Date Created, Creator, Contributor, Rights Holder" and 1 rows "test.jpg"
    Then I will select a file "test2.jpg" to upload
    Then I will click the 2 "uploadmedia"
    Then I see a table with 7 headers "File Name, Object Number, File Size, Date Created, Creator, Contributor, Rights Holder" and 1 rows "test2.jpg"
    Then sign out
