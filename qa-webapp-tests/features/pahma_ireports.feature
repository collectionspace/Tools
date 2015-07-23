Feature: Navigate the PAHMA ireports feature, select a report, enter a query, and check the report, reset, and back buttons.

Scenario: Search for the website
    Given I am on the "pahma" homepage for "-dev"
    Then I will click the "ireports" feature
    Then I select a report called "HSR Phase I Inventory"
    When I enter "Kroeber, 20A, AA  1,  9" in the Keyword "Start Location" and click "report"
    Then I will see the correct report in pdf format
    Then I will click "params-reset" and the "Start Location" field should have "Kroeber, 20A, AA  1,  1"
    When I click "back"
    Then I will see a list of reports as follows "Component Check, Component Check Subreport, Government Holdings, HSR Phase I Inventory, HSR/Arch. Systematic Inventory, Key Information Review, Systematic Inventory" and files "ComponentCheck.jrxml, ComponentCheckSubReport.jrxml, govholdings.jrxml, HsrPhaseOneInventory.jrxml, SystematicInventoryHSR.jrxml, keyinfobyloc.jrxml, SystematicInventory.jrxml"
    Then sign out
