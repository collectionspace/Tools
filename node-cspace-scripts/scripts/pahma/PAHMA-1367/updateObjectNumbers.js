/* 
 * See https://issues.collectionspace.org/browse/PAHMA-1367.
 */

var CollectionSpace = require('collectionspace');
var pahma = require('../../../lib/pahma.js');
var Q = require('q');
var fs = require('fs');
var util = require('util');
var csv = require('csv');
var bunyan = require('bunyan');

var log = bunyan.createLogger({ name: 'updateObjectNumbers' });
var lastConnectTime = null;
var connectionTimeout = 30 * 60 * 1000; // 30 minutes (in ms)

var user = process.env.CSPACE_USER;
var password = process.env.CSPACE_PW;
var inputFilePath = process.argv[2]; //'objects_to_update.csv';

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
    columns: ['objectNumber', 'sortableObjectNumber', 'csid']
  });
  
  var transformer = csv.transform(function(row, callback) {
    var csid = row.csid;
    var objectNumber = row.objectNumber;
    
    cspace.getRecord('collectionobject', csid)
      .then(function(data) {
        return updateObjectNumber(csid, objectNumber, data);
      })
      .then(function() {
        return checkConnection();
      })
      .then(function() {
        callback();
      })
      .catch(function(error) {
        if (error.message === 'Does not exist (EAPI)') {
          // If the record isn't found, warn but allow processing to continue.
          
          log.error('Record not found: ' + error.csid);
          
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

function updateObjectNumber(csid, expectedObjectNumber, data) {
  var fields = data.fields;
  var objectNumber = fields.objectNumber;
  var suffix = '(0)';
  
  if (objectNumber.slice(-suffix.length) === suffix) {
    log.error('Object number for ' + csid + ' already ends with ' + suffix);
    
    return Q();
  }
  else if (objectNumber !== expectedObjectNumber) {
    log.warn('Unexpected object number for ' + csid + ': expected ' + expectedObjectNumber + ' found ' + objectNumber);
    
    return Q();
  }
  else {
    var newObjectNumber = objectNumber + suffix;
    var newSortableObjectNumber = pahma.computeSortableObjectNumber(newObjectNumber);
    
    fields.objectNumber = newObjectNumber;
    fields.sortableObjectNumber = newSortableObjectNumber;
  
    log.info('Updating object number for ' + csid + ': from ' + objectNumber + ' to ' + newObjectNumber + ' (' + newSortableObjectNumber + ')');
    
    return cspace.updateRecord('collectionobject', csid, {
      fields: fields
    })
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