Feature: Find and use the eloan feature of the UCJEPS development server.

Scenario: Search for the website        
    Given I am on the "ucjeps" homepage for "-dev"
    Then I will click the "eloan" feature
    Then I will enter "UCE258" in the Search field
    Then the results displayed include "LatLong, Determination Details, Previous Determinations, Locality, Local Name, Collector, Collection Number, Locality, LatLong, Collection Date, Description, Phase, Last updated at"
    Then I see the three rows "E-loan No.:, Borrower:, E-loan Date"
    