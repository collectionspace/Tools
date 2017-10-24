import csv, os, sys

with open(sys.argv[1], "rb") as csv_file:
    reader = csv.reader(csv_file, delimiter="\t")
    for row in reader:
        print (row[0])
        os.system(row[0])
