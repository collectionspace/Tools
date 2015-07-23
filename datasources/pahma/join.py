import sys, csv

delim = "\t"

inputFile1 = sys.argv[1]
inputFile2 = sys.argv[2]

f1 = csv.reader(open(inputFile1, 'rb'), delimiter=delim, quotechar="\r")
f2 = csv.reader(open(inputFile2, 'rb'), delimiter=delim, quotechar="\r")

file1 = {}
counts = {}
max = 0

counts['file1'] = 0
counts['file2'] = 0
counts['unmatched'] = 0
counts['matched'] = 0

for lineno, ci in enumerate(f1):
    counts['file1'] += 1
    file1[ci[0]] = ci[1:]

for lineno, ci in enumerate(f2):
    #print lineno,"\t",ci
    counts['file2'] += 1
    if ci[0] in file1:
        file1[ci[0]] = file1[ci[0]] + ci[1:]
        max = len(file1[ci[0]])
	counts['matched'] += 1
    else:
	# non matching lines in file to go into the bit bucket
	counts['unmatched'] += 1
        pass
	#file1[ci[0]].append(len(ci[1:]) * "|")

for key,line in file1.items():
    if len(line) == max:
        print "%s%s%s" % (key,delim,delim.join(line))
    else:
        print "%s%s%s%s" % (key,delim,delim.join(line),(max-len(line)) * delim)

counts['max'] = max
for stat,value in sorted(counts.items()):
    print >> sys.stderr, "%s: %s" % (stat,value)
