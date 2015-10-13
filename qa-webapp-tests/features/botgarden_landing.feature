Feature: Botgarden landing page

Scenario: Checks that the landing page has the correct apps displayed when User signs in and signs out
    Given I am on the "botgarden" homepage 
    Then I find the content "Applications Available" in "div#content-main" 
    Then I find the content "to view all available applications" in "div#content"
    When I click "login"
    Then I find the content "Sign in to the CollectionSpace Webapps using the same login and password you use to login to the CollectionSpace system itself." in "div#login"
    Then I find the content "Or, if you want to see what is available without signing in, click" in "div#login"
    Then I will sign in 
    Then I find the content "All available Webapps" in "div#user-tools"
    Then I find the content "Sign Out" in "div#user-tools"
    Then I see "internal, ireports, search" in "div#content-main"
    When I click "logout"  
    Then I find the content "No Apps" in "div#content"