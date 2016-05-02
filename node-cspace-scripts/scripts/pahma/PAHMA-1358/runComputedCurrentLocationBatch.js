/* 
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

    // cspace.getRecord('collectionobject', componentCsid)
    //   .then(function(componentData) {
    //     var computedCurrentLocation = componentData.fields.computedCurrentLocation;
    //
    //     if (computedCurrentLocation === seeChildObjectsLocation) {
    //       var searchOptions = {
    //         pageSize: 0,
    //         sortDir: cspace.SortDir.DESCENDING,
    //         sortKey: 'movements_common.locationDate'
    //       };
    //
    //       cspace.findRelated('collectionobject', componentCsid, 'movement', searchOptions)
    //         .then(function(relatedMovements) {
    //           log.info("Component " + componentCsid + " needs update; related movements: " + relatedMovements.items.length);
    //
    //           callback();
    //         })
    //         .catch(function(error) {
    //           callback(error);
    //         });
    //     }
    //     else {
    //       callback();
    //     }
    //   })
    //   .catch(function(error) {
    //     callback(error);
    //   });
      
    log.info("Updating computed current location for " + componentCsid);

    updateComputedCurrentLocation(componentCsid)
      .then(function(data) {
        log.info(data, "Updated computed current location for " + componentCsid);

        callback();
      })
      .catch(function(error) {
        callback(error);
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

function updateComputedCurrentLocation(collectionObjectCsid) {
  return cspace.invokeBatch(updateComputedCurrentLocationBatchCsid, 'collectionobject', collectionObjectCsid);
}