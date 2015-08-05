Feature: The PAHMA ireports feature

Scenario: Navigate the ireports feature, select a report, enter a query, and check the report, reset, and back buttons.
    Given I am on the "pahma" homepage
    When I click "login" 
    Then I will sign in 
    Then I will click the "ireports" feature
    Then I select a report called "HSR Phase I Inventory"
    When I enter "Kroeber, 20A, AA  1,  9" in the Keyword "Start Location" and click "report"
    Then I will see the correct report in pdf format
    Then I will click "params-reset" and the "Start Location" field should have "Kroeber, 20A, AA  1,  1"
    When I click "back"
    Then I find the content "Component Check, Component Check Subreport, Government Holdings, HSR Phase I Inventory, HSR/Arch. Systematic Inventory, Key Information Review, Systematic Inventory" in "div#content"
	Then I find the content "ComponentCheck.jrxml, ComponentCheckSubReport.jrxml, govholdings.jrxml, HsrPhaseOneInventory.jrxml, SystematicInventoryHSR.jrxml, keyinfobyloc.jrxml, SystematicInventory.jrxml" in "div#content"
    When I click "logout"    
    Then I see "imaginator, search"     