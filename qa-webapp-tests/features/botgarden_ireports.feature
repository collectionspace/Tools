Feature: The Botgarden ireports feature

Scenario: Navigate the ireports feature, select a report, enter a query, and check the report, reset, and back buttons.
    Given I am on the "botgarden" homepage 
    Then I will click the "ireports" feature
    Then I select a report called "Rare Status (Family)"
    When I enter "%RUBIACEAE%" in the Keyword "family" and click "report"
    Then I will see the correct report in pdf format
    Then I will click "reset" and the "family" field should have "%ARAUCARIACEAE%"
    When I click "back"
    Then I will see a list of reports as follows "Accession Count, Dead Report, Deads in Bed, Duplicate Accession Numbers, Label Orders, List of Living Accessions, Rare Status (Family), Rare Status (Genus), Taxon Count, Voucher Family, Voucher Genus, Voucher Label" and files "ucbgAccessionCount.jrxml, ucbgDeadReportRange.jrxml, ucbgDiedInLocation.jrxml, duplicateobjectnumber.jrxml, ucbgLabelOrder.jrxml, ucbgListofLivingAccessions.jrxml, ucbgRareStatusFamily.jrxml, ucbgRareStatusGenus.jrxml, ucbgTaxonCount.jrxml, ucbgVoucherFamily.jrxml, ucbgVoucherGenus.jrxml, ucbgVoucherLabel.jrxml"
    Then I sign out
