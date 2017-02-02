import sys
import psycopg2 as ps2
from bs4 import BeautifulSoup

valid_tokens = ["-m", "-i", "-o", "-d"]
museums = ["pahma", "bampfa", "ucjeps", "botgarden", "cinefiles"]


def parse(inp, mark, museum, pwd, port, user, dbname):
    counts_sql = "count.sql"
    counts_before = "%s.counts.before.txt" % museum
    counts_after = "%s.counts.after.txt" % museum
    counts_results = "%s.counts.results.txt" % museum
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
    
    # perform_counts(counts, counts_before)
    execute(update_sqlstatements, count_sqlstatements, pwd, port, user, dbname)
    # perform_counts(counts, counts_after)
    
# def perform_counts(counts_file, counts_output_name):

#     # uses the counts_file and generates a file "counts_before/after.txt" 
#     pass



def execute(update_sqlstatements, count_sqlstatements, dbpassword, dbport, usr, database_name):
    """
        @param update_sqlstatements  list of statements used to update a record
        @param count_sqlstatements   list of statements used to perform counts
        @param dbpassword            password for the database
        @param dbport                port to connect to
        @param usr                   database password 
        @param database_name         databse name to connect to
        
        counts the items to update, performs updates in the database, and confirms counts before and after are the same
    """
    
    dbconn = ps2.connect(dbname=database_name, user=usr, password=dbpassword, host="localhost", port=dbport)
    dbcursor = dbconn.cursor()
    
    # First: Do the counts before any changes
    counts_before_file = open(counts_before, "w")
    total_to_change = 0 
    for count_statement in count_sqlstatements:
        dbcursor.execute(count_statement)
        results = dbcursor.fetchall()
        counts_before_file.write(results)
        for result in results:
            total_to_change += result[1]  
    counts_before_file.write(total_to_change)            
    counts_before_file.close()
    
    # Second: Perform the changes
    for update_statement in update_sqlstatements:
        dbcursor.execute(update_statement)
    
    
    # Third: Do the counts after all the changes
    counta_after_file = open(counts_after, "w")
    total_changed = 0
    for count_statement in count_sqlstatements:
        dbcursor.execute(count_statement)
        results = dbcursor.fetchall()
        counts_after_file.write(results)
        for result in results:
            total_changed += result[1]
    counts_after_file.write(total_changed)
    counts_after_file.close()
    
    
    # Fourth: Make sure that all the counts match up
    #
    # um... i think commit only works within a "transaction"
    # and you have not started the transaction anywhere...
    # it's a good idea, however! 
    # you'll want to make a "BEGIN" somewhere earlier!
    if total_changed == total_to_change:
    	db.commit()
    	return 1
    return -1


                          
if __name__ == "__main__":
    args = sys.argv
    if (len(args) > 1 and args[1] == "help"):
        print ("To run the file, use the inputs: \n -m <museum_name> \n -i <input_file> \n -d <domain_instance_vocab>")
        sys.exit()
    elif len(args) < 15:
        print ("One or more inputs missing: -m <museum_name> -i <input_file> -d <domain_instance_vocab> -pwd <db password> -prt <port number> -u <user> -db <database name>. \n Fix or run with 'help' for more info.")
        sys.exit(-1)
    else:
        museum = args[args.index("-m") + 1]
        if museum not in museums:
            print ("Unknown museum %s" % museum)
            sys.exit()
        infile = args[args.index("-i") + 1]
        markup = args[args.index("-d") + 1]
        pwd = args[args.index("-pwd") + 1]
        port = args[args.index("-prt") + 1]
        user = args[args.index("-u") + 1]
        dbname = args[args.index("-db") + 1]
        parse(infile, markup, museum, pwd, port, user, dbname)




