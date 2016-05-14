#!/usr/bin/env python

from argparse import ArgumentParser
# import ConfigParser
import json
import re
import os
import sys

FIELD_PATTERN = re.compile("^\$\{fields\.(\w+)\}$", re.IGNORECASE)
def get_field_name(value):
    # 'basestring' -> 'str' here in Python 3
    if isinstance(value, basestring):
        match = FIELD_PATTERN.match(value)
        if match is not None:
            return str(match.group(1))
    # TODO:
    # Many fields are in repeatable structures, and
    # code MUST be added here to match those.
    # 
    # if isinstance(value, dict):
    #     for v in value.values():
            # stub
            # print "\nisdict\n"
            # print v

LABEL_SUFFIX = '-label'
def get_label_name_from_field_name(field_name):
    # TODO:
    # This may be wildly too simplistic and may miss many fields;
    # we might instead need to get all items that have 'messagekey' children
    return '.' + field_name + LABEL_SUFFIX

# Given the name of a label entry in the uispec file,
# get its 'messagekey' value
MESSAGEKEY_KEY = 'messagekey'
def get_messagekey_from_label_name(label_name, items):
    label_value = items[label_name]
    messagekey = label_value[MESSAGEKEY_KEY]
    return messagekey

# Get the selector prefix for the current record type (e.g. "acquisition-")
RECORD_TYPE_PREFIX = None
SELECTOR_PATTERN = re.compile("^\.(csc-\w+\-)?.*$", re.IGNORECASE)
def get_record_type_selector_prefix(selector):
    global RECORD_TYPE_PREFIX
    if RECORD_TYPE_PREFIX is not None:
        return RECORD_TYPE_PREFIX
    else:
        match = SELECTOR_PATTERN.match(selector)
        if match is not None:
            RECORD_TYPE_PREFIX = str(match.group(1))       
            return RECORD_TYPE_PREFIX

# Per Stack Overflow member 'Roberto' in http://stackoverflow.com/a/31852401
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
    
    # Get the list of items below the top level item
    
    # Check for presence of the expected top-level item
    TOP_LEVEL_KEY='recordEditor'
    try:
        uispec_items = uispec[TOP_LEVEL_KEY]
    except KeyError, e:
        sys.exit("Could not find expected top level item \'%s\' in uispec file" % TOP_LEVEL_KEY)
    
    # Check that at least one item was returned
    if not uispec_items:
        sys.exit("Could not find expected items in uispec file")
    
    # ##################################################
    # Iterate through the list of selectors in the
    # uispec file
    # ##################################################
    
    for selector, value in sorted(uispec_items.iteritems()):
        
        # TODO:
        # From a second look at the uispec file, there's likely
        # merit in first looking for all labels, and then finding
        # the fields that correspond to these labels (and getting
        # the latters' selectors)
        #
        # That would entail a bit of refactoring here 
        
        # Get selectors that are specifically for fields. (There are some
        # selectors in uispec files that are for other entity types)
        #
        # From those selectors, get their actual field names, as these
        # may not always match even a part of the selector.
        #
        # E.g. for selector '.csc-acquisition-acquisition-provisos'
        # its actual field name, following the initial '.csc-recordtype-...'
        # prefix, is 'acquisitionProvisos' (i.e. ${fields.acquisitionProvisos})
        field_name = get_field_name(value)
        if field_name is not None:
            prefix = get_record_type_selector_prefix(selector)
            field_name = prefix + field_name
            label = get_label_name_from_field_name(field_name)
            messagekey = get_messagekey_from_label_name(label, uispec_items)
            try:
                text_label = text_labels_lowercase[messagekey.lower()]
                if not text_label.strip():
                    print "// Could not find text label for message key '%s'" % messagekey
                else:
                    # Strip leading '.' from selector
                    print 'fieldSelectorByLabel.put("%s", "%s");' % (text_label, selector.replace(selector[:1], ''))
            except KeyError, e:
                print "// Could not find message key '%s'" % messagekey

            
        
    