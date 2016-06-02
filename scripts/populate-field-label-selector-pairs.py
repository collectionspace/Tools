#!/usr/bin/env python

from argparse import ArgumentParser
import collections
import json
import re
import os
import sys

# TODO: Replace commented-out debugging statements
# with debug or trace level log statements.

# TODO: Handle term lists for authority term records.
# These will have messagekeys similar to 'preferred...-term...'

# TODO: Handle cases like CollectionObject (Cataloging)
# where there may be multiple, discrepant record type names.
# (E.g. csc-object v. csc-collection-object, as well as
# some items that have neither prefix.)

# TODO: Handle structured dates. These will be present within
# lists containing key 'func', value 'cspace.structuredDate',
# and have the form '${fields.groupname.fieldname}', while
# their associated text labels in the message bundle file
# will have the form 'structuredDate-fieldname'.

# Remove a substring from the right of a string.
# From Jack Kelly
# http://stackoverflow.com/a/3663505
def rchop(thestring, ending):
  if thestring.endswith(ending):
    return thestring[:-len(ending)]
  return thestring

# Extract the name of a field from an entry for a field or row (the
# latter for repeatable fields) in a CollectionSpace 'uispec' file.
FIELD_PATTERN = re.compile("^\$\{fields\.(\w+)\}$", re.IGNORECASE)
ROW_PATTERN = re.compile("^\$\{\{row\}\.(\w+)\}$", re.IGNORECASE)
def get_field_name(value):
    # 'basestring' -> 'str' here in Python 3
    if isinstance(value, basestring):
        match = FIELD_PATTERN.match(value)
        if match is not None:
            return str(match.group(1))
        match = ROW_PATTERN.match(value)
        if match is not None:
            return str(match.group(1))
            
MESSAGEKEY_KEY = 'messagekey'
def get_messagekey_from_item(item):
    if isinstance(item, dict):
        try:
            messagekey = item[MESSAGEKEY_KEY]
            return messagekey
        except KeyError, e:
            return None
    else:
        return None

# Recursively walk a nested collection and return
# lists representing each of its parts
# From Bryukhanov Valentin
# http://stackoverflow.com/a/12507546
def get_messagekeys_generator(indict, key=MESSAGEKEY_KEY):
    if isinstance(indict, dict):
        for key, value in indict.items():
            if isinstance(value, dict):
                for d in get_messagekeys_generator(value, [key]):
                    yield d
            elif isinstance(value, list) or isinstance(value, tuple):
                for v in value:
                    for d in get_messagekeys_generator(v, [key]):
                        yield d
            else:
                yield [key, value]
    else:
        yield indict

# Get the selector prefix for the current record type (e.g. "acquisition-").
RECORD_TYPE_PREFIX = None
SELECTOR_PATTERN = re.compile("^\.csc-(\w+\-)?.*$", re.IGNORECASE)
def get_record_type_selector_prefix(selector):
    global RECORD_TYPE_PREFIX
    if RECORD_TYPE_PREFIX is not None:
        return RECORD_TYPE_PREFIX
    else:
        match = SELECTOR_PATTERN.match(selector)
        if match is not None:
            RECORD_TYPE_PREFIX = str(match.group(1))       
            return RECORD_TYPE_PREFIX

# Exclude messagekeys for generic metadata fields like 'tenant ID'
# and 'workflow state'. These typically aren't displayed with
# text labels, and most don't even appear in a user-visible context
# within the CollectionSpace UI.
def in_messagekey_stoplist(messagekey):
    global RECORD_TYPE_PREFIX
    stoplist = ['coreInformationLabel', 'createdAtLabel', 'createdByLabel', 'csidLabel', 'domaindataLabel',
        'inAuthorityLabel', 'numberLabel', 'refNameLabel', 'shortIdentifierLabel', 'summaryLabel', 'tenantIdLabel',
        'updatedAtLabel', 'updatedByLabel', 'uriLabel', 'workflowLabel']
    in_stoplist = False
    for stop_item in stoplist:
        if messagekey == RECORD_TYPE_PREFIX + stop_item:
            in_stoplist = True
            return in_stoplist

# Load the contents of a Java-style properties file.
# E.g. with per-line entries in the form 'key: value'.
# From Roberto
# http://stackoverflow.com/a/31852401
def load_properties(filepath, sep=':', comment_char='#'):
    props = {}
    with open(filepath, "rt") as f:
        for line in f:
            l = line.strip()
            # Added check that each line to be processed also contains the separator 
            if l and not l.startswith(comment_char) and sep in l:
                key_value = l.split(sep)
                props[key_value[0].strip()] = key_value[1].strip('" \t') 
    return props

if __name__ == '__main__':
    
    parser = ArgumentParser(description='Populate field label/selector associations')
    parser.add_argument('-b', '--bundle_file',
        help='file with text labels (defaults to \'core-messages.properties\' in current directory)', default = 'core-messages.properties')
    parser.add_argument('-u', '--uispec_file',
        help='file with data used to generate the page (defaults to \'uispec\' in current directory)', default = 'uispec')
    args = parser.parse_args()
    
    # ##################################################
    # Open and read the message bundle (text label) file
    # ##################################################
    
    bundle_path = args.bundle_file.strip()
    if not os.path.isfile(bundle_path):
        sys.exit("Could not find file \'%s\'" % bundle_path)
        
    text_labels = load_properties(bundle_path)
    text_labels_lowercase = {k.lower():v for k,v in text_labels.items()}
    
    # For debugging
    # for key,value in text_labels_lowercase.items():
    #     # Change the following hard-coded record type value as needed, for debugging
    #     if key.startswith('acquisition-'):
    #         print "%s: %s" % (key, str(value))
    
    # ##################################################
    # Open and read the uispec file
    # ##################################################

    uispec_path = args.uispec_file.strip()
    if not os.path.isfile(uispec_path):
        sys.exit("Could not find file \'%s\'" % uispec_path)
        
    with open(uispec_path) as uispec_file:    
        uispec = json.load(uispec_file)
    
    # From the uispec file ...
    
    # Check for presence of the expected top-level item
    TOP_LEVEL_KEY='recordEditor'
    try:
        uispec_items = uispec[TOP_LEVEL_KEY]
    except KeyError, e:
        sys.exit("Could not find expected top level item \'%s\' in uispec file" % TOP_LEVEL_KEY)
    
    # Verify that at least one item is present in the list of items
    # below the top level item
    if not uispec_items:
        sys.exit("Could not find expected items in uispec file")

    # ##################################################
    # Get the prefix for this record type
    # (used in selectors)
    # ################################################## 
    
    # TODO: As noted above, also need to handle instances of irregular
    # use of this prefix, as in CollectionObjects/Cataloging records   
    
    for selector, value in uispec_items.iteritems():
        
        # For debugging
        # print "%s %s\n" % (selector, value)
        
        # Set the record type prefix - just once - when we encounter
        # the first 'fields.fieldname' value.
        if RECORD_TYPE_PREFIX is None:
            # For debugging
            # print "record type prefix is none"
            field_name = get_field_name(value)
            if field_name is not None:
                # For debugging
                # print "Found record type prefix"
                prefix = get_record_type_selector_prefix(selector)
                break

    # ##################################################
    # Iterate through the list of selectors in the
    # uispec file and find those that have messagekeys.
    # These represent text labels that are, in many
    # cases, associated with fields. Store these selectors
    # and their text labels for further use below ...
    # ##################################################
        
    # ##################################################
    # Get messagekeys and their associated selectors
    # ##################################################

    CSC_PREFIX = 'csc-'
    CSC_RECORD_TYPE_PREFIX = CSC_PREFIX + RECORD_TYPE_PREFIX
    LABEL_CAMELCASE_SUFFIX = "Label"
    LABEL_SUFFIX = '-label'
    mkeys = {}
    for selector, value in uispec_items.iteritems():
        
        # For debugging
        # print "%s %s" % (selector, value)
        
        mkey = get_messagekey_from_item(value)
        # 'basestring' -> 'str' here in Python 3
        if isinstance(mkey, basestring):
            mkeys[selector] = mkey
        # Can use collections.abc abstract classes here in Python 3.3 and higher
        if mkey is None and isinstance(value, (dict, list, set, tuple)):
            for item in get_messagekeys_generator(value):
                # For debugging
                # print item
                if isinstance(item, list):
                    if str(item[0]) == MESSAGEKEY_KEY:
                        # This block is an outright hack
                        mkey_selector = '.' + CSC_RECORD_TYPE_PREFIX + str(item[1])
                        if mkey_selector.endswith(LABEL_CAMELCASE_SUFFIX):
                            mkey_selector= mkey_selector.replace(LABEL_CAMELCASE_SUFFIX, LABEL_SUFFIX)
                        mkeys[mkey_selector] = str(item[1])
            
    # ##################################################
    # For each messagekey, get its text label (if any)
    # ##################################################
        
    text_labels_not_found_msgs = []
    messagekeys = {}
    for selector, messagekey in mkeys.iteritems():
        # For debugging
        # print "selector messagekey = %s %s\n" % (selector, messagekey)
        if messagekey is not None:
            if in_messagekey_stoplist(messagekey):
                continue
            text_label = text_labels_lowercase.get(messagekey.lower(), None)
            if text_label is None or text_label.strip() is None:
                text_labels_not_found_msgs.append("// Not found: text label for message key '%s'" % messagekey)
            else:
                # Strip leading '.' from selector
                selector = selector.replace(selector[:1], '')
                messagekeys[selector] = text_label

    # For debugging
    # for key, value in messagekeys.iteritems():
    #     print 'fieldSelectorByLabel.put("%s", "%s");' % (value, key)
            
    # ##################################################
    # Do one last cleanup pass on messagekeys:
    # * Remove the 'Label' suffix from selectors
    # * Add placeholders for missing text labels
    # ##################################################
                    
    ADD_ME_VALUE = "ADD_ME"
    fields = {}
    for key, value in messagekeys.iteritems():
        messagekey_fieldname = rchop(key, LABEL_SUFFIX)
        if messagekey_fieldname.startswith(CSC_RECORD_TYPE_PREFIX):
            # Expression here includes ternary operator
            fields[messagekey_fieldname] = value if value is not (None or '') else ADD_ME_VALUE
            
    # ##################################################
    # Generate output suitable for pasting
    # ##################################################

    print '// ----- Start of entries generated by an automated script -----'
    print '// (Note: these require review by a human.)'
    print "\n"

    # ##################################################
    # Output regarding text label-selector associations
    # ##################################################
                    
    # Print associations between text labels and field selectors
    # TODO: Need to do case independent sorting here (e.g. on lowercase values)
    for key, value in sorted(fields.iteritems(), key=lambda (k,v): (v,k)):
        print 'fieldSelectorByLabel.put("%s", "%s");' % (value, key)

    # ##################################################
    # Output regarding errors
    # ##################################################
    
    # Print various potential errors as Java comments, for a human to look at/sort out
    
    # Duplicate text labels: instances where the same text label is
    # associated with two or more fields, or there is some other
    # discrepancy in text label-to-field associations.
    #
    # From user2357112
    # http://stackoverflow.com/a/20463090 
    value_occurrences = collections.Counter(fields.values())
    if value_occurrences is not None and len(value_occurrences) > 0:
        print "\n"
        print "// Entries above with duplicate text labels, to be checked by a human."
        print "//"
        print "// Some may represent labels for headers above repeatable fields/groups."
        for key, value in sorted(value_occurrences.iteritems()):
            if value > 1:
                print "// Duplicate text label: %s (appears %d times)" % (key, value)

    # Messagekeys in the 'uispec file without associated text labels in the
    # message bundle file (e.g. 'core-messages.properties').
    #
    # (Example: messagekey 'acquisition-ownerLabel' is present in the uispec
    # for the Acquisition record, but isn't found in the message bundle file;
    # only 'acquisition-ownersLabel' is present there.)
    if len(text_labels_not_found_msgs) > 0:
        print "\n"
        print "// Messagekeys in the 'uispec' file not matched by text labels"
        print "// in the message bundles file (e.g. 'core-messages.properties')."
        print "//"
        print "// Some of these may be record metadata that is never displayed"
        print "// in the UI. If so, they can be added to the script's stoplist."
        print "//"
        print "// In other instances, these may represent messagekeys for section"
        print "// headers in the record, rather than for fields."
        print "//"
        for msg in sorted(text_labels_not_found_msgs):
            print msg

    print "\n"
    print '// ----- End of entries generated by an automated script -----'

        
    