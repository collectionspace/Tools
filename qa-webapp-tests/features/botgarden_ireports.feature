Feature: Find if navigating to the ireports and signing out breaks anything.

Scenario: Search for the website
    Given I am on the "botgarden" homepage for "-dev"
    Then I will click the "ireports" feature
    Then I select a report called "Rare Status (Family)"
    When I enter "%RUBIACEAE%" in the Keyword "family" and click "report"
    Then I will see the correct report in pdf format
    Then I will click "reset" and the "family" field should have "Rare Status (Family)"
    When I click "back"
    Then I will see a list of reports as follows "Accession Count, Dead Report, Deads in Bed, Duplicate Accession Numbers, Label Orders, Label Orders (Word), List of Living Accessions, Rare Status (Family), Rare Status (Genus), Taxon Count, Voucher Family, Voucher Genus, Voucher Label" and files "ucbgAccessionCount.jrxml, ucbgDeadReportRange.jrxml, ucbgDiedInLocation.jrxml, duplicateobjectnumber.jrxml, ucbgLabelOrder.jrxml, ucbgListofLivingAccessions.jrxml, ucbgRareStatusFamily.jrxml, ucbgRareStatusGenus.jrxml, ucbgTaxonCount.jrxml, ucbgVoucherFamily.jrxml, ucbgVoucherGenus.jrxml, ucbgVoucherLabel.jrxml"
    Then sign out
