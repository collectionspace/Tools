#!/usr/bin/env bash
#
# extract-stepdefs.sh
# A utility script for use in CollectionSpace QA automation work.
#
# Extracts a list of needed Cucumber step definitions from an output file
# previously created via:
#
# mvn clean verify -Dcucumber.options="--dry-run --strict" > outputfile.txt

# Print usage instructions and quit if fewer or more than one argument
# is provided
scriptname=`basename "$0"`
if [ "$#" -ne 1 ]; then
    echo "Usage: $scriptname filename"
    exit 1
fi

# Print an error message and quit if the argument isn't a readable file
INPUT_FILE=$1
if [[ ! -r $INPUT_FILE ]]; then
    echo "Could not read file '$1'"
    exit 1
fi

# Match only lines containing step defs (those beginning with '@')
step_defs=$(grep '^@' $1)
  
# Remove keywords like '@And' from the beginning of each line, via 'sed'
# (Remove text from the start of each line, until the first left parens)
step_defs_keyword_removed=$(echo "$step_defs" | sed 's/^[^\(]*?\(.*\)/\1/g')

# Pipe the output from the above command to 'sort'
# to sort lines in ascending order
step_defs_sorted=$(echo "$step_defs_keyword_removed" | sort)

# Pipe the output from the above command to 'uniq'
# to remove duplicate lines (ignoring case)
step_defs_unique=$(echo "$step_defs_sorted" | uniq -u -i)

# Save the output from the above command to a file
# (This file will be overwritten if already present)
STEPDEFS_FILENAME=$1-stepdefs.txt
echo "$step_defs_unique" >| $STEPDEFS_FILENAME

# Report on the number of stepdefs found
# (Use 'awk' to print just the number of lines reported by 'wc',
# and not also the filename or leading whitespace)
lines=$(wc -l $STEPDEFS_FILENAME | awk {'print $1'})
echo "Found $lines stepdef(s) in file '$STEPDEFS_FILENAME' ..."
