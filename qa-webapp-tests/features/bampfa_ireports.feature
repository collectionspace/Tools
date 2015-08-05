Feature: The BAMPFA ireports feature

Scenario: Navigate the ireports feature, select a report, enter a query, and check the report, reset, and back buttons.
    Given I am on the "bampfa" homepage 
    When I click "login"
    Then I will sign in 
    Then I will click the "ireports" feature
    Then I select a report called "Image Metadata"
    When I enter "1995.46.257.a-d" in the Keyword "idNumber" and click "report"
    Then I will see the correct report in pdf format
    Then I will click "params-reset" and the "idNumber" field should have ""
    When I click "back"
    Then I find the content "CollObjs Modified in Last30Days, Image Metadata, Person: Incomplete Artists" in "div#content"
    Then I find the content "bampfaCollObjModifiedLast30.jrxml, bampfaImageMetadata.jrxml, bampfaPersonIncompleteArtist.jrxml" in "div#content"
    When I click "logout"
    Then I find the content "No Apps" in "div#content"