#!/usr/bin/env python

# Simple script to perform hard deletion of authority terms via the CollectionSpace
# Services REST API, checking before deletion (as does Collectionspace's UI layer)
# whether there are any references to each term.
#
# Requires a separate text file containing one identifier for an authority term
# per line - either a CSID or a URN - thus identifying each term to be deleted.
# (Run this script with the '-h' argument for usage instructions.)
#
# This script also provides a rudimentary example of invoking the Services REST API from Python.

# FIXME: Generates verbose messages, including debugging messages, to the console.
# Using Python's integral logging library might be a way to better manage this output.

from string import Template
import argparse
import base64
import exceptions
import httplib # renamed to http.client in Python 3
import os
import sys
import xml.etree.ElementTree as elementtree

# Variables used as constants
AUTHORITY_URL_TEMPLATE_STR = '/cspace-services/${auth}/${auth_csid}'
TERM_URL_TEMPLATE_STR = AUTHORITY_URL_TEMPLATE_STR + '/items/${item_csid}'
REFERRING_OBJECTS_URL_TEMPLATE_STR = TERM_URL_TEMPLATE_STR + '/refObjs?pgSz=5&pgNum=0'

# FIXME: The following values are currently hard-coded here, rather than being
# supplied via command line arguments, read from environment variables, etc.
username = 'admin@core.collectionspace.org'
password = 'Administrator'
host = 'localhost'
port = 8180

def main():
    
    parser = get_args_parser()
    args = parser.parse_args()
    
    authority_name = args.authority;
    authority_identifier = args.authority_id;
    termcsids_filename = args.filename;
    
    sys.stdout.write('authority_name = ' + authority_name + '\n')
    sys.stdout.write('authority_identifier = ' + authority_identifier + '\n')
    sys.stdout.write('termcsids_filename = ' + termcsids_filename + '\n')

    sys.stdout.write("Verifying authority exists ..." + '\n')
    if not authority_exists(authority_name, authority_identifier):
        sys.stdout.write("'Could not find authority '" + authority_name
                         + " with identifier '" + authority_identifier + "'\n")
        exit(1)
        
    sys.stdout.write("Reading authority term identifiers from file '" + termcsids_filename + "' ...\n")
    csids = read_term_csids_from_file(termcsids_filename)
    if len(csids) == 0:
        sys.stdout.write("Could not read authority term identifiers from file '" + termcsids_filename + "'\n")
        exit(1)

    sys.stdout.write("Identifying terms that aren't referred to by other records ..." + '\n')
    terms_to_delete = build_terms_to_delete_list(csids, authority_name, authority_identifier)
    
    sys.stdout.write("Found " + str(len(terms_to_delete)) + " term(s) to delete" + '\n')
    if len(terms_to_delete) > 0:
        sys.stdout.write("Deleting terms ..." + '\n')
        delete_terms(terms_to_delete, authority_name, authority_identifier)

def get_args_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument("-n", required=True,
                        dest="authority",
                        help="authority name in URL; e.g. 'personauthorities'")
    parser.add_argument("-i", required=True,
                        dest="authority_id",
                        help="authority identifier, either a CSID or URN")
    parser.add_argument("-f",
                        dest="filename",
                        default="authority-term-csids.txt",
                        help="filename for authority term CSIDs, one per line")
    return parser

def authority_exists(authority_name, authority_identifier):
    authority_exists = False
    url_str=build_url(AUTHORITY_URL_TEMPLATE_STR,
                      authority_name, authority_identifier, '');
    response = perform_http_get_request(host, port, username, password, url_str);
    if response.status == httplib.OK:
        authority_exists = True
    return authority_exists

def read_term_csids_from_file(termcsids_filename):
    csids = []
    f = None
    try:
        f = open(termcsids_filename, 'r')
    except IOError, ioex:
        print 'Cannot open file', termcsids_filename, ':', os.strerror(ioex.errno)
    else:
        csids = f.readlines()
    finally:
        if f is not None:
            if hasattr(f, 'close'):
                f.close()
        return csids
                
def build_terms_to_delete_list(csids, authority_name, authority_identifier):            
    terms_to_delete = []
    for csid in csids:
        num_referring_objects = num_referring_objects_for_term(authority_name, authority_identifier, csid.strip())
        sys.stdout.write('referring objects = ' + str(num_referring_objects) + '\n')
        # If there are no objects that refer to this term (and no error occurred when retrieving
        # its referring objects), add this term's CSID to the 'terms to be deleted' list
        if num_referring_objects == 0:
            terms_to_delete.append(csid.strip())
    return terms_to_delete
                
def num_referring_objects_for_term(authority_name, authority_identifier, term_identifier):
    url_str=build_url(REFERRING_OBJECTS_URL_TEMPLATE_STR,
                      authority_name, authority_identifier, term_identifier);
    sys.stdout.write('url_str = ' + url_str + '\n')
    response = perform_http_get_request(host, port, username, password, url_str);
    referring_objects = -1 # Defaults to assuming an error value, by convention
    if response.status == httplib.OK:
        referring_objects_str = parse_for_num_referring_objects(response.read())
        if referring_objects_str is not None:
            referring_objects = str_to_int(referring_objects_str)
    return referring_objects
    
def str_to_int(str):
    try:
        return int(str)
    except exceptions.ValueError:
        return -1 # Indicates an error value
    
def parse_for_num_referring_objects(xmlstr):
  return text_value_from_element(xmlstr, "itemsInPage")

def text_value_from_element(xmlstr, element_name):
    if xmlstr is None:
       return ''
    root = elementtree.fromstring(xmlstr)
    if root is None:
        return ''
    element = root.find(element_name) # Finds the first child element with the specified name
    if element is None:
        return ''
    if element.text is None:
        return ''
    else:
        return element.text
        
def delete_terms(terms_to_delete, authority_name, authority_identifier):
    for term_identifier in terms_to_delete:
        sys.stdout.write('term to delete = ' + term_identifier + '\n')
        response = delete_term(term_identifier, authority_name, authority_identifier)

def delete_term(term_identifier, authority_name, authority_identifier):
    url_str=build_url(TERM_URL_TEMPLATE_STR,
                      authority_name, authority_identifier, term_identifier);
    perform_http_delete_request(host, port, username, password, url_str);
        
def build_url(url_template_str, authority_name, authority_identifier, term_identifier):
    url_template = Template(url_template_str)
    url_str = ''
    try:
        url_str = url_template.substitute(auth=authority_name, 
                                          auth_csid=authority_identifier,
                                          item_csid=term_identifier)
    except ValueError, valerr:
        print 'Cannot build URL string', ':', os.strerror(valerr.errno)
    else:
        return url_str
        
def perform_http_get_request(host, port, username, password, url):
    return perform_http_request_no_body("GET", host, port, username, password, url)
    
def perform_http_delete_request(host, port, username, password, url):
    return perform_http_request_no_body("DELETE", host, port, username, password, url)
    
def perform_http_request_no_body(http_method, host, port, username, password, url):
    conn = httplib.HTTPConnection(host, port)
    headers = {"Authorization": "Basic %s" % get_basic_auth_credentials(username, password)}
    conn.request(http_method, url, "", headers)
    response = conn.getresponse()
    print response.status, response.reason
    return response
    
def get_basic_auth_credentials(username, password):
    return base64.standard_b64encode('%s:%s' % (username, password)).strip().replace('\n', '')

if __name__ == "__main__":
   main()