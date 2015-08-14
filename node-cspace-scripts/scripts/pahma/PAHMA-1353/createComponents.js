/* 
 * See https://issues.collectionspace.org/browse/PAHMA-1353.
 */

var CollectionSpace = require('collectionspace');
var pahma = require('../../../lib/pahma.js');
var Q = require('q');
var fs = require('fs');
var util = require('util');
var csv = require('csv');
var bunyan = require('bunyan');

var log = bunyan.createLogger({ name: 'createComponents' });

var user = process.env.CSPACE_USER;
var password = process.env.CSPACE_PW;
var inputFilePath = process.argv[2]; //'Components_to_create_2015-08-03.csv';

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
    columns: ['componentObjectNumber', 'parentCsid', 'parentObjectNumber']
  });
  
  var transformer = csv.transform(function(row, callback) {
    cspace.getRecord('collectionobject', row.parentCsid)
      .then(function(parentData) {
        return createChildRecord(row.componentObjectNumber, parentData);
      })
      .then(function(childData) {
        log.info({ createdComponent: { componentObjectNumber: row.componentObjectNumber, componentCsid: childData.csid, parentCsid: row.parentCsid } }, 'Created component ' + row.componentObjectNumber + ' with csid ' + childData.csid + ' as child of ' + row.parentCsid);

        return copyRelations(row.parentCsid, childData.csid, ['media', 'acquisition', 'movement']);
      })
      .then(function(relationData) {
        log.info({ createdRelations: relationData }, 'Related ' + relationData.items.length + ' records');

        callback(null);
      })
      .catch(function(error) {
        if (error.message === 'Does not exist (EAPI)') {
          // If the parent record isn't found, warn but allow processing to continue.
          
          log.error('Parent record not found: ' + error.csid);
          
          callback(null);
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

  // The parentData object won't be used again, so don't bother
  // to clone it. Just modify it.
  
  var data = parentData;
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
      });
    
      cspace.createRecord('relationships', { items: relations })
        .then(function(data) {
          deferred.resolve(data);
        })
        .catch(function(error) {
          throw(error);
        })
    })
    .catch(function(error) {
      deferred.reject(error);
    });

  return deferred.promise;
}