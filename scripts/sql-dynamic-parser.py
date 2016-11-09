import sys
from bs4 import BeautifulSoup

valid_tokens = ["-m", "-i", "-o", "-d"]
museums = ["pahma", "bampfa", "ucjeps", "botgarden", "cinefiles"]

def parse(out, inp, mark, museum):
	outfile = open(out, "w")
	infile = open(inp)
	markup = open(mark)
	soup = BeautifulSoup(markup, "xml")

	lines = [line.rstrip('\n') for line in infile]

	for line in lines:
		line = line.split(',')
		vocab_list = line[0]
		db_table = line[1]
		db_column = line[2]

		vocab_search = "vocab-" + vocab_list
		option_tags = soup.find(id=vocab_search).find_all("option")

		for each in option_tags:
			vocab_id = each['id']
			field_name = each.contents[0]

			print(vocab_id, field_name)
			new_value = "urn:cspace:%s.cspace.berkeley.edu:vocabularies:name(%s):item:name(%s)''%s''" % (museum, vocab_list, vocab_id, field_name)
			select_statement = "update %s set %s='%s' where %s='%s';\n" % (db_table, db_column, new_value, db_column, field_name)
			outfile.write(select_statement)

	outfile.close()
	markup.close()

						  
if __name__ == "__main__":
	args = sys.argv
	if (len(args) > 1 and args[1] == "help"):
		print ("To run the file, use the inputs: \n -m <museum_name> \n -i <input_file> \n -o <output_file> \n -d <domain_instance_vocab>")
		sys.exit()
	elif len(args) < 9:
		print ("One or more inputs missing: -m <museum_name> -i <input_file> -o <output_file> -d <domain_instance_vocab>. \nFix or run with 'help' for more info.")
		sys.exit()
	else:
		museum = args[args.index("-m") + 1]
		if museum not in museums:
			print ("Unknown museum %s" % museum)
			sys.exit()
		infile = args[args.index("-i") + 1]
		outfile = args[args.index("-o") + 1]
		markup = args[args.index("-d") + 1]

		parse(outfile, infile, markup, museum)


