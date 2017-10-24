# Static to Dynamic List Converter
This directory contains the script and resources for changing a static list in the CollectionSpace database to dynamic. There are preliminary steps before running the script.

### Step 1a: Convert Terms List in the XML
First, the terms list must be transferred from their respective files to the file that will hold all of the dynamic term lists.
This section will show samples of how the XML files should look:
1. Before: term list in original XML file
2. After: XML file after deleting hardcoded options
3. Added term list to dynamic XML file

##### Before: term list in original XML file
```
## application/tomcat-main/src/main/resources/tenants/MUSEUM/MUSEUM-page.xml
<repeat id="staticTermList">
	<field id="staticTermList">
		<options>
			<option id="North">north</option>
			<option id="south">south</option>
			<option id="west">west</option>
			<option id="east">east</option>
		</options>
	</field>
</repeat>
```

##### After: XML file after deleting hardcoded options
```
## application/tomcat-main/src/main/resources/tenants/MUSEUM/MUSEUM-page.xml
<repeat id="staticTermList">
	<field id="staticTermList" autocomplete="vocab-dynamicTermList" ui-type="enum">
		<!-- Converted to dynamic -->
	</field>
</repeat>
```
Changes:
1. Deleted options tag and everything inside (will transfer to dynamic XML file).
2. Added autocomplete and ui-type field. Autocomplete field should correspond to what you name your termslist in the dynamic XML file.
3. NOTE: Keep other attributes in the field tag if they exist.

##### Added term list to dynamic XML file
```
## application/tomcat-main/src/main/resources/tenants/MUSEUM/domain-instance-vocabularies.xml
<instance id="vocab-dynamicTermList">
	<web-url>dynamicTermList</web-url>
	<title-ref>dynamicTermList</title-ref>
	<title>dynamicTermList</title>
	<options>
		<option id="position01">north</option>
		<option id="position02">south</option>
		<option id="position03">west</option>
		<option id="position04">east</option>
	</options>
</instance>
```
Notes:
1. Fill in the same name of termlist, that you created and inserted into ```autocomplete=""``` in the original XML file, into the: instance id, web-url, title-ref, and title. Append ```vocab-``` to the beginning of this term in the instance id.
2. Move options tag here.
3. Note that the id's are different; the id's need to be unique and somewhat identifiable. The only valid characters are: letters, numbers, and underscores. 
4. Check to see if an instance with all of the same options already exist. If one does, you won't need to make a new instance, and can link your term list to the existing one.

### Step 1b: Add tags to terms that are different in the database.
Some terms differ in how they appear in the database and in the dropdown. Unique attributes need to be added so that they are able to found in the database. This change occurs in the dynamic XML file.

##### Example: in original XML file before modifying
```
## application/tomcat-main/src/main/resources/tenants/MUSEUM/MUSEUM-page.xml

<option id="North">north</option>
```
Even a change as simple as capitalization will require a unique attribute.

##### Example: in dyanmic XML file after modifying
```
## application/tomcat-main/src/main/resources/tenants/MUSEUM/MUSEUM-page.xml

<option id="position01" from-static-id="North">north</option>
```
Now, we will be able to find and convert it in our database.

### Step 2: Create input file
The input file consists of three parts, each separated by a comma (no spaces in-between). There can be multiple entries. For now, the process of figuring out the table and column names has been manual.
1. The vocabulary name, as noted in ```autocomplete=""``` and the first four tags in the dynamic XML.
2. The table to which the termlist is saved.
3. The column to which the termlist is saved.

```
#example input file
dynamicTermList,table_name,column_name
dynamicTermList2,table_name2,column_name2
dynamicTermList3,table_name3,column_name3
...
```

### Step 3: Running the Script
To run the script, ```sql-dynamic-parser.py```, make sure that in your environment you have:
1. psycopg2: ```sudo apt-get install python-psycopg2```
2. bs4: ```sudo apt-get install python-bs4```

Next, we can run the script. Here is the format:
```
python <MUSEUM> <INFILE PATH> <DYNAMIC XML PATH> <CONNECT STRING> <DRY RUN (Optional)>
```
- **Museum:** Written as its shortname. Currently, we have: bampfa, botgarden, cinefiles, pahma, ucjeps.
- **Infile Path:** The input file that links the vocabular list in the dymanic XML to the database table and column.
- **Dynamic XML Path:** either download the XML file directly to this folder, or access it from a cloned repo. Make sure it is updated!
- **Connect String:** pass it in with single quotes wrapping it. Here is the format:
```‘host=redacted port=redacted dbname=redacted user=redacted sslmode=prefer password=redacted'``` 
- **Dry run:** A dry run will prevent the script from making changes in the database; however, it will still perform count statements and instead, the commands it would have run will be printed to the terminal. **If you want to perform a dry run,** add anything as a last argument. **Otherwise, only pass in four arguments.**

### Step 4a: Deciphering Output
##### SQL count statements file: ```counts.sql```
For each line in the input file with valid term lists, it will write the count statement:
```
SELECT column_name, COUNT(*) FROM table_name GROUP BY column_name;
```

##### Output file: ```MUSEUM.out.txt```
For each term entry for each valid term lists, it will write the statement that converts old database entries to the new format:
```
update table_name set column_name='new_column_entry' where column_name='old_column_entry;
```

##### Output file: ```MUSEUM.counts.txt```
Holds the output of count statements before and after the database changes.

### Step 4b: Deciphering Errors
###### Example error 1: ```ERROR: cannot find terms list for dynamicTermList. It will be ignored.```
This means that either ```dynamicTermList``` is not in the XML file, or that there was a typo when writing the tag: ``` <instance id="vocab-dynamicTermList"> ```. If this occurs, then database changes are not made to the table-column pair associated with this.

###### Example error 2: ```Something went wrong... aborting, undoing database changes because some record did not change: <sql statement>```
This occurs when a record does not change. The script will not commit until this conflict is resolved.

###### Example error 3: ```Looks like there are either more or less records than what we started with. Undoing changes. Check counts log for numbers.```
This occurs when a record is not switched properly. The script will not commit until this conflict is resolved.

### More Resources
1. For real life examples of how the lists were edited, steps 1a and 1b, look at merge requests [34](https://github.com/cspace-deployment/application/commit/2730e532c655abb8451272e8bb9114e7fcb6300f) (step 1a) and [35](https://github.com/cspace-deployment/application/commit/99231357d37eec222c3a1741b5c60533eff39c7b) (step 1b) in ```cspace-deployment/applications```.
2. Those merges are linked to [PAHMA-1519](https://issues.collectionspace.org/browse/PAHMA-1519). Database testing for these SQL statements are documented in [PAHMA-1520](https://issues.collectionspace.org/browse/PAHMA-1520).
