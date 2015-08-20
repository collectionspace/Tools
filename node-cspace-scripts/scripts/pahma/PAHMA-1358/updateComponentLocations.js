/* 
 * If the current location of a component record created in PAHMA-1353 is 'See child objects for location(s)',
 * delete the relation to the LMI record, and recalculate the computed current location.
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

var log = bunyan.createLogger({ name: 'updateComponentLocations' });

var user = process.env.CSPACE_USER;
var password = process.env.CSPACE_PW;
var inputFilePath = process.argv[2]; //'createdcsids.csv';

var seeChildObjectsLocation = "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(location):item:name(seechildloc)'See child objects for location(s)'";
//var seeChildObjectsLocation = "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(location):item:name(Seechildobjectsforlocations1439409241977)'See child objects for location(s)'";
var seeChildObjectsLocationName = "See child objects for location(s)";

//var updateComputedCurrentLocationBatchCsid = '480d4f74-9a21-4e85-a207';
var updateComputedCurrentLocationBatchCsid = '309c6cd9-03cc-4f2c-b23c';

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
    columns: ['componentCsid']
  });
  
  var transformer = csv.transform(function(row, callback) {
    var componentCsid = row.componentCsid;
    
    cspace.getRecord('collectionobject', componentCsid)
      .then(function(componentData) {
        var needsUpdate = false;
        
        if (componentData.fields.broaderContext) {
          if (! componentData.fields.narrowerContexts[0].narrowerContext) {
            var computedCurrentLocation = componentData.fields.computedCurrentLocation;
          
            if (computedCurrentLocation === seeChildObjectsLocation) {
              needsUpdate = true;
            }
            else {
              log.info("Skipping " + componentCsid + ": has location " + computedCurrentLocation);
            }
          }
          else {
            log.warn("Skipping " + componentCsid + ": is a parent");
          }
        }
        else {
          log.warn("Skipping " + componentCsid + ": is not a component");
        }
        
        if (needsUpdate) {
          log.info("Updating " + componentCsid);
          
          var searchOptions = {
            pageSize: 0,
            sortDir: cspace.SortDir.DESCENDING,
            sortKey: 'movements_common.locationDate'
          };
          
          cspace.findRelated('collectionobject', componentCsid, 'movement', searchOptions)
            .then(function(relatedMovements) {
              var movementCsid = null;
              
              if (relatedMovements.items && relatedMovements.items.length > 0) {
                var firstItem = relatedMovements.items[0];
              
                if (firstItem.summarylist.currentLocation === seeChildObjectsLocationName) {
                  movementCsid = firstItem.csid;
                }
                else {
                  log.error("Unexpected related movement for" + componentCsid + ": latest movement location is not '" + seeChildObjectsLocationName + "'");
                }
              }
              else {
                log.error("No related movements found for " + componentCsid);
              }
              
              if (movementCsid != null) {
                log.info("Deleting relation to movement " + movementCsid);
                
                deleteRelation(componentCsid, movementCsid)
                  .then(function(data) {
                    log.info("Deleted relation to movement " + movementCsid);
                    
                    callback();
                  })
                  .catch(function(error) {
                    callback(error);
                  })
                
                callback();
              }
              else {
                callback();
              }
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
          // If the component record isn't found, warn but allow processing to continue.
          
          log.error('Component record not found: ' + error.csid);
          
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

function deleteRelation(collectionObjectCsid, movementCsid) {
  return cspace.deleteRelation({
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
  });
}