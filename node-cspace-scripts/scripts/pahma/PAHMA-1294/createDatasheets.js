/* 
 * See https://issues.collectionspace.org/browse/PAHMA-1294.
 * 
 * This script works, but is pretty slow, since it has to go through the app layer, and
 * send the binary over HTTP. I used a Talend job instead.
 */

var CollectionSpace = require('collectionspace');
var pahma = require('../../../lib/pahma.js');
var utils = require('../../../lib/utils.js');
var Q = require('q');
var fs = require('fs');
var csv = require('csv');
var bunyan = require('bunyan');
var path = require('path');

var log = bunyan.createLogger({ name: 'createDatasheets' });

var user = process.env.CSPACE_USER;
var password = process.env.CSPACE_PW;
var inputFilePath = process.argv[2]; // 'datasheets_for_cspace_v1.csv';

var imageBasePath = '/Volumes/Images/HSR Scanned Forms';

// var cspace = new CollectionSpace({
//   host: 'localhost',
//   tenant: 'pahma'
// });

var cspace = new CollectionSpace({
  host: 'pahma-dev.cspace.berkeley.edu',
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
    columns: ['collectionObjectCsid', 'objectNumber', 'filename', 'directoryPath']
  });
  
  var transformer = csv.transform(function(row, callback) {
    var collectionObjectCsid = row.collectionObjectCsid;
    var objectNumber = row.objectNumber;
    var filename = row.filename;
    var directoryPath = row.directoryPath;
    
    cspace.getRecord('collectionobject', collectionObjectCsid)
      .then(function(data) {
        return createBlob(directoryPath, filename);
      })
      .then(function(blobData) {
        var blobCsid = blobData.csid;
        
        log.info({ createdBlob: blobCsid }, 'Created blob with csid ' + blobCsid);
        
        return createMedia(objectNumber, blobCsid);
      })
      .then(function(mediaData) {
        var mediaCsid = mediaData.csid;
        
        log.info({ createdMedia: mediaCsid }, 'Created media with csid ' + mediaCsid);
        
        return createRelation(collectionObjectCsid, mediaCsid);
      })
      .then(function(relationData) {
        log.info({ createdRelation: relationData }, 'Created relation');
        
        callback();
      })
      .catch(function(error) {
        if (error.message === 'Does not exist (EAPI)') {
          // If the collection object record isn't found, warn but allow processing to continue.
          
          log.error('Collection object not found: ' + error.csid);
          
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

function createBlob(directoryPath, filename) {
  var pathToFile = path.join(imageBasePath, directoryPath, filename);
  
  log.info('Creating blob from ' + pathToFile);
  
  return cspace.createBlob(pathToFile);
}

function createMedia(identificationNumber, blobCsid) {
  return cspace.createRecord('media', {
    fields: {
      identificationNumber: identificationNumber,
      description: 'HSR datasheet',
      approvedForWeb: false,
      blobCsid: blobCsid,
      title: 'Media record'
    }
  });
}

function createRelation(collectionObjectCsid, mediaCsid) {
  return cspace.createRecord('relationships', {
    items: [{
      'one-way': false,
      type: 'affects',
      source: {
        csid: collectionObjectCsid,
        recordtype: 'cataloging'
      },
      target: {
        csid: mediaCsid,
        recordtype: 'media'
      }
    }]
  });
}