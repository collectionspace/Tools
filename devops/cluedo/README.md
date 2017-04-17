Toy Scripts To Load the "Cluedo Museum"
=======================================

This suite of scripts loads records of different types in a CSpace deployment.

The goal is to demonstrate how to load data into CSpace.

The records form a coherent set of collection objects with metadata pointing
to 3 authorities (persons, places, and materials).

The set is based on the classic board game Cluedo (better known in the US as
Clue). You know, "Mr. Green, in the Kitchen, with the Candlestick".

Media are also provided and linked where possible to their corresponding
entities in CSpace.

(Permission to use the images has been obtained and may be found in the
PERMISSIONS file.)

The process works as follows:

* A small script parses an XML file which contains a description of all
the entities and creates several intermedia .csv files
* Several other scripts load these files into CSpace to create authority and
collectionobject records.
* The CSIDs of the records created above are used to create relations
between them.

How to run the suite

First, you'll need to set environment variables for the server and credentials.
An example script is provided for this purpose. You will need to customized it.

A version already customized for the existing, publicly accessible 
CollectionSpace "nightly" server is provide.

The another script runs the rest of the suite.

```
# set up server and credentials
source set-nightly.sh 
# generate the various .csv file for authorities, objects, etc.
# and load them, in order, into CSpace
./loadCluedo.sh 
```

Afew notes:

* If you run this on nightly, please run the cleanup script to remove the records you created:

```
./cleanup.sh
```

* `loadCluedo.sh` assume that nightly is the target. You'll need to edit this script to point to different authorities in different deployments.
