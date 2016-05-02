/* 
 * See https://issues.collectionspace.org/browse/PAHMA-1368.
 */

var CollectionSpace = require('collectionspace');
var pahma = require('../../../lib/pahma.js');
var utils = require('../../../lib/utils.js');
var Q = require('q');
var fs = require('fs');
var util = require('util');
var csv = require('csv');
var bunyan = require('bunyan');
var extend = require('extend');

var log = bunyan.createLogger({ name: 'createComponents' });
var lastConnectTime = null;
var connectionTimeout = 30 * 60 * 1000; // 30 minutes (in ms)

var user = process.env.CSPACE_USER;
var password = process.env.CSPACE_PW;
var inputFilePath = process.argv[2]; //'List_of_7214_records_to_copy_to_create_(0)_suffixes.csv';

var hoursToSlow = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17];
var pauseWhenSlowed = 10 * 1000; // 10 seconds (in ms)

var seeChildObjectsLocation = "urn:cspace:pahma.cspace.berkeley.edu:locationauthorities:name(location):item:name(Seechildobjectsforlocations1439409241977)'See child objects for location(s)'";
var seeChildObjectsLocationName = "See child objects for location(s)";

var exitRequested = false;

process.on('SIGINT', function() {
  log.info('Received SIGINT');
  
  exitRequested = true;
});

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

  lastConnectTime = Date.now();
  
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
    columns: ['componentObjectNumber', 'parentObjectNumber', 'parentSortableObjectNumber', 'parentCsid']
  });
  
  var transformer = csv.transform(function(row, callback) {
    var parentCsid = row.parentCsid;
    var parentData = null;
    var componentObjectNumber = row.componentObjectNumber;
    var componentCsid = null;
    
    cspace.getRecord('collectionobject', parentCsid)
      .then(function(data) {
        parentData = data;
        
        return createChildRecord(componentObjectNumber, parentData);
      })
      .then(function(childData) {
        componentCsid = childData.csid;
        
        log.info({ createdComponent: { componentObjectNumber: componentObjectNumber, componentCsid: componentCsid, parentCsid: parentCsid } }, 'Created component ' + row.componentObjectNumber + ' with csid ' + childData.csid + ' as child of ' + row.parentCsid);

        return copyRelations(parentCsid, componentCsid, ['media', 'acquisition']);
      })
      .then(function(relationData) {
        log.info({ createdRelations: relationData }, 'Related ' + relationData.items.length + ' media/acquisition records');
        
        return copyMovementRelations(parentCsid, componentCsid);
      })
      .then(function(relationData) {
        log.info({ createdRelations: relationData }, 'Related ' + relationData.items.length + ' movement records');

        return relocateParent(parentData);
      })
      .then(function() {
        return pause();
      })
      .then(function() {
        return checkConnection();
      })
      .then(function() {
        if (exitRequested) {
          throw(new Error('Exited by user request'));
        }
        
        callback();
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

/*
 * Creates a new child (component) record. The child is created as a clone of the parent,
 * mimicking the "Create new from existing" functionality in the UI. Then some field
 * values are changed.
 */
function createChildRecord(objectNumber, parentData) {
  var parentCsid = parentData.csid;
  
  // The fieldsToIgnore setting is copied from UI layer configuration, in order to
  // produce the same results as "Create new from existing".
  
  var fieldsToIgnore = [
    'csid', 'createdAt', 'createdBy', 'updatedAt', 'updatedBy', 'objectNumber', 'narrowerContexts', 'computedCurrentLocation',
    'computedCrate', 'objectNameGroup', 'measuredPartGroup', 'inventoryCount', 'sex', 'ageEstimateGroup', 'briefDescriptions', 'titleGroup'
  ];

  // Clone parentData.
  
  var data = {};
  extend(true, data, parentData);
  
  var fields = data.fields;

  // Delete fieldsToIgnore.
  
  delete data.csid;
  
  fieldsToIgnore.forEach(function(fieldName) {
    delete fields[fieldName];
  });

  // Set field values.
  
  fields.objectNumber = objectNumber;
  fields.sortableObjectNumber = pahma.computeSortableObjectNumber(objectNumber);
  fields.isComponent = 'yes';
  fields.numberOfObjects = '1';

  fields.objectNameGroup = [{
    _primary: true,
    objectName: 'human remains',
    objectNameCurrency: 'current',
    objectNameLanguage: "urn:cspace:pahma.cspace.berkeley.edu:vocabularies:name(languages):item:name(eng)'English'",
    objectNameLevel: 'whole',
    objectNameNote: '',
    objectNameSystem: '',
    objectNameType: 'simple',
  }];

  fields.broaderContext = parentData.fields.refName;
  fields.broaderContextType = 'component';

  return cspace.createRecord('collectionobject', data);
}

/*
 * Copies the relations of a collection object to another.
 *   fromCsid     The csid of the source record
 *   toCsid       The csid of the destination record
 *   recordTypes  An array of record types. Relations between the source record
 *                and records of the specified types will be copied to the 
 *                destination record.
 * Returns a promise that is fulfilled after the relations have been created.
 */
function copyRelations(fromCsid, toCsid, recordTypes) {
  var deferred = Q.defer();
  var relations = [];
  
  var promises = recordTypes.map(function(recordType) {
    return cspace.findRelated('collectionobject', fromCsid, recordType, { pageSize: 0 });
  })
  
  Q.all(promises)
    .then(function(responses) {
      responses.forEach(function(response) {
        if (response.items) {
          response.items.forEach(function(item) {
            relations.push({
              'one-way': false,
              type: 'affects',
              source: {
                csid: toCsid,
                recordtype: 'cataloging'
              },
              target: {
                csid: item.csid,
                recordtype: item.recordtype
              }
            });
          });
        }
      });
    
      if (relations.length > 0) {
        cspace.createRecord('relationships', { items: relations })
          .then(function(data) {
            deferred.resolve(data);
          })
          .catch(function(error) {
            throw(error);
          })
      }
      else {
        deferred.resolve({
          items: []
        });
      }
    })
    .catch(function(error) {
      deferred.reject(error);
    });

  return deferred.promise;
}

function copyMovementRelations(fromCsid, toCsid) {
  var deferred = Q.defer();
  var relations = [];

  var searchOptions = {
    pageSize: 0,
    sortDir: cspace.SortDir.DESCENDING,
    sortKey: 'movements_common.locationDate'
  };
  
  cspace.findRelated('collectionobject', fromCsid, 'movement', searchOptions)
    .then(function(relatedMovements) {
      if (relatedMovements.items && relatedMovements.items.length > 0) {
        var firstItem = relatedMovements.items[0];
      
        if (firstItem.summarylist.currentLocation === seeChildObjectsLocationName) {
          log.info("Omitting relation to '" + seeChildObjectsLocationName + "'");
          
          relatedMovements.items.shift();
        }
        
        relatedMovements.items.forEach(function(item) {
          relations.push({
            'one-way': false,
            type: 'affects',
            source: {
              csid: toCsid,
              recordtype: 'cataloging'
            },
            target: {
              csid: item.csid,
              recordtype: item.recordtype
            }
          });
        });
      }
      
      if (relations.length > 0) {
        cspace.createRecord('relationships', { items: relations })
          .then(function(data) {
            deferred.resolve(data);
          })
          .catch(function(error) {
            throw(error);
          })
      }
      else {
        deferred.resolve({
          items: []
        });
      }
    })
    .catch(function(error) {
      deferred.reject(error);
    });

  return deferred.promise;
}

function relocateParent(parentData) {
  var deferred = Q.defer();
  var parentCsid = parentData.csid;
  
  if (parentData.fields.computedCurrentLocation === seeChildObjectsLocation) {
    log.info('No relocation needed: ' + parentCsid + " is already located at '" + seeChildObjectsLocationName  + "'");

    deferred.resolve();
  }
  else {
    createSeeChildObjectsMovementRecord()
      .then(function(movementData) {
        log.info("Created '" + seeChildObjectsLocationName + "' movement with csid " + movementData.csid);

        return createRelation(parentCsid, movementData.csid);
      })
      .then(function(relationData) {
        log.info({ createdRelocationRelation: relationData }, 'Relocated parent');

        deferred.resolve();
      })
      .catch(function(error) {
        deferred.reject(error);
      });
  }
  
  return deferred.promise;
}

function createSeeChildObjectsMovementRecord() {
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

function pause() {
  var now = new Date();
  var hour = now.getHours();
  
  if (hoursToSlow.indexOf(hour) > -1) {
    return Q.delay(pauseWhenSlowed);
  }
  else {
    return Q();
  }
}

function checkConnection() {
  var now = Date.now();
  
  if (now - lastConnectTime > connectionTimeout) {
    log.info('Reconnection needed');
    
    return connect();
  }
  else {
    return Q();
  }
}