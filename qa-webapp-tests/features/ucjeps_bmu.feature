Feature: The UCJEPS uploadmedia application
Background:

Scenario: Test image uploading functionalities in uploadmedia with both Upload... NOW and Upload... LATER       
    Given I am on the "ucjeps" homepage
    When I click "login"
    Then I will sign in
    Then I click "uploadmedia" 
    When I click "View the Job Queue" 
    Then I find the content "Job Number, Job Summary, Job Errors, Job Flag, Download Job Files" in "div#content-main"
    When I click "List Images That Failed to Load" 
    Then I find the content "Job Number, Image Filename" in "div#content-main"
    When I click "logout"
    Then I see "eloan, publicsearch, search" in "div#content-main"