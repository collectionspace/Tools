package org.collectionspace.qa;

import com.thoughtworks.selenium.*;
import java.util.Arrays;
import java.util.Collection;
import java.util.Date;
import org.junit.*;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;
import static org.junit.Assert.*;
import static org.collectionspace.qa.Utilities.*;

/**
 *
 * @author kasper
 */
@RunWith(value = Parameterized.class)
public class SecondaryTabTests {

    static Selenium selenium;
    public static int PORT_NUM = 4444;
    public static String BROWSER = "firefox";
    private int primaryType, secondaryType;
    

    public SecondaryTabTests(int primaryType, int secondaryType) {
        this.primaryType = primaryType;
        this.secondaryType = secondaryType;
    }

    @Parameters
    public static Collection<Object[]> data() {
        Object[][] data = new Object[][]{
            //its the second entry being tested
            //comment out here to limit tests JJM
            {Record.GROUP, Record.INTAKE},
            {Record.INTAKE, Record.LOAN_IN},
            {Record.LOAN_IN, Record.LOAN_OUT},
            {Record.LOAN_OUT, Record.ACQUISITION},
            {Record.ACQUISITION, Record.MOVEMENT},
            {Record.GROUP, Record.MEDIA},
            {Record.MEDIA, Record.OBJECT_EXIT},
            {Record.OBJECT_EXIT, Record.GROUP},
            {Record.LOAN_IN, Record.CATALOGING}
        };
        return Arrays.asList(data);
    }

    @BeforeClass
    public static void init() throws Exception {
        if (System.getProperty("baseurl") != null) {
            BASE_URL = System.getProperty("baseurl");
        }
        if (System.getProperty("portnum") != null) {
            PORT_NUM = Integer.parseInt(System.getProperty("portnum"));
        }
        if (System.getProperty("browser") != null) {
            BROWSER = System.getProperty("browser");
        }
        selenium = new DefaultSelenium("localhost", PORT_NUM, BROWSER, BASE_URL);
        selenium.start();

        //log in:
        login(selenium);
        
        //autogenerate a movement record so that we have an urn::value to put in the required field
//        String locationAuthorityURN = getLocationURN(selenium);
//        System.out.println("URN: "+locationAuthorityURN);
//        Record.setField(Record.MOVEMENT, Record.getRequiredFieldSelector(Record.MOVEMENT), locationAuthorityURN);
    }

    /**
     * TEST: Test leave page warnings
     *
     * 1) Create new record and save
     * 2) Go to the secondary tab to be tested and create new
     * 2) Edit field and attempt to navigate away
     * 3) Expect dialog and cancel it
     * 4) Navigate away
     * 5) Expect dialog and close it
     * 6) Navigate away
     * 7) Expect dialog and Save Changes
     * 8) Check that the record has been saved properly
     * 9) Open record in secondary tab and edit field
     * 10) Navigate away
     * 11) Expect dialog and click Dont Save
     * 12) check that the changes to record has not been saved
     * @throws Exception
     */
    @Test
    public void tabLeavePageWarning() throws Exception {
        String primaryID = Record.getRecordTypeShort(primaryType) + (new Date().getTime());
        String secondaryID = Record.getRecordTypeShort(secondaryType) + (new Date().getTime());
        //create primary record
        createAndSave(primaryType, primaryID, selenium);
        //got to secondary tab and create new
        createNewRelatedOfCurrent(secondaryType, selenium);
        //make sure required field is filled out
        selenium.type(Record.getRequiredFieldSelector(secondaryType), secondaryID);
        //Test close and cancel buttons of dialog
        navigateWarningClose(secondaryType, secondaryID, selenium);
        //Test 'Save' button - expect it was properly saved
        navigateWarningSave(secondaryType, secondaryID, selenium);
        //go to the record again:
        openRelatedOf(primaryType, primaryID, secondaryType, secondaryID, selenium);
        //selenium.waitForPageToLoad(MAX_WAIT);
        waitForRecordLoad(selenium);
        //Test 'Dont Save' button
        navigateWarningDontSave(secondaryType, secondaryID + "MODIFIED", selenium);
    }

    /**
     * TEST: Test Cancel button functionality
     *
     * 1) Create a new record and save
     * 2) Go to secondary tab and create new record
     * 2) Fill out fields with known values
     * 3) Save
     * 4) Modify all fields
     * 5) Click cancel
     * X) Expect all values are back to their previous value
     *
     * @throws Exception
     */
    @Test
    public void tabTestCancel() throws Exception {
        //create record and fill out all fields
        String primaryID = Record.getRecordTypeShort(primaryType) + (new Date().getTime());
        String secondaryID = Record.getRecordTypeShort(secondaryType) + (new Date().getTime());
        //create primary record
        createAndSave(primaryType, primaryID, selenium);
        //open secondary tab and create new record in that
        createNewRelatedOfCurrent(secondaryType, selenium);
        //fiil out form
        fillForm(secondaryType, secondaryID, selenium);
        saveSecondary(secondaryType, secondaryID, selenium);
        //modify all fields
        clearForm(secondaryType, selenium);
        //click cancel and expect content to change to original;
        selenium.click("css=.csc-relatedRecordsTab-" + Record.getRecordTypeShort(secondaryType) + " :input[value='Cancel changes']");
        waitForRecordLoad(selenium); // verifyFill sometimes giving errors when term lists haven't fully loaded - JJM 2/15/12
        verifyFill(secondaryType, secondaryID, selenium);
    }

    /**
     * TEST: Tests the save functionality:
     * 1) Create and save a new primary record
     * 2) Go to secondary tab and create new record
     * 3) Click save on blank record form
     * X) Expect missing ID error
     * 4) Fill out form with default values
     * 5) Save the record
     * X) Expect that fields still contain the entered values
     *
     * @throws Exception
     */
    @Test
    public void testSecondarySave() throws Exception {
        //create record and fill out all fields
        String primaryID = Record.getRecordTypeShort(primaryType) + (new Date().getTime());
        String secondaryID = Record.getRecordTypeShort(secondaryType) + (new Date().getTime());
        //create primary record
        createAndSave(primaryType, primaryID, selenium);
        //open secondary tab and create new record in that
        createNewRelatedOfCurrent(secondaryType, selenium);
        //attempt saving and expect error message:
        selenium.click("css=.csc-relatedRecordsTab-" + Record.getRecordTypeShort(secondaryType) + " .saveButton");
		if (selenium.isElementPresent("css=.csc-confirmationDialog .saveButton")){
			selenium.click("css=.csc-confirmationDialog .saveButton");
		}
        elementPresent("CSS=.cs-message-error", selenium);
        assertEquals(Record.getRequiredFieldMessage(secondaryType), selenium.getText("CSS=.cs-message-error #message"));

        //fill out form
        fillForm(secondaryType, secondaryID, selenium);
        //save and expect to be successful
        saveSecondary(secondaryType, secondaryID, selenium);
        waitForRecordLoad(selenium); // verifyFill sometimes giving errors when term lists haven't fully loaded - JJM 2/15/12
        //check values:
        verifyFill(secondaryType, secondaryID, selenium);
    }

    /**
     * FIXME FIXME FIXME FIXME FIXME FIXME
     * This is broke due to autogenerator being broke. Recheck once autogenerator is fixed
     * FIXME FIXME FIXME FIXME FIXME FIXME
     * 
     * TEST: Tests save functionality when the fields are empty
     *
     * PRE-REQUISITE: an already saved record is loaded
     *
     * 1) Select the first option for all dropdowns
     * 2) Write the empty string in all fields
     * 3) Save
     * X) Expect no ID warning
     * 4) Fill out ID and save
     * X) Expect successful message
     * X) Expect all fields to be empty except for ID, Expect drop-downs to have index 0 selected
     *
     * @throws Exception
     */
    @Test
    public void testRemovingValues() throws Exception {
        //generate a record of secondary type
        String secondaryID = generateRecord(secondaryType, selenium);
        String primaryID = Record.getRecordTypeShort(primaryType) + (new Date().getTime());

        //goto some collectionspace page with a search box - and open new record
        selenium.open("createnew.html");
        open(secondaryType, secondaryID, selenium);
        //go to the secondary tab of the type primaryType and create new record
        createNewRelatedOfCurrent(primaryType, selenium);
        //fill out ID field + required field and save:
        selenium.type(Record.getIDSelector(primaryType), primaryID);
        //make sure required field is filled out:
        if (!Record.getRequiredFieldSelector(primaryType).equals(Record.getIDSelector(primaryType))) {
            selenium.type(Record.getRequiredFieldSelector(primaryType), "This field is required");
        }
        //save the record in the secondary tab:
        saveSecondary(primaryType, primaryID, selenium);
        //Now that they are related, make sure we have the secondaryType in the secondary tab:
        openRelatedOf(primaryType, primaryID, secondaryType, secondaryID, selenium);
        //clear values from all fields
        clearForm(secondaryType, selenium);
        //save record - and expect error due to missing ID
        selenium.click("css=.csc-relatedRecordsTab-" + Record.getRecordTypeShort(secondaryType) + " .saveButton");
		if (selenium.isElementPresent("css=.csc-confirmationDialog .saveButton")){
			selenium.click("css=.csc-confirmationDialog .saveButton");
		}
        //expect error message due to missing required field\n");
        elementPresent("CSS=.cs-message-error", selenium);
        assertEquals(Record.getRequiredFieldMessage(secondaryType), selenium.getText("CSS=.cs-message-error #message"));
        //Enter ID and make sure required field is filled out
        selenium.type(Record.getIDSelector(secondaryType), secondaryID);
        selenium.type(Record.getRequiredFieldSelector(secondaryType), secondaryID);
        //save record
        saveSecondary(secondaryType, secondaryID, selenium);
        //check values:
        verifyClear(secondaryType, selenium);
    }

    /**
     * TEST: Deleting relation via list
     * 
     * 1) Create a primary record
     * 2) Go to secondary tab and create a secondary record
     * 3) Fill out at least the required field and save the secondary record
     * 4) Make sure that the secondary record is still open
     * 5) Click the delete symbol next to the record
     * X) Expect dialog and click 'Cancel'
     * X) Expect dismissed dialog and no changes
     * 6) Click the delete symbol next to the record
     * X) Expect dialog and click close symbol
     * X) Expect dismissed dialog and no changes
     * 7) Click the delete symbol next to the record
     * X) Expect dialog
     * 8) Click the delete button
     * X) Expect the record to disappear from the relation list
     * X) Expect the recordEditor to be dismissed
     * 9) Search for the record that was previously displayed in the secondary tab
     * X) Expect the record to be found.
     */
    @Test
    public void testSecondaryListDelete() throws Exception {
        //create record and fill out all fields
        String primaryID = Record.getRecordTypeShort(primaryType) + (new Date().getTime());
        String secondaryID = Record.getRecordTypeShort(secondaryType) + (new Date().getTime());
        //create primary record
        createAndSave(primaryType, primaryID, selenium);
        //open secondary tab and create new record in that
        createNewRelatedOfCurrent(secondaryType, selenium);
        //fill out ID field + required field and save:
        selenium.type(Record.getIDSelector(secondaryType), secondaryID);
        //make sure required field is filled out:
        if (!Record.getRequiredFieldSelector(secondaryType).equals(Record.getIDSelector(secondaryType))) {
            selenium.type(Record.getRequiredFieldSelector(secondaryType), "This field is required");
        }
        saveSecondary(secondaryType, secondaryID, selenium);

        //Find the delete symbol in list and click it:
//        String listDeleteSelector = findListDeleteButton(secondaryType, secondaryID, selenium);
        String listDeleteSelector = "css=span:contains(\""+secondaryID+"\") ~ span .csc-recordList-deleteRelation";
        selenium.click(listDeleteSelector);
        assertTrue(selenium.isTextPresent("exact:Delete this relation?"));
        selenium.click("//img[@alt='close dialog']");
        selenium.click(listDeleteSelector);
        assertTrue(selenium.isTextPresent("exact:Delete this relation?"));
        selenium.click("//input[@value='Cancel']");
        selenium.click(listDeleteSelector);
        assertTrue(selenium.isTextPresent("exact:Delete this relation?"));
        selenium.click("css=.cs-confirmationDialog :input[value='Delete']");
        //check that record is no longer related:
        String selector = "css=.csc-relatedRecordsTab-"+Record.getRecordTypeShort(secondaryType) +" .csc-recordList-row span:contains(\""+secondaryID+"\")";
        elementNotPresent(selector, selenium);
        //TODO: Check that recordEditor is dismissed

        //check that the record is not deleted
        elementPresent("css=.cs-searchBox :input[value='Search']", selenium);
        selenium.select("recordTypeSelect-selection", "label=" + Record.getRecordTypePP(secondaryType));
        selenium.type("css=.cs-searchBox :input[name='query']", secondaryID);
        selenium.click("css=.cs-searchBox :input[value='Search']");
        selenium.waitForPageToLoad(MAX_WAIT);
        //expect no results when searching for the record\n");
        textPresent("Found 1 records for " + secondaryID, selenium);
        assertTrue(selenium.isElementPresent("link=" + secondaryID));
    }

    //returns selector for the deleteButton
    private String findListDeleteButton(int secondaryType, String secondaryID, Selenium selenium) throws Exception {
        textPresent(secondaryID, selenium);
        int rowCount = 0;
        System.out.println("textpresent: " + secondaryID);
        String selector = "row::column:-1"; //TODO POINTS TO SIDEBAR! FIND SOMETHING ELSE
        System.out.println("checking whether " + selector + " is present" + selenium.isElementPresent(selector));
        elementPresent(selector, selenium);
        System.out.println("checking whether " + selector + " is present" + selenium.isElementPresent(selector));
        while (selenium.isElementPresent(selector)) {
            System.out.println("found " + selector);
            if (secondaryID.equals(selenium.getText(selector))) {
                System.out.println("matched text: '" + selenium.getText(selector) + "'");
                selenium.click(selector);
                waitForRecordLoad(secondaryType, selenium);
                return "row:" + ((rowCount == 0) ? "" : rowCount) + ":deleteRelation";
            }
            System.out.println("didn't match text: '" + selenium.getText(selector) + "'");
            rowCount++;
            selector = "row:" + rowCount + ":column:-1";
            System.out.println("checking whether " + selector + " is present" + selenium.isElementPresent(selector));
        }
        assertTrue("Error when opening related record - couldn't find " + secondaryID, false);
        return "";
    }

    /**
     * TEST: Deleting relation via list
     *
     * 1) Create a primary record
     * 2) Go to secondary tab and create a secondary record
     * 3) Fill out at least the required field and save the secondary record
     * 4) Make sure that the secondary record is still open
     * 5) Click the Delete Relation button in record editor
     * X) Expect dialog and click 'Cancel'
     * X) Expect dismissed dialog and no changes
     * 6) Click the Delete Relation button in record editor
     * X) Expect dialog and click close symbol
     * X) Expect dismissed dialog and no changes
     * 7) Click the Delete Relation button in record editor
     * X) Expect dialog
     * 8) Click the Delete Relation button in record editor
     * X) Expect the record to disappear from the relation list
     * X) Expect the recordEditor to be dismissed
     * 9) Search for the record that was previously displayed in the secondary tab
     * X) Expect the record to be found.
     */
    @Test
    public void testSecondaryDeleteRelation() throws Exception {
        //create record and fill out all fields
        String primaryID = Record.getRecordTypeShort(primaryType) + (new Date().getTime());
        String secondaryID = Record.getRecordTypeShort(secondaryType) + (new Date().getTime());
        //create primary record
        createAndSave(primaryType, primaryID, selenium);
        //open secondary tab and create new record in that
        createNewRelatedOfCurrent(secondaryType, selenium);
        //fill out ID field + required field and save:
        selenium.type(Record.getIDSelector(secondaryType), secondaryID);
        //make sure required field is filled out:
        if (!Record.getRequiredFieldSelector(secondaryType).equals(Record.getIDSelector(secondaryType))) {
            selenium.type(Record.getRequiredFieldSelector(secondaryType), "This field is required");
        }
        saveSecondary(secondaryType, secondaryID, selenium);

        //Find the delete symbol in list and click it:
        String deleteButtonSelector = "css=.csc-relatedRecordsTab-" + Record.getRecordTypeShort(secondaryType) + " .csc-delete";
        selenium.click(deleteButtonSelector);
        assertTrue(selenium.isTextPresent("exact:Delete this relation?"));
        selenium.click("//img[@alt='close dialog']");
        selenium.click(deleteButtonSelector);
        assertTrue(selenium.isTextPresent("exact:Delete this relation?"));
        selenium.click("//input[@value='Cancel']");
        selenium.click(deleteButtonSelector);
        assertTrue(selenium.isTextPresent("exact:Delete this relation?"));
        selenium.click("css=.cs-confirmationDialog :input[value='Delete']");

        //TODO: Check that recordEditor is dismissed

        //check that the record is not deleted
        elementPresent("css=.cs-searchBox :input[value='Search']", selenium);
        selenium.select("recordTypeSelect-selection", "label=" + Record.getRecordTypePP(secondaryType));
        selenium.type("css=.cs-searchBox :input[name='query']", secondaryID);
        selenium.click("css=.cs-searchBox :input[value='Search']");
        selenium.waitForPageToLoad(MAX_WAIT);
        //expect no results when searching for the record\n");
        textPresent("Found 1 records for " + secondaryID, selenium);
        assertTrue(selenium.isElementPresent("link=" + secondaryID));

    }

    /**
     * TEST: Testings "Go To Record" works
     *
     * 1) Create a primary record
     * 2) Go to secondary tab and create a secondary record
     * 3) Fill out at least the required field and save the secondary record
     * 4) Make sure that the secondary record is still open
     * 5) Click the "GO To Record" link above the form
     * X) Expect the record to be loaded in primary tab
     */
    @Test
     public void testGoToRecordButton() throws Exception {
        //create record and fill out all fields
        String primaryID = Record.getRecordTypeShort(primaryType) + (new Date().getTime());
        String secondaryID = Record.getRecordTypeShort(secondaryType) + (new Date().getTime());
        //create primary record
        createAndSave(primaryType, primaryID, selenium);
        //open secondary tab and create new record in that
        createNewRelatedOfCurrent(secondaryType, selenium);
        //fill out ID field + required field and save:
        selenium.type(Record.getIDSelector(secondaryType), secondaryID);
        //make sure required field is filled out:
        if (!Record.getRequiredFieldSelector(secondaryType).equals(Record.getIDSelector(secondaryType))) {
            selenium.type(Record.getRequiredFieldSelector(secondaryType), "This field is required");
        }
        saveSecondary(secondaryType, secondaryID, selenium);
        selenium.click("css=.csc-relatedRecordsTab-" + Record.getRecordTypeShort(secondaryType) + " .gotoButton");
        textPresent(Record.getRecordTypePP(secondaryType), "css=#title-bar .record-type", selenium);
    }
}
