Feature: Test the Botgarden Imaginator app by checking queries made with "Search the Metadata" and "Search for Images".

Scenario: Search for the website        
    Given I am on the "botgarden" homepage for ""
    Then I will click the "imaginator" feature
    Then I will enter "augustinii" in the Search the Metadata field
    Then I will select the item "2000.0053" and results displayed include the following "Early Collection Date, Field Place Name, State, Country, Elevation, Habitat, Family, Garden, Rare?, Dead?, Reason for Move, Has Vouchers, Fruiting, Canonical Name Complete"
    When I enter "rosa" in the Search for Images
    Then I see page only listing images