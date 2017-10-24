Feature: Find and use the eloan feature of the UCJEPS development server.

Scenario: Search for the website        
    Given I am on the "ucjeps" homepage 
    When I click "login"
    Then I will sign in 
    Then I click "eloan"
    When I enter "I-12" in "kw" and click "Search"
    Then I find the content "Error: E-loan numbers begin with a collection code, followed by a capital E and only digits after that. You entered: I-12" in "div#results"
    When I enter "UCE258" in "kw" and click "Search"
    Then I find the content "Determination Details, Previous Determinations, Local Name, Collector, Collection Number, Locality, LatLong, Collection Date, Description, Phase, Last updated at" in "div#results"
    Then I find the content "E-loan No.:, Borrower:, E-loan Date" in "div#recordInfo"