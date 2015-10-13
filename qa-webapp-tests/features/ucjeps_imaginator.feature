Feature: The UCJEPS imaginator application

Scenario: Test the Imaginator by checking queries made with "Search the Metadata" and "Search for Images". 
    Given I am on the "ucjeps" homepage 
    When I click "login"
    Then I will sign in 
    Then I click "imaginator" 
    Then I will enter "keyword" "Collection des Plantes Alpines" in the "Search the Metadata" field
    Then I click "GOD340"
    Then I find the content "LatLong, Collector(s) (verbatim), Date Collected, Locality (verbatim), Locality Note, Country, Previous Determinations, Label Header, Cultivated, Phase, Determination Details, Type Assertions?" in "div#content"
    Then I will enter "keyword" "Ambroise" in the "Search for Images" field
    Then I verify a page only listing images
    Then I click "GOD362"
    Then I find the content "LatLong, Collector(s) (verbatim), Date Collected, Locality (verbatim), Locality Note, Country, Previous Determinations, Label Header, Cultivated, Phase, Determination Details, Type Assertions?" in "div#content"
    When I click "logout"
    Then I see "eloan, publicsearch, search" in "div#content-main"