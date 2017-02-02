import sys
import psycopg2 as ps2
from bs4 import BeautifulSoup

valid_tokens = ["-m", "-i", "-o", "-d"]
museums = ["pahma", "bampfa", "ucjeps", "botgarden", "cinefiles"]


def parse(inp, mark, museum, pwd, port, user, dbname):
    counts_sql = "count.sql"
    out = "%s.out.txt" % museum
    outfile = open(out, "w")
    counts = open(counts_sql, "w")
    infile = open(inp)
    markup = open(mark)
    soup = BeautifulSoup(markup, "html.parser")
    update_sqlstatements = []
    count_sqlstatements = []
    
    lines = [line.rstrip('\n') for line in infile]

    for line in lines:
        (vocab_list, db_table, db_column) = line.split(',')
        
        # Write the count statements into file
        count_statement = "SELECT %s, COUNT(*) FROM %s GROUP BY %s" % (db_column, db_table, db_column)
        # print (count_statement)
        counts.write(count_statement)
        count_sqlstatements.append(count_statement)
        
        vocab_search = "vocab-" + vocab_list
        option_tags = soup.find(id=vocab_search).find_all("option")
        
        # NOTE ERROR HERE IF VOCAB DOES NOT EXIST, BUT CONTINUE
        if option_tags == None or len(option_tags) == 0:
            print ("no option tags for %s" % vocab_list)
            continue

        for each in option_tags:
            vocab_id = each['id']
            field_name = each.contents[0]

            # print(vocab_id, field_name)
            new_value = "urn:cspace:%s.cspace.berkeley.edu:vocabularies:name(%s):item:name(%s)''%s''" % (museum, vocab_list, vocab_id, field_name)
            select_statement = "update %s set %s='%s' where %s='%s';\n" % (db_table, db_column, new_value, db_column, field_name)
            outfile.write(select_statement)
            update_sqlstatements.append(select_statement)

    outfile.close()
    markup.close()
    counts.close()
    
    execute(update_sqlstatements, count_sqlstatements, pwd, port, user, dbname, museum)
    
def do_counts(counts_file, dbcursor, count_sqlstatements):
    total_changes = 0
    for count_statement in count_sqlstatements:
        dbcursor.execute(count_statement)
        results = dbcursor.fetchall()
        counts_file.write(str(results))
        for result in results:
            total_changes += str(result[1])
    counts_file.write(total_changes)
    counts_file.write("\n")
    return total_changes


def execute(update_sqlstatements, count_sqlstatements, dbpassword, dbport, usr, database_name, museum):
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

    counts_file = open("%s.counts.txt" % museum, "w")
    counts_file.write("Counts before: ")
    # First: Do the counts before any changes
    # counts_before_file = open(counts_before, "w")

    total_to_change = do_counts(counts_file, dbcursor, count_sqlstatements)
    
    # Second: Perform the changes
    for update_statement in update_sqlstatements:
        dbcursor.execute(update_statement)
    
    counts_file.write("Counts after: ")
    # Third: Do the counts after all the changes
    total_changed = do_counts(counts_file, dbcursor, count_sqlstatements)

    if total_changed == total_to_change:
    	dbconn.commit()
    	return 1
    else:
        dbconn.rollback()
        return -1


if __name__ == "__main__":
    args = sys.argv
    if (len(args) > 1 and args[1] == "help"):
        print ("To run the file, use the inputs: <museum_name> <input_file> <domain_instance_vocab> <dbconnectionstringinquotes>")
    elif len(args) != 5:
        print ("One or more inputs missing: <museum_name> <input_file> <domain_instance_vocab> <dbconnectionstringinquotes> \nPlease fix or run with 'help' for more info.")
    else:
        museum = args[1]
        if museum not in museums:
            print ("Unknown museum %s" % museum)
        else:
            infile = args[2]
            markup = args[3]
            connect_string = args[4]
            parse(infile, markup, museum, connect_string)




