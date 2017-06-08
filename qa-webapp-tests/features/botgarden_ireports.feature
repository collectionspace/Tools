Feature: The Botgarden ireports feature

Scenario: Navigate the ireports feature, select a report, enter a query, and check the report, reset, and back buttons.
    Given I am on the "botgarden" homepage 
    When I click "login"
    Then I will sign in 
    Then I click "ireports"
    Then I select a report called "Rare Status (Family)"
    When I enter "%RUBIACEAE%" in "family" and click "report"
    Then I will see the correct report in pdf format
    Then I will click "reset" and the "family" field should have "%ARAUCARIACEAE%"
    When I click "back"
    Then I find the content "Accession Count, Dead Report, Deads in Bed, Duplicate Accession Numbers, Label Orders, List of Living Accessions, Rare Status (Family), Rare Status (Genus), Taxon Count, Voucher Family, Voucher Genus, Voucher Label" in "div#content"
    Then I find the content "ucbgAccessionCount.jrxml, ucbgDeadReportRange.jrxml, ucbgDiedInLocation.jrxml, duplicateobjectnumber.jrxml, ucbgLabelOrder.jrxml, ucbgListofLivingAccessions.jrxml, ucbgRareStatusFamily.jrxml, ucbgRareStatusGenus.jrxml, ucbgTaxonCount.jrxml, ucbgVoucherFamily.jrxml, ucbgVoucherGenus.jrxml, ucbgVoucherLabel.jrxml" in "div#content"
    When I click "logout"  
    Then I find the content "No Apps" in "div#content"