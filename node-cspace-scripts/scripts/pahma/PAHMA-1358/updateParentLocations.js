/* 
 * Set the current location of parent records from PAHMA-1353 to 'See child objects for location(s)'.
 *
 * See https://issues.collectionspace.org/browse/PAHMA-1358.
 */

var CollectionSpace = require('collectionspace');
var utils = require('../../../lib/utils.js');
var Q = require('q');
var fs = require('fs');
var util = require('util');
var csv = require('csv');
var bunyan = require('bunyan');

var log = bunyan.createLogger({ name: 'updateParentLocations' });

var user = process.env.CSPACE_USER;
var password = process.env.CSPACE_PW;
var inputFilePath = process.argv[2]; //'Set_parent_locations.csv';

var seeChildObjectsLocation = "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(location):item:name(seechildloc)'See child objects for location(s)'";

// var cspace = new CollectionSpace({
//   host: 'localhost',
//   tenant: 'pahma'
// });

var cspace = new CollectionSpace({
  host: 'pahma.cspace.berkeley.edu',
  port: '',
  ssl: true,
  tenant: 'pahma'
});

connect()
  .then(processInputFile)
  .then(disconnect)
  .then(finish)
  .catch(function(error) {
    log.error(error);
  });

function connect() {
  log.info("Connecting to CollectionSpace at " + cspace.getUrl());
  
  return cspace.connect(user, password);
}

function disconnect() {
  log.info("Disconnecting");
  
  return cspace.disconnect();
}

function finish() {
  log.info("Done");
}

function processInputFile() {
  var input = fs.createReadStream(inputFilePath);

  var parser = csv.parse({
    columns: ['parentCsid', 'parentObjectNumber']
  });
  
  var transformer = csv.transform(function(row, callback) {
    var collectionObjectCsid = row.parentCsid;
    
    cspace.getRecord('collectionobject', collectionObjectCsid)
      .then(function(parentData) {
        var needsUpdate = false;
        
        if (parentData.fields.narrowerContexts.length > 0) {
          var computedCurrentLocation = parentData.fields.computedCurrentLocation;
          var computedCrate = parentData.fields.computedCrate;
          
          if (computedCrate || (computedCurrentLocation !== seeChildObjectsLocation)) {
            needsUpdate = true;
          }
          else {
            log.info("Skipping " + collectionObjectCsid + ": already has the correct current location and crate");
          }
        }
        else {
          log.warn("Skipping " + collectionObjectCsid + ": not a parent");
        }
        
        if (needsUpdate) {
          log.info("Updating " + collectionObjectCsid);
          
          createMovementRecord()
            .then(function(movementData) {
              var movementCsid = movementData.csid;
        
              log.info("Created movement with csid " + movementCsid);
        
              return createRelation(collectionObjectCsid, movementCsid);
            })
            .then(function(relationData) {
              log.info({ createdRelation: relationData }, "Created relation");
        
              callback();
            })
            .catch(function(error) {
              callback(error);
            });
        }
        else {
          callback();
        }
      })
      .catch(function(error) {
        if (error.message === 'Does not exist (EAPI)') {
          // If the parent record isn't found, warn but allow processing to continue.
          
          log.error('Parent record not found: ' + error.csid);
          
          callback();
        }
        else {
          callback(error);
        }
      })
  }, {
    parallel: 1
  });
  
  var deferred = Q.defer();
  
  transformer.on('finish', function() {
    log.info("Processed " + transformer.finished + " rows");
    
    deferred.resolve(transformer.finished);
  });
  
  transformer.on('error', function(error) {
    deferred.reject(error);
  });
  
  input.pipe(parser).pipe(transformer);
  
  return deferred.promise;
}

function createMovementRecord() {
  var todayDate = utils.getCollectionSpaceDate();
  
  return cspace.createRecord('movement', {
    fields: {
      computedSummary: todayDate,
      currentLocation: seeChildObjectsLocation,
      locationDate: todayDate,
      movementNote: 'Child records created for object.',
      locationHandlers: [{
        _primary: true,
        locationHandler: "urn:cspace:pahma.cspace.berkeley.edu:personauthorities:name(person):item:name(7827)'Michael T. Black'"
      }]
    }
  });
}

function createRelation(collectionObjectCsid, movementCsid) {
  return cspace.createRecord('relationships', {
    items: [{
      'one-way': false,
      type: 'affects',
      source: {
        csid: collectionObjectCsid,
        recordtype: 'cataloging'
      },
      target: {
        csid: movementCsid,
        recordtype: 'movement'
      }
    }]
  });
}