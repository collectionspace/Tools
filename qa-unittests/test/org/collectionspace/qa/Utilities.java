package org.collectionspace.qa;

import java.util.regex.Matcher;
import java.util.regex.Pattern;
import com.thoughtworks.selenium.*;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import static org.junit.Assert.*;

public class Utilities {

    public static String BASE_URL = "http://localhost:8180/collectionspace/ui/core/html/",
            LOGIN_URL = "index.html",
            LOGIN_USER = "admin@core.collectionspace.org",
            LOGIN_PASS = "Administrator",
            MAX_WAIT = "30000";
    public static int MAX_WAIT_SEC = 30;
    public static String LOGIN_REDIRECT = "findedit.html";

    /**
     * Logs in to collectionspace as LOGIN_USER with LOGIN_PASS
     *
     * @param selenium a Selenium object to check with
     * @throws Exception
     */
    public static void login(Selenium selenium) throws Exception {
        System.out.println("Running login function...");
        selenium.open(LOGIN_URL);
        selenium.waitForPageToLoad(MAX_WAIT);
        elementPresent("//input[@value='Sign In']", selenium);
        log("LOGIN: logging in as admin\n");
        selenium.type("name=userid", LOGIN_USER);
        selenium.type("name=password", LOGIN_PASS);
        selenium.click("//input[@value='Sign In']");
        selenium.waitForPageToLoad(MAX_WAIT);
        if (selenium.getLocation().equals(BASE_URL + LOGIN_URL)) {
            log("Not logged in yet, trying again");
            Thread.sleep(10000);
            selenium.type("userid", LOGIN_USER);
            selenium.type("password", LOGIN_PASS);
            selenium.click("//input[@value='Sign In']");
            selenium.waitForPageToLoad(MAX_WAIT);
        }
        assertEquals(BASE_URL + LOGIN_REDIRECT, selenium.getLocation());
        System.out.println("Logged in");
    }

    /**
     * Opens the record with the ID primaryID and of type primaryType. The record is
     * found via the search. After function is done, the record should be loaded.
     *
     * @param primaryType the type of record to open
     * @param primaryID The ID of the record to open
     * @param selenium The selenium object to use
     * @throws Exception
     */
    public static void open(int primaryType, String primaryID, Selenium selenium) throws Exception {
        System.out.println("opening record of type " + Record.getRecordTypePP(primaryType));
        elementPresent("css=.cs-searchBox .csc-searchBox-selectRecordType", selenium);
        //Search for our ID
        selenium.select("css=.cs-searchBox .csc-searchBox-selectRecordType", "label=" + Record.getRecordTypePP(primaryType));
		//search chokes on any query containing a dash. we remove it from the search query.
		String primaryIDAltered = new String(primaryID);
		primaryIDAltered = primaryIDAltered.replace(" - ", " ");
        selenium.type("css=.cs-searchBox .csc-searchBox-query", primaryIDAltered);
        selenium.click("css=.cs-searchBox .csc-searchBox-button");
        System.out.println("clicking search");
        //Expect record and only that to be found in search results (to avoid false thruths :) )
        //removing the following command. JJM 2/15/12
        //selenium.waitForPageToLoad(MAX_WAIT);
        elementPresent("link=" + primaryID, selenium);
        System.out.println("found search result");
        //go to the record again:
        selenium.click("link=" + primaryID);
        waitForRecordLoad(primaryType, selenium);
    }

    /**
     * @param selenium
     * @return
     * @throws Exception 
     */
    public static String getLocationURN(Selenium selenium) throws Exception {
        selenium.setTimeout(""+(Integer.parseInt(MAX_WAIT)*3));
        selenium.open("/collectionspace/tenant/core/" + Record.getRecordTypeShort(Record.MOVEMENT) + "/generator?quantity=1");        
        //wait for record to be generated
        //"created movement with csid of " format
//////////        textPresent("created movement with csid of", selenium, MAX_WAIT_SEC*3);
//////////        selenium.setTimeout(MAX_WAIT);
//////////        //get the entire source:        
//////////        String source = selenium.getBodyText();
//////////        System.out.println("RAWSOURCE: " + source);
//////////        //find csid:
//////////        Pattern linkElementPattern = Pattern.compile("created movement with csid of: (.*)\n");
//////////        Matcher linkElementMatcher = linkElementPattern.matcher(source);
//////////        linkElementMatcher.find();
//////////        String csid = linkElementMatcher.group(1);
//////////        System.out.println("CSID" + csid);
        
        //"{"movement":{"0":"303029fd-2e53-48bd-b28a"}}" format
        textPresent("{\"movement\":{\"0\":\"", selenium, MAX_WAIT_SEC*3);
        selenium.setTimeout(MAX_WAIT);
        //get the entire source:        
        String source = selenium.getBodyText();
        //System.out.println("RAWSOURCE: " + source);
        //find csid:
        Pattern linkElementPattern = Pattern.compile("\\{\"movement\":\\{\"0\":\"(.*)\"\\}\\}");
        Matcher linkElementMatcher = linkElementPattern.matcher(source);
        linkElementMatcher.find();
        String csid = linkElementMatcher.group(1);
        System.out.println("CSID of new movement record: " + csid);
        //open the record by typing the URL directly
        selenium.open(Record.getUrl(Record.MOVEMENT) + "?csid=" + csid);
        waitForRecordLoad(Record.MOVEMENT, selenium);
        //finally get the URN for the location authority
        String urn = selenium.getValue(Record.getRequiredFieldSelector(Record.MOVEMENT));
        return urn;
    }

    /**
     * Generated a record of the given type using Chris' script. The ID of the record is
     * returned
     *
     * @param recordType the type of record to generate
     * @param selenium The Selenium object to use
     * @return the ID of the generated record
     * @throws Exception
     */
    public static String generateRecord(int recordType, Selenium selenium) throws Exception {
        selenium.setTimeout(""+(Integer.parseInt(MAX_WAIT)*3)); //hack to handle slow generator                
        long timestamp = (new Date().getTime());
        log("generating record with: /collectionspace/chain/" + Record.getRecordTypeShortChain(recordType) + "/generator?quantity=1&startvalue=0&extraprefix=" + timestamp + "\n");
        selenium.open("/collectionspace/tenant/core/" + Record.getRecordTypeShort(recordType) + "/generator?quantity=1&startvalue=0&extraprefix=" + timestamp);
        String generatedID = timestamp + "0" + Record.getGeneratedPostfix(recordType);
        textPresent("created " + Record.getRecordTypeShortChain(recordType) + " with csid of:", selenium);
        selenium.setTimeout(MAX_WAIT);
        return generatedID;
    }

    /**
     * Saves record and wait for successful message. Returns once the success
     * message is shown
     *
     * EXPECTS: to be in a record where the required fields are filled out
     *
     * @param selenium a Selenium object to run the actions with
     * @throws Exception
     */
    public static void save(Selenium selenium) throws Exception {
        //save record
        selenium.click("//input[@value='Save']");
		if (selenium.isElementPresent("css=.csc-confirmationDialog .saveButton")){
			selenium.click("css=.csc-confirmationDialog .saveButton");
		}
        waitForRecordSave(selenium);
    }


    /**
     * FIXME: needs proper description
     *
     * saves secondary tab and makes sure the record is still open afterwards
     *
     * REQUIRED: to be in secondary tab with all the required fields filled out
     * 
     * @param secondaryType
     * @param secondaryID
     * @param selenium
     * @throws Exception
     */
    public static void saveSecondary(int secondaryType, String secondaryID, Selenium selenium) throws Exception {
        selenium.click("css=.csc-relatedRecordsTab-" + Record.getRecordTypeShort(secondaryType) + " .saveButton");
		if (selenium.isElementPresent("css=.csc-confirmationDialog .saveButton")){
			selenium.click("css=.csc-confirmationDialog .saveButton");
		}
        //due to bug, expect record to be dismissed
        textNotPresent("Select number pattern", selenium);
        //and to appear on listing of related records
        textPresent(secondaryID, selenium);
        openRelatedOfCurrent(secondaryType, secondaryID, selenium);
    }

    /**
     * Creates a record of recordType with the given id and saves it. The function
     * returns once a successful save message is given. The function will automagically
     * fill out any required fields.
     *
     * @param recordType The Record.recordType to create
     * @param id The desired value of the ID field
     * @param selenium The selenium object which to run this on
     * @throws Exception
     */
    public static void createAndSave(int recordType, String requiredValue, Selenium selenium) throws Exception {
        //create new
        selenium.open(Record.getRecordTypeShort(recordType) + ".html");
        waitForRecordLoad(recordType, selenium);
        assertEquals(Record.getRecordTypePP(recordType), selenium.getText("css=#title-bar .record-type"));
        selenium.type(Record.getIDSelector(recordType), requiredValue);
        //make sure required field is filled out:
        if (!Record.getRequiredFieldSelector(recordType).equals(Record.getIDSelector(recordType))) {
            selenium.type(Record.getRequiredFieldSelector(recordType), "This field is required");
        }
        //and save
        selenium.click("//input[@value='Save']");
		if (selenium.isElementPresent("css=.csc-confirmationDialog .saveButton")){
			selenium.click("css=.csc-confirmationDialog .saveButton");
		}
        waitForRecordSave(selenium);
    }

    /**
     * Opens the record with type primaryType, then navigates to the secondary
     * given by secondaryType and creates a new record of that type. The record
     * is NOT saved
     *
     * @param primaryType
     * @param primaryID
     * @param secondaryType
     */
    public static void createNewRelatedOf(int primaryType, String primaryID, int secondaryType, Selenium selenium) throws Exception {
        open(primaryType, primaryID, selenium);
        //go to secondary tab:
        createNewRelatedOfCurrent(secondaryType, selenium);
    }

    /**
     * Goes to the secondary tab of the type secondaryType and creates a new record.
     * The new record is NOT saved.
     *
     * REQUIRED: Should be in a saved records primary tab
     *
     * @param secondaryType The type of record to create in secondary tab
     * @param selenium The selenium object
     * @throws Exception
     */
    public static void createNewRelatedOfCurrent(int secondaryType, Selenium selenium) throws Exception {
        String dialogSelector = ".cs-search-dialogFor-" + Record.getRecordTypeShort(secondaryType);
        //waitForRecordLoad(secondaryType, selenium); // JJM 2/15/12
        //go to secondary tab:
        selenium.click("link=" + Record.getRecordTypeTabName(secondaryType));
        elementPresent("//input[@value='Add record']", selenium);
        selenium.click("//input[@value='Add record']");
        elementPresent("css=" + dialogSelector + " :input[value='Create']", selenium);
        selenium.click("css=" + dialogSelector + " :input[value='Create']");
        waitForRecordLoad(secondaryType, selenium);
    }

    /**
     * REQUIRED: Should be in the secondary tab with the desired record displayed in listing
     * 
     * @param secondaryType
     * @param secondaryID
     * @param selenium
     * @throws Exception
     */
    public static void openRelatedOfCurrent(int secondaryType, String secondaryID, Selenium selenium) throws Exception {
		System.out.println("seeking textpresent: " + secondaryID);
        textPresent(secondaryID, selenium);
        String selector = "css=.csc-relatedRecordsTab-"+Record.getRecordTypeShort(secondaryType) +" .csc-recordList-row span:contains(\""+secondaryID+"\")";
        System.out.println("checking whether " + selector + " is present: " + selenium.isElementPresent(selector));
        elementPresent(selector, selenium);
        selenium.click(selector);
        waitForRecordLoad(secondaryType, selenium);
    }

    public static void openRelatedOf(int primaryType, String primaryID, int secondaryType, String secondaryID, Selenium selenium) throws Exception {
        open(primaryType, primaryID, selenium);
        //go to secondary tab:
        selenium.click("link=" + Record.getRecordTypeTabName(secondaryType));
        openRelatedOfCurrent(secondaryType, secondaryID, selenium);
    }

    /**
     * Used for testing the close buttons (close/cancel) in the dialog that appears
     * when navigating away from an edited page. This function:
     * 1) Edit field
     * 2) Click 'find and edit' tab
     * X) Expect warning and click cancel
     * 3) Click 'acquisition' tab
     * X) Expect warning and click close
     *
     * PRE-REQUISITES: a record with the required fields filled out
     *
     * @param primaryType The record type we're testing on
     * @param modifiedID The value to change the ID of the record to
     * @param selenium The selenium object on which to run these actions
     * @throws Exception
     */
    public static void navigateWarningClose(int primaryType, String modifiedID, Selenium selenium) throws Exception {
    	System.out.println("navigateWarningClose: primary= " + Record.getRecordTypePP(primaryType) + " modifiedID= " + modifiedID);
        waitForRecordLoad(primaryType, selenium);
        //edit a field (ID field)
        selenium.type(Record.getIDSelector(primaryType), modifiedID);
        //navigate away
        selenium.click("link=Find and Edit");
        elementPresent("ui-dialog-title-1", selenium);
        //expect warning and click cancel
        assertTrue(selenium.isTextPresent("exact:Save Changes?"));
        selenium.click("//input[@value='Cancel']");
        //navigate away, expect warning dialog, close with top right close symbol
        selenium.click("link=Create New");
        elementPresent("ui-dialog-title-1", selenium);
        assertTrue(selenium.isTextPresent("exact:Save Changes?"));
        selenium.click("//img[@alt='close dialog']");
    }

    /**
     * Used for testing the save button in the dialog that appears when navigating
     * away from an edited page. This function:
     * 1) Enter the modifiedID value into the ID field
     * 2) Navigate away from page using the search - the thing we search for is the modifiedID
     * X) Expect the warning dialog
     * 3) Hit Save
     * X) Expect exactly one result from search - that is the saved record with modified ID
     *
     * PRE-REQUISITES: a record with the required fields filled out
     *
     * @param primaryType The record type we're testing on
     * @param modifiedID The value to change the ID of the record to
     * @param selenium The selenium object on which to run these actions
     * @throws Exception
     */
    public static void navigateWarningSave(int primaryType, String modifiedID, Selenium selenium) throws Exception {
        waitForRecordLoad(primaryType, selenium);
        //edit field (ID field)
        selenium.type(Record.getIDSelector(primaryType), modifiedID);
        //Search for our ID (should cause warning too)
        selenium.select("recordTypeSelect-selection", "label=" + Record.getRecordTypePP(primaryType));
        selenium.type("query", modifiedID);
        selenium.click("//input[@value='Search']");
        //expect warning for leaving page
        elementPresent("ui-dialog-title-1", selenium);
        assertTrue(selenium.isTextPresent("exact:Save Changes?"));
        selenium.click("css=.csc-confirmationDialogButton-act");        //click save
		if (selenium.isElementPresent("css=.csc-confirmationDialog .saveButton")){
			selenium.click("css=.csc-confirmationDialog .saveButton");
		}
        //Expect record and only that to be found in search results (to avoid false thruths :) )
        selenium.waitForPageToLoad(MAX_WAIT);
        elementPresent("link=" + modifiedID, selenium);
        assertEquals("Found 1 records for " + modifiedID, selenium.getText("css=.csc-search-results-count"));
    }

    /**
     * Used for testing the 'dont save' button in the dialog that appears when navigating
     * away from an edited page. This function:
     * 1) Enter the modifiedID value into the ID field
     * 2) Navigate away from page using create new
     * X) Expect the warning dialog
     * 3) Hit Dont Save
     * X) Do a search for modifiedID and expect 0 results
     *
     * PRE-REQUISITES: a record with the required fields filled out
     *
     * @param primaryType The record type we're testing on
     * @param modifiedID The value to change the ID of the record to
     * @param selenium The selenium object on which to run these actions
     * @throws Exception
     */
    public static void navigateWarningDontSave(int primaryType, String modifiedID, Selenium selenium) throws Exception {
        waitForRecordLoad(primaryType, selenium);
        //edit ID field
        selenium.type(Record.getIDSelector(primaryType), modifiedID);
        //navigate away, wait for dialog and click dont save:
        selenium.click("link=Create New");
        elementPresent("ui-dialog-title-1", selenium);
        assertTrue(selenium.isTextPresent("exact:Save Changes?"));
        elementPresent("css=.csc-confirmationDialogButton-proceed", selenium);
        selenium.click("css=.csc-confirmationDialogButton-proceed");
        //wait for page to load
        selenium.waitForPageToLoad(MAX_WAIT);
        textPresent(Record.getRecordTypePP(primaryType), selenium);
        //search for the changed ID (which should not be present, since we didn't save
        selenium.select("recordTypeSelect-selection", "label=" + Record.getRecordTypePP(primaryType));
        selenium.type("query", modifiedID);
        selenium.click("//input[@value='Search']");
        //wait for page to load.. Record should not be be found:
        textPresent("Viewing page 1", selenium);
        assertFalse(selenium.isElementPresent("link=" + modifiedID));
    }

    /**
     * Fills out the fields of the given record type with the given recordID string as ID
     * and the default values of that record type.
     *
     * EXPECTS: that the record is loaded
     *
     * @param recordType The record type to fill out
     * @param recordID The value to put in the ID field
     * @param selenium The selenium object used to fill out the form
     */
    public static void fillForm(int recordType, String recordID, Selenium selenium) {
        fillForm(recordType, recordID, Record.getFieldMap(recordType), Record.getSelectMap(recordType), Record.getDateMap(recordType), selenium);
    }

    /**
     * Fills out the fields of the given record type with the given recordID string as ID
     * and the default values given as parameters
     *
     * EXPECTS: that the record is loaded
     *
     * @param recordType The record type to fill out
     * @param recordID The value to put in the ID field
     * @param fieldMap Map of selectors/values to put in regular text fields and text areas
     * @param selectMap Map of selectors/values to use in select boxes
     * @param dateMap Map of selectors/dates to use in the date fields.
     * @param selenium The selenium object used to fill out the form
     */
    public static void fillForm(int recordType, String recordID, HashMap<String, String> fieldMap, HashMap<String, String> selectMap, HashMap<String, String> dateMap, Selenium selenium) {
        selenium.type(Record.getIDSelector(recordType), recordID);

        //fill out all fields:
        Iterator<String> iterator = fieldMap.keySet().iterator();
        while (iterator.hasNext()) {
            String selector = iterator.next();
            //System.out.println("changing " + selector + " to " + fieldMap.get(selector) + " modified");
            selenium.type(selector, fieldMap.get(selector));
        }
        //fill out all dates:
        iterator = dateMap.keySet().iterator();
        while (iterator.hasNext()) {
            String selector = iterator.next();
            selenium.type(selector, dateMap.get(selector));
        }
        //select from all select boxes
        iterator = selectMap.keySet().iterator();
        while (iterator.hasNext()) {
            String selector = iterator.next();
            try {
                //make sure options for select box are loaded (and not Options Not Loaded)
                //and yes, this is indeed a very nasty xpath selector, but:
                //The option= predicate was required to make ensure that the options were loaded                
                //The contains predicate was required, since the options-loaded checker didn't work if several dropdowns contained the value checked for
                //       the entire normalize, etc. was required due to multiple classes..
                //we need class selector without "." in the beginning, so remove if present
                String classNameOnly = selector.startsWith("css=.")?selector.substring(5):selector;
                elementPresent("//select[contains(@class, '"+classNameOnly+"') and option='"+selectMap.get(selector)+"']", selenium);
//                elementPresent("//select[option='"+selectMap.get(selector)+"']", selenium);
            } catch (Exception e) {
                System.out.println("ERROR -- ELEMENT NOT PRESENT");
            }
            selenium.select(selector, "label=" + selectMap.get(selector));
        }
    }

    /**
     * Clears values from all the fields of the form. Does NOT save afterwards
     *
     * EXPECTS: that the record is loaded
     *
     * @param recordType The record type to clear
     */
    public static void clearForm(int recordType, Selenium selenium) {
        //clear ID field
        selenium.type(Record.getIDSelector(recordType), "");

        //clear all regular fields
        HashMap<String, String> fieldMap = Record.getFieldMap(recordType);
        Iterator<String> iterator = fieldMap.keySet().iterator();
        while (iterator.hasNext()) {
            String selector = iterator.next();
            selenium.type(selector, "");
        }
        // clear all date fields
        HashMap<String, String> dateMap = Record.getDateMap(recordType);
        iterator = dateMap.keySet().iterator();
        while (iterator.hasNext()) {
            String selector = iterator.next();
            selenium.type(selector, "");
        }
        // clear all vocab fields
        HashMap<String, String> vocabMap = Record.getVocabMap(recordType);
        iterator = vocabMap.keySet().iterator();
        while (iterator.hasNext()) {
            String selector = iterator.next();
            selenium.type(selector, "");
        }
        HashMap<String, String> selectMap = Record.getSelectMap(recordType);
        //select from all select boxes
        iterator = selectMap.keySet().iterator();
        while (iterator.hasNext()) {
            String selector = iterator.next();
            selenium.select(selector, "index=0");
        }
    }

    /**
     * Checks all the fields are cleared, except for the ID field and required field.
     * That is, it check all values of fieldMap, dateMap, vocabMap and selectMap
     * For select boxes, it is expected that index=0 is selected
     *
     * EXPECTS: that the record is loaded
     *
     * @param recordType The record type to fill out
     */
    public static void verifyClear(int recordType, Selenium selenium) {
        //check values of regular fields:
        HashMap<String, String> fieldMap = Record.getFieldMap(recordType);
        Iterator<String> iterator = fieldMap.keySet().iterator();
        while (iterator.hasNext()) {
            String selector = iterator.next();
            //dont expect required field to be empty:
            if (!selector.equals(Record.getRequiredFieldSelector(recordType))) {
//                System.out.println("CHECKING FIELD: "+selector);
                assertEquals("checking for field: " + selector, "", selenium.getValue(selector));
            }
        }
        //check values of date fields:
        HashMap<String, String> dateMap = Record.getDateMap(recordType);
        iterator = dateMap.keySet().iterator();
        while (iterator.hasNext()) {
            String selector = iterator.next();
            assertEquals("checking date field: "+selector, "", selenium.getValue(selector));
        }
        HashMap<String, String> vocabMap = Record.getVocabMap(recordType);
        iterator = vocabMap.keySet().iterator();
        while (iterator.hasNext()) {
            String selector = iterator.next();
            assertEquals("checking vocab field: "+selector, "", selenium.getValue(selector));
        }
        HashMap<String, String> selectMap = Record.getSelectMap(recordType);
        iterator = selectMap.keySet().iterator();
        while (iterator.hasNext()) {
            String selector = iterator.next();
            assertEquals("checking select field: "+selector, 0, Integer.parseInt(selenium.getSelectedIndex(selector)));
        }
    }

    /**
     * Checks all the fields of the loaded record against the default values of the
     * given recordType. Also checks that the ID of the record equals the value of
     * recordID.
     *
     * EXPECTS: that the record is loaded
     *
     * @param recordType The record type to verify
     * @param recordID The value expected in the ID field
     * @param selenium The selenium object used to fill out the form
     */
    public static void verifyFill(int recordType, String recordID, Selenium selenium) {
        verifyFill(recordType, recordID, Record.getFieldMap(recordType), Record.getSelectMap(recordType), Record.getDateMap(recordType), selenium);
    }

    /**
     * Checks all the fields of the loaded record against the values given as parameters.
     *
     * EXPECTS: that the record is loaded
     *
     * @param recordType The record type to fill out
     * @param recordID The value to put in the ID field
     * @param fieldMap Map of selectors/values to put in regular text fields and text areas
     * @param selectMap Map of selectors/values to use in select boxes
     * @param dateMap Map of selectors/dates to use in the date fields.
     * @param selenium The selenium object used to fill out the form
     */
    public static void verifyFill(int recordType, String recordID, HashMap<String, String> fieldMap, HashMap<String, String> selectMap, HashMap<String, String> dateMap, Selenium selenium) {
        assertEquals(recordID, selenium.getValue(Record.getIDSelector(recordType)));
        //check values:
        Iterator<String> iterator = fieldMap.keySet().iterator();
        while (iterator.hasNext()) {
            String selector = iterator.next();
            assertEquals("checking for field: " + selector, fieldMap.get(selector), selenium.getValue(selector));
        }
        iterator = dateMap.keySet().iterator();
        while (iterator.hasNext()) {
            String selector = iterator.next();
			//take substring of returned date value. 
			//cspace returns date value format with universal time and this causes errors
			String selectorDateTrim = selenium.getValue(selector);
			// we only want first 11 chars, e.g. <2011-04-11>
			selectorDateTrim = selectorDateTrim.substring(0,10);
            assertEquals(dateMap.get(selector), selectorDateTrim);
        }
        iterator = selectMap.keySet().iterator();
        while (iterator.hasNext()) {
            String selector = iterator.next();
            try {
                //make sure options for select box are loaded (and not Options Not Loaded)
                //and yes, this is indeed a very nasty xpath selector, but:
                //The option= predicate was required to make ensure that the options were loaded                
                //The contains predicate was required, since the options-loaded checker didn't work if several dropdowns contained the value checked for
                //       the entire normalize, etc. was required due to multiple classes..
                //we need class selector without "." in the beginning, so remove if present
                String classNameOnly = selector.startsWith("css=.")?selector.substring(5):selector;
                elementPresent("//select[contains(@class, '"+classNameOnly+"') and option='"+selectMap.get(selector)+"']", selenium);
                //make sure options for select box are loaded
//                elementPresent("//select[option='"+selectMap.get(selector)+"']", selenium);
            } catch (Exception e) {
                System.out.println("ERROR -- ELEMENT NOT PRESENT");
            }
            assertEquals(selectMap.get(selector), selenium.getSelectedLabel(selector));
        }
    }

    public static void waitForRecordLoad(Selenium selenium) throws Exception {
        elementPresent("//input[@value='Select number pattern']", selenium);
        
//        elementNotPresent("//select[option='Options not loaded']", selenium);
    }

    public static void waitForRecordSave(Selenium selenium) throws Exception {
        textPresent("successfully", selenium);
//        elementNotPresent("//select[option='Options not loaded']", selenium);
    }
    
    /**
     * wait for record to load.. This is indicated by number picker being present, or in 
     * case of group, by the selector having got it's option values
     * 
     * @param recordType record type expected to load
     * @param selenium a Selenium object to check with
     * @throws Exception
     */
    public static void waitForRecordLoad(int recordType, Selenium selenium) throws Exception {
        if (recordType == Record.GROUP) { //group doesn't have number picker
            elementPresent("//select[option='Decorative Arts']", selenium);
        } else {
            elementPresent("//input[@value='Select number pattern']", selenium);
        }
        elementPresent(Record.getIDSelector(recordType), selenium);
    }

    /**
     * Asserts that the text given as parameter is not present after MAX_WAIT_SEC
     *
     * @param text the text to check for whether is present
     * @param selenium a Selenium object to check with
     * @throws Exception
     */
    static final void textNotPresent(String text, Selenium selenium) throws Exception {
        for (int second = 0;; second++) {
            if (second >= MAX_WAIT_SEC) {
                fail("textNotPresent: The text "+text+" stayed present - timeout");
            }
            try {
                if (!selenium.isTextPresent(text)) {
                    break;
                }
            } catch (Exception e) {
            }
            Thread.sleep(1000);
        }
    }

    /**
     * Asserts that the text becomes present within MAX_WAIT_SEC
     *
     * @param text the text to check whether is present
     * @param selenium  a Selenium object to check with
     * @throws Exception
     */
    static final void textPresent(String text, Selenium selenium, int timeout) throws Exception {
        for (int second = 0;; second++) {
            if (second >= timeout) {
                fail("textPresent: Unable to find text: "+text);
            }
            try {
                if (selenium.isTextPresent(text)) {
                    break;
                }
            } catch (Exception e) {
            }
            Thread.sleep(1000);
        }
    }
    
        /**
     * Asserts that the text becomes present within MAX_WAIT_SEC
     *
     * @param text the text to check whether is present
     * @param selenium  a Selenium object to check with
     * @throws Exception
     */
    static final void textPresent(String text, Selenium selenium) throws Exception {
        textPresent(text, selenium, MAX_WAIT_SEC);
    }

    /**
     * Asserts that the field defined by selector parameter will contain text within
     * MAX_WAIT_SEC seconds
     *
     * @param text the text to check whether is present
     * @param selector to the field that we want to check for the text in
     * @param selenium  a Selenium object to check with
     * @throws Exception
     */
    static final void textPresent(String text, String selector, Selenium selenium) throws Exception {
        for (int second = 0;; second++) {
            if (second >= MAX_WAIT_SEC) {
                fail("textPresent: Unable to find text "+text+" in field: "+selector);
            }
            try {
                if (text.equals(selenium.getText(selector))) {
                    break;
                }
            } catch (Exception e) {
            }
            Thread.sleep(1000);
        }
    }

    /**
     * Asserts that the element is NOT present within MAX_WAIT_SEC
     *
     * @param selector The selector for the element to check
     * @param selenium a Selenium object to check with
     * @throws Exception
     */
    static final void elementNotPresent(String selector, Selenium selenium) throws Exception {
        for (int second = 0;; second++) {
            if (second >= MAX_WAIT_SEC) {
                fail("elementNotPresent: Element: "+selector+" stayed on page");
            }
            try {
                if (!selenium.isElementPresent(selector)) {
                    break;
                }
            } catch (Exception e) {
            }
            Thread.sleep(1000);
        }
    }

    /**
     * Asserts that the element is present within MAX_WAIT_SEC
     *
     * @param selector The selector for the element to check
     * @param selenium a Selenium object to check with
     * @throws Exception
     */
    static final void elementPresent(String selector, Selenium selenium) throws Exception {
        for (int second = 0;; second++) {
            if (second >= MAX_WAIT_SEC) {
                fail("elementPresent: Unable to find element "+selector);
            }
            try {
                if (selenium.isElementPresent(selector)) {
                    break;
                }
            } catch (Exception e) {
                
            }
            Thread.sleep(1000);
        }
    }

    public static void log(String str) {
        System.out.print(str);
    }
}
