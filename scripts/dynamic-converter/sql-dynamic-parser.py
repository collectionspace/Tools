import codecs
import sys
import psycopg2 as ps2
from bs4 import BeautifulSoup

valid_tokens = ["-m", "-i", "-o", "-d"]
museums = ["pahma", "bampfa", "ucjeps", "botgarden", "cinefiles"]

URN = 'urn:%'

UTF8Writer = codecs.getwriter('utf8')
sys.stdout = UTF8Writer(sys.stdout)

def parse(inp, mark, museum, connect_string, dry_run):
    counts_sql = "%s.count_statements.sql" % museum # Contains count statements for all the terms we searched for, not just numbers
    out = "%s.out.txt" % museum    
    outfile = UTF8Writer(open(out, "w"))  # Contains the update statements that were executed
    counts = open(counts_sql, "w")
    infile = open(inp)
    markup = open(mark)
    soup = BeautifulSoup(markup, "html.parser")
    update_sqlstatements = []
    count_sqlstatements = []
    verify_all_urns_count = []

    update_statement_params = [] 

    lines = [line.rstrip('\n') for line in infile]

    for line in lines:
        (vocab_list, db_table, db_column) = line.split(',')
        vocab_search = "vocab-" + vocab_list
        option_tags = soup.find(id=vocab_search).find_all("option")
        
        # NOTE: Error here if term list cannot be found, but continue
        if option_tags == None or len(option_tags) == 0:
            print ("ERROR: cannot find terms list for %s. It will be ignored." % vocab_list)
            continue
        
        # NOTE: Check that the the column and table names are valid and nothing sketchy is going on 
        if sanity_check(db_table) == False or sanity_check(db_column) == False:
            print ("ERROR: The table " + db_table + " and column " + db_column + " will be ignored. Sanity check failed.")
            continue 

        # Write the SQL count statements into file
        count_statement = "SELECT %s, COUNT(*) FROM %s WHERE %s is not null GROUP BY %s" % (db_column, db_table, db_column, db_column)
        urn_count_statement = "SELECT COUNT(DISTINCT %s) FROM %s WHERE %s not like '%s'" % (db_column, db_table, db_column, URN)
        counts.write(count_statement + " \n")
        verify_all_urns_count.append(urn_count_statement)
        count_sqlstatements.append(count_statement)

        # Make SQL statements to change each database entry.
        for each in option_tags:
            vocab_id = each['id']
            field_name = each.contents[0]

            if 'from-static-id' in each.attrs:
                search_id = each['from-static-id']
            else:
                search_id = field_name

            new_value = "urn:cspace:%s.cspace.berkeley.edu:vocabularies:name(%s):item:name(%s)'%s'" % (museum, vocab_list, vocab_id, field_name)

            # update_statement is only used to write the future queries into a file
            update_statement_params.append((db_table, db_column, new_value, db_column, search_id))
            update_statement = "update %s set %s='%s' where %s='%s';\n" % (db_table, db_column, new_value, db_column, search_id)
            outfile.write(update_statement)


    outfile.close()
    markup.close()
    counts.close()
    
    execute(verify_all_urns_count, update_statement_params, count_sqlstatements, connect_string, museum, dry_run)

def sanity_check(identifier):
    if (len(identifier.split()) != 1): 
        print ("Warning: table names are not allowed to have spaces. This item will be skipped.")
        return False
    if (not identifier[0].isalpha and identifier[0] != 0):
        return False
    for c in identifier:
        if not c.isalpha() and not c.isdigit() and c != "_":
                return False
    return True

def do_counts(counts_file, dbcursor, count_sqlstatements):
    total_changes = 0
    rouge_terms_lists = []

    for count_statement in count_sqlstatements:
        dbcursor.execute(count_statement)
        results = dbcursor.fetchall()
        split_statement = str(count_statement).split(" ")
        if len(results) > 0:
            for result in results:
                counts_file.write(str(result) + "\n")
                if result[0].find("urn") == -1:
                    # result_tokens = result.split(",")
                    rouge_terms_lists.append([split_statement[1].replace(",",""), split_statement[4], result[0][0:len(result[0])]])
        else:
            # counts_file.write(str(results) + "\n")
            counts_file.write("* " + split_statement[1] + " on table " + split_statement[4] + " generated 0 results. \n")
        for result in results:
            total_changes +=result[1]
    counts_file.write("* Total counted = " + str(total_changes))
    counts_file.write("\n")
    return total_changes, rouge_terms_lists


def execute(urn_sqlcountstatements, update_statement_params, count_sqlstatements, connect_string, museum, dry_run):
    """
        @param update_sqlstatements  list of statements used to update a record
        @param count_sqlstatements   list of statements used to perform counts
        @param dbpassword            password for the database
        @param dbport                port to connect to
        @param usr                   database password 
        @param database_name         databse name to connect to
        
        counts the items to update, performs updates in the database, and confirms counts before and after are the same
    """
    
    dbconn = ps2.connect(connect_string)   
    dbcursor = dbconn.cursor()

    # First: Do the counts before any changes
    pre_convert_counts_file = open("%s.counts.before.txt" % museum, "w") # will contain counts for all things before they're converted
    post_convert_counts_file = open("%s.counts.after.txt" % museum, "w") # will contain counts for all things afte   they're been converted

    pre_convert_counts_file.write("Counts before: \n")
    total_to_change, tmp = do_counts(pre_convert_counts_file, dbcursor, count_sqlstatements)
    
    # Second: Perform the changes
    for i in range(0, len(update_statement_params)):
        params = update_statement_params[i]
        query = "UPDATE {0} SET {1}=(%s) WHERE {1}=(%s);".format(params[0], params[1]) 
        if dry_run:
            print(query % (params[2], params[4]))

        dbcursor.execute(query, (params[2], params[4])) 
            
    
    # Third: Do the counts after all the changes
    post_convert_counts_file.write("Counts after: \n")
    total_changed, rougue_terms_lists = do_counts(post_convert_counts_file, dbcursor, count_sqlstatements)
    
    post_convert_counts_file.close()
    pre_convert_counts_file.close()

    if dry_run: # Generate the report
        rougue_termslist = []
        unconverted_terms = open("%s.unconverted_terms.txt" % museum, "w")
        for col, tbl, term in rougue_terms_lists:
            query = "SELECT id, {0} FROM {1} WHERE {0} like '{2}'".format(col, tbl, term)
            dbcursor.execute(query)
            results = dbcursor.fetchall()
            [unconverted_terms.write(result[0] + " " + result[1] + "\n") for result in results]
        dbconn.rollback()
        return 1

    # Fourth: Verify counts and either rollback or commit 
    if total_changed == total_to_change:
        for statement in urn_sqlcountstatements:
            dbcursor.execute(statement)
            results = dbcursor.fetchall()
            if (results[0][0] != 0):
                print ("Something went wrong... aborting, undoing database changes because some record did not change: %s" % (statement))
                dbconn.rollback()
                return -1
        dbconn.commit()
        return 1

    print ("Looks like there are either more or less records than what we started with. Undoing changes. Check counts log for numbers.")
    dbconn.rollback()
    return -1

if __name__ == "__main__":
    args = sys.argv
    if (len(args) > 1 and args[1] == "help"):
        print ("To run the file, use the inputs: <museum_name> <input_file> <domain_instance_vocab> <dbconnectionstringinquotes>")
    elif len(args) < 5:
        print ("One or more inputs missing: <museum_name> <input_file> <domain_instance_vocab> <dbconnectionstringinquotes> <dry_run> \nPlease fix or run with 'help' for more info.")
    else:
        museum = args[1]
        if museum not in museums:
            print ("Unknown museum %s" % (museum))
            sys.exit(-1)
        else:
            infile = args[2]
            markup = args[3]
            connect_string = args[4]
        if (len(args) > 5):
            dry_run = True
        else:
            dry_run = False
        parse(infile, markup, museum, connect_string, dry_run)
