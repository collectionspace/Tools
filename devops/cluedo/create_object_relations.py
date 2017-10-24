import csv
import os
import sys
import Queue
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape
from cswaExtras import *
# from loadCSpace import *

username = os.environ['LOGIN']
password = os.environ['PASSWORD']
server = os.environ['CSPACEURL']
realm = 'org.collectionspace.services'

# only use collectionobjects and storage locations, then link those using a group thing
# read in entities.csv 

entities_file = "entities.csv"
locations_file = "locationauthorities.created.csv"
objects_file = "collectionobjects.created.csv"

request_csids = False

if len(sys.argv) > 1:
    entities_file = sys.argv[1]
    if len(sys.argv) == 2:
        request_csids = True #this means only entities were provided, and fetching will be needed
    else:
        locations_file = sys.argv[2]
        objects_file = sys.argv[3]



# Step 1: Read in the file that we will use to pair things!
type_to_name_map = {}
with open(entities_file, "rb") as csvfile:
    reader = csv.reader(csvfile, delimiter="\t")
    for row in reader:
        record_type = row[0]
        obj_type = row[1]
        obj_name = row[2]
        if record_type in type_to_name_map:
            termslist = type_to_name_map[record_type]
            termslist.append(obj_name)
            type_to_name_map[record_type] = termslist
        else:
            type_to_name_map[record_type] = [obj_name]


def pair_ids_from_csv():
    """
    Pairs Locations and Objects, getting their csids from a CSV file rather than through 
    HTTP requests.
    """
    location_ids = {}
    location_refnames = {}
    with open(locations_file, "rb") as loccsv:
        reader = csv.reader(loccsv, delimiter="\t")
        for row in reader:
            location_ids[row[2]] = row[3]
            location_refnames[row[2]] = row[5]

    object_ids = {}
    object_refnames = {}
    with open(objects_file, "rb") as objcsv:
        reader = csv.reader(objcsv, delimiter="\t")
        for row in reader:
            object_ids[row[2]] = row[3]
            object_refnames[row[2]] = row[5]

    pairedCSV = csv.writer(open("paired_entities.csv", "wb"), delimiter="\t")
    
    # Queue the rooms in order to put elements inside of them
    locations_queue = Queue.Queue()
    for location in type_to_name_map["storagelocation"]:
        locations_queue.put(location)

    for obj in type_to_name_map["collectionobject"]:
        location = locations_queue.get()
        object_id = object_ids[obj]
        loc_id = location_ids[location]

        pairedCSV.writerow([obj, object_id, location, loc_id])
        # pairedCSV.writerow([location, loc_id, obj, object_id])
        locations_queue.put(location)

    return (location_refnames, object_refnames)

def pair_ids_from_request():
    return {}, {}

def substitute(mh,payload):
    for m in mh.keys():
        payload = payload.replace('{%s}' % m, escape(mh[m]))

    # get rid of any unsubstituted items in the template
    payload = re.sub(r'\{.*?\}', '', payload)
    return payload

if request_csids:
    location_refnames, object_refnames = pair_ids_from_request()
else:
    location_refnames, object_refnames = pair_ids_from_csv()



xmlfile = 'xml/%s.xml' % "movements"

template = open(xmlfile).read()
username = os.environ['LOGIN']
password = os.environ['PASSWORD']
server = os.environ['CSPACEURL']
realm = 'org.collectionspace.services'
uri = 'movements'
relations_uri = 'relations'

movementscreated = csv.writer(open("movements.created.csv", "wb"), delimiter="\t")

# load file from paired_entities.csv [obj, obj_id, loc, loc_id]
sequence_number = 0
# with open(entities_file, "rb") as csvfile:
#     reader = csv.reader(csvfile, delimiter="\t")
mov2obj_template = open("xml/mov2obj.xml").read()
obj2mov_template = open("xml/obj2mov.xml").read()

with open("paired_entities.csv", "rb") as entity_pairs:
    reader = csv.reader(entity_pairs, delimiter="\t")
    for row in reader:
        sequence_number += 1
        obj = row[0]
        obj_id = row[1]
        loc = row[2]
        loc_id = row[3]
        loc_refname = location_refnames[loc]

        # 1. Create a new movement record, link the movement location
        payload = substitute({"authority": "", "sequencenumber":"%03d" % sequence_number,"currentLocation":loc_refname}, template)
        (url, data, movement_id) = make_request("POST", uri, realm, server, username, password, payload)


        # 2. Link the movement record and the object record
        payload = substitute({"objectCsid": obj_id, "movementCsid":movement_id}, mov2obj_template)
        (url, data, relation_id1) = make_request("POST", relations_uri, realm, server, username, password, payload)

        # 3. Link object and movement
        payload = substitute({"objectCsid": obj_id, "movementCsid": movement_id}, obj2mov_template)
        (url, data, relation_id2) = make_request("POST", relations_uri, realm, server, username, password, payload)

        x = ("curl -S --stderr - -X DELETE https://nightly.collectionspace.org/cspace-services/movements/%s --basic -u \"admin@core.collectionspace.org:Administrator\" -H \"Content-Type: application/xml\"" % movement_id)
        y = ("curl -S --stderr - -X DELETE https://nightly.collectionspace.org/cspace-services/relations/%s --basic -u \"admin@core.collectionspace.org:Administrator\" -H \"Content-Type: application/xml\"" % relation_id1)
        z = ("curl -S --stderr - -X DELETE https://nightly.collectionspace.org/cspace-services/relations/%s --basic -u \"admin@core.collectionspace.org:Administrator\" -H \"Content-Type: application/xml\"" % relation_id2)

        movementscreated.writerow([x])
        movementscreated.writerow([y])
        movementscreated.writerow([z])