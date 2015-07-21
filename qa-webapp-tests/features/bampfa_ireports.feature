Feature: Navigate the BAMPFA ireports feature, select a report, enter a query, and check the report, reset, and back buttons.

Scenario: Search for the website
    Given I am on the "bampfa" homepage for ""
    Then I will click the "ireports" feature
    Then I select a report called "Image Metadata"
    When I enter "1995.46.257.a-d" in the Keyword "idNumber" and click "report"
    Then I will see the correct report in pdf format
    Then I will click "params-reset" and the "idNumber" field should have ""
    When I click "back"
    Then I will see a list of reports as follows "CollObjs Modified in Last30Days, Image Metadata, Person: Incomplete Artists" and files "bampfaCollObjModifiedLast30.jrxml, bampfaImageMetadata.jrxml, bampfaPersonIncompleteArtist.jrxml"
    Then sign out
