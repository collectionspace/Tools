#!/usr/bin/env python

from argparse import ArgumentParser
import collections
import json
import re
import os
import sys

# TODO: Replace commented-out debugging statements
# with debug or trace level log statements

# TODO: Handle fields represented in the 'uispec' file as
# ${row.fieldname} values, not just ${fields.fieldname} values.

# TODO: Handle structured dates. These will be present within
# lists containing key 'func', value 'cspace.structuredDate',
# and have the form '${fields.groupname.fieldname}', while
# their associated text labels in the message bundle file
# will have the form 'structuredDate-fieldname'.

# From Jack Kelly
# http://stackoverflow.com/a/3663505
def rchop(thestring, ending):
  if thestring.endswith(ending):
    return thestring[:-len(ending)]
  return thestring

# From Bryukhanov Valentin
# http://stackoverflow.com/a/12507546
# (renamed and with minor changes to variable names)
def list_generator_from_dict(current_dict, prefix=None):
    prefix = prefix[:] if prefix else []
    if isinstance(current_dict, dict):
        for key, value in current_dict.items():
            if isinstance(value, dict):
                for d in list_generator_from_dict(value, [key] + prefix):
                    yield d
            elif isinstance(value, list) or isinstance(value, tuple):
                for v in value:
                    for d in list_generator_from_dict(v, [key] + prefix):
                        yield d
            else:
                yield prefix + [key, value]
    else:
        yield current_dict
        
FIELD_PATTERN = re.compile("^\$\{fields\.(\w+)\}$", re.IGNORECASE)
def get_field_name(value):
    # 'basestring' -> 'str' here in Python 3
    if isinstance(value, basestring):
        match = FIELD_PATTERN.match(value)
        if match is not None:
            return str(match.group(1))

MESSAGEKEY_KEY = 'messagekey'
def get_messagekey_from_item(item):
    # 'basestring' -> 'str' here in Python 3
    if isinstance(item, dict):
        try:
            messagekey = item[MESSAGEKEY_KEY]
            return messagekey
        except KeyError, e:
            return None
    else:
        return None

# Get the selector prefix for the current record type (e.g. "acquisition-")
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
    stoplist = ['coreInformationLabel', 'createdAtLabel', 'createdByLabel', 'domaindataLabel',
        'numberLabel', 'refNameLabel', 'summaryLabel', 'tenantIdLabel',
        'updatedAtLabel', 'updatedByLabel', 'uriLabel', 'workflowLabel']
    in_stoplist = False
    for stop_item in stoplist:
        if messagekey == RECORD_TYPE_PREFIX + stop_item:
            in_stoplist = True
            return in_stoplist

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
    # Iterate through the list of selectors in the
    # uispec file and find those that have messagekeys.
    # These represent text labels that are, in many,
    # cases, associated with fields. Store these selectors
    # and their text labels for further use below ...
    # ##################################################
    
    messagekeys = {}
    messagekeys_not_found_msgs = []
    text_labels_not_found_msgs = []
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
    
    for selector, value in uispec_items.iteritems():
        
        # For debugging
        # print "%s %s\n" % (selector, value)
        
        # ##################################################
        # For each selector, get its text label (if any)
        # ##################################################
        
        messagekey = get_messagekey_from_item(value)
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
    # Get a set of lists from the uispec file dict
    # ##################################################
    
    generator = list_generator_from_dict(uispec[TOP_LEVEL_KEY])

    # ##################################################
    # Filter the set of lists, retaining just those items
    # that have selectors
    # ##################################################

    selector_items = []
    for uispec_item in generator:
        # TODO: There may be more elegant and/or faster ways to do this
        # with list comprehensions and/or fiters
        # For debugging
        # print uispec_item
        if isinstance(uispec_item, list):
            for u_item in uispec_item:
                # TODO: Replace with regex to avoid unintentional matches
                if str(u_item).startswith(".cs"):
                    selector_items.append(uispec_item)
    
    # For debugging
    # for s_item in selector_items:
    #     print s_item

    # ##################################################
    # Further filter the set of lists, retaining just
    # those selector items that also have fields
    # ##################################################
        
    field_items = []
    field_regex = re.compile(".*fields\.", re.IGNORECASE)
    for selector_item in selector_items:
        for entry in selector_item:
            if field_regex.match(entry):
                field_items.append(selector_item)
               
    # For debugging
    # for f_item in field_items:
    #     print f_item

    # ##################################################
    # For each field, match it with its associated
    # text label
    # ##################################################
                    
    LABEL_SUFFIX = '-label'
    CSC_PREFIX = 'csc-'
    CSC_RECORD_TYPE_PREFIX = CSC_PREFIX + RECORD_TYPE_PREFIX
    CSC_RECORD_TYPE_PREFIX_LENGTH = len(CSC_RECORD_TYPE_PREFIX)
    fields = {}
    fields_not_found_msgs = []
    # Iterate through the list of text labels
    for key, value in messagekeys.iteritems():
        messagekey_fieldname = rchop(key, LABEL_SUFFIX)
        if messagekey_fieldname.startswith(CSC_RECORD_TYPE_PREFIX):
            messagekey_fieldname = messagekey_fieldname[CSC_RECORD_TYPE_PREFIX_LENGTH:]
        # For debugging
        # print messagekey_fieldname
        # if 'somestringhere' in messagekey_fieldname:
        #     print messagekey_fieldname
        found = False
        num_found = 0
        for field_item in field_items:
            for item in field_item:
                messagekey_fieldname_regex = re.compile(".*fields\.([^\.]\.)?" + messagekey_fieldname, re.IGNORECASE)
                if messagekey_fieldname_regex.match(str(item)):
                    for possible_selector_item in field_item:
                        if str(possible_selector_item).startswith("." + CSC_PREFIX):
                            # For debugging
                            # print "=> %s" % possible_selector_item
                            fieldkey = possible_selector_item.replace(possible_selector_item[:1], '')
                            # Add this field selector if we haven't already added it
                            key_already_added = fields.get(fieldkey, None)
                            if not key_already_added:
                                fields[fieldkey] = value
                                found = True
                                # For debugging
                                # if 'somestringhere' in messagekey_fieldname:
                                #     print fieldkey
                                #     print value
                            # For debugging
                            # num_found += 1
                            # print num_found
                            # print "fieldkey %s, value %s" % (fieldkey, value)
        if not found:
            fields_not_found_msgs.append("// Not found: field for label %s" % rchop(key, LABEL_SUFFIX))
    
    print '// ----- Start of entries generated by an automated script -----'
    print '// (Note: these require review by a human.)'
    print "\n"
    
    # Print associations between text labels and field selectors
    # TODO: Need to do case independent sorting here (e.g. on lowercase values)
    for key, value in sorted(fields.iteritems(), key=lambda (k,v): (v,k)):
        print 'fieldSelectorByLabel.put("%s", "%s");' % (value, key)
    
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
        print "// Entries above with duplicate text labels, to be checked by a human"
        print "//"
        for key, value in value_occurrences.iteritems():
            if value > 1:
                print "// Duplicate text label: %s (appears %d times)" % (key, value)

    # Text labels that aren't matched by associated fields in the uispec.
    #
    # (These might sometimes reflect exceptions to a nearly always-followed
    # naming convention, in which the existence of a '... fieldName-label'
    # messagekey selector is matched by a field selector 'fieldName';
    # i.e. the same name with the '-label' suffix removed.)
    if len(fields_not_found_msgs) > 0:
        print "\n"
        print "// Messagekeys not matched by fields in the 'uispec' file."
        print "//"
        print "// Label-field associations for these fields may need to be human-added."
        print "// Perhaps 'fieldname-label' => 'fieldname' convention was not followed?"
        print "// Sometimes this can result from pluralization of one of these names."
        print "// In other cases, these may be fields within a repeatable group"
        print "// that are not yet handled by the automated script."
        print "//"
        for msg in sorted(fields_not_found_msgs):
            print msg
            if 'DateGroup' in msg:
                print "// (If item above is a structured date, it must be added manually here)"

    # Messagekeys in the 'uispec file without associated text labels in the
    # message bundle file (e.g. 'core-messages.properties').
    #
    # (Example: messagekey 'acquisition-ownerLabel' is present in the uispec
    # for the Acquisition record, but isn't found in the message bundle file;
    # only 'acquisition-ownersLabel' is present there.)
    if len(fields_not_found_msgs) > 0:
        print "\n"
        print "// Messagekeys in the 'uispec' file not matched by text labels"
        print "// in the message bundles file (e.g. 'core-messages.properties')"
        print "//"
        print "// Some of these may be common record metadata that is never displayed"
        print "// in the UI. If so, they can be added to the script's stoplist."
        print "//"
        print "// In other instances, these may represent messagekeys for section"
        print "// headers in the record, rather than for fields."
        print "//"
        for msg in sorted(text_labels_not_found_msgs):
            print msg

    print "\n"
    print '// ----- End of entries generated by an automated script -----'

        
    