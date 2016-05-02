/* 
 * See https://issues.collectionspace.org/browse/PAHMA-1296.
 */

'use strict';

let Q = require('q');
let CollectionSpace = require('collectionspace');
let fs = require('fs');
let csv = require('csv');
let bunyan = require('bunyan');
let utils = require('../../../lib/utils.js')

let log = bunyan.createLogger({ name: 'loadAgeEstimates' });
let user = process.env.CSPACE_USER;
let password = process.env.CSPACE_PW;
let inputFilePath = process.argv[2];
let estimates = new Map();

let lastConnectTime = null;
let connectionTimeout = 30 * 60 * 1000; // 30 minutes (in ms)

let exitRequested = false;

process.on('SIGINT', function() {
  log.info('Received SIGINT');
  
  exitRequested = true;
});

let cspace = new CollectionSpace({
  host: process.env.CSPACE_HOST,
  port: '',
  ssl: true,
  tenant: process.env.CSPACE_TENANT
});

connect()
  .then(readInputFile)
  .then(processEstimates)
  .then(disconnect)
  .then(finish)
  .catch((error) => {
    log.error(error);
  });

function connect() {
  log.info('Connecting to CollectionSpace at ' + cspace.getUrl());

  lastConnectTime = Date.now();

  return cspace.connect(user, password);
}

function disconnect() {
  log.info('Disconnecting');

  return cspace.disconnect();
}

function finish() {
  log.info('Done');
}

function readInputFile() {
  let input = fs.createReadStream(inputFilePath);

  let parser = csv.parse({
    columns: ['collectionObjectCsid', 'pos', 'ageVerbatim', 'ageLower', 'ageUpper', 'date', 'note', 'analyst', 'estimateId', 'inventoryId']
  });

  let transformer = csv.transform((row, callback) => {
    if (validateInput(row)) {
      let collectionObjectCsid = row.collectionObjectCsid;
      let inventoryId = row.inventoryId;
      let pos = parseInt(row.pos);

      let estimatesByInventoryId = estimates.get(collectionObjectCsid);
    
      if (!estimatesByInventoryId) {
        estimatesByInventoryId = new Map();
        estimates.set(collectionObjectCsid, estimatesByInventoryId);
      }
      
      let estimatesByPos = estimatesByInventoryId.get(inventoryId);
      
      if (!estimatesByPos) {
        estimatesByPos = new Map();
        estimatesByInventoryId.set(inventoryId, estimatesByPos);
      }
      
      if (estimatesByPos.has(pos)) {
        log.warn({ row : row, existing: estimatesByPos.get(pos) }, 'Found duplicate pos');
      }
      
      estimatesByPos.set(pos, row);
    }
    
    callback();
  }, {
    parallel: 1
  });

  input.pipe(parser).pipe(transformer);

  return new Promise((resolve, reject) => {
    transformer.on('finish', () => {
      let osteoCount = 0;
      
      for (let [collectionObjectCsid, estimatesByInventoryId] of estimates) {
        osteoCount += estimatesByInventoryId.size;
      }

      log.info('Read ' + transformer.finished + ' rows with ' + osteoCount + ' osteology records');
      
      resolve(transformer.finished);
    });

    transformer.on('error', (error) => {
      reject(error);
    });
  });
}

function processEstimates() {
  return new Promise((resolve, reject) => {
    let processor = Q.async(function* () {
      log.info('Processing estimates');

      for (let [collectionObjectCsid, estimatesByInventoryId] of estimates) {
        for (let [inventoryId, estimatesByPos] of estimatesByInventoryId) {
          yield loadEstimates(collectionObjectCsid, inventoryId, estimatesByPos);
        }
        
        if (exitRequested) {
          log.info('Exiting by request');
          break;
        }
        
        yield checkConnection();
      }
    });
  
    processor()
      .then(() => {
        log.info('Processing done');
        resolve();
      })
      .catch((error) => {
        reject(error);
      });
  });
}

function loadEstimates(collectionObjectCsid, inventoryId, estimatesByPos) {
  log.info('Loading estimates for inventory ' + inventoryId);

  return new Promise((resolve, reject) => {
    cspace.findRelated('collectionobject', collectionObjectCsid, 'osteology', { pageSize: 0 })
      .then((related) => {
        let items = related.items.filter((item) => {
          return (item.number === inventoryId);
        });
        
        if (items.length > 1) {
          throw new Error('CollectionObject ' + collectionObjectCsid + ' has more than one related inventory with id ' + inventoryId);
        }
        
        if (items.length === 0) {
          return createOsteology(collectionObjectCsid, inventoryId, estimatesByPos);
        }
        else {
          let item = items[0];
          let osteologyCsid = item.csid;
          
          return updateOsteology(osteologyCsid, estimatesByPos);
        }
      })
      .then(() => {
         resolve();
      })
      .catch((error) => {
        log.error(error);
        
        resolve();
      });
  });
}

function createOsteology(collectionObjectCsid, inventoryId, estimatesByPos) {
  return new Promise((resolve, reject) => {
    log.info('Creating osteology ' + inventoryId + ' for collectionobject ' + collectionObjectCsid);
    
    // Make sure there isn't already an osteology record with the inventory id.
    
    let searchParams = { 
      fields: {
        InventoryIDs: [{
          InventoryID: inventoryId,
          _primary: true
        }]
      },
      operation: 'and'
    };
    
    let searchOptions = {
      pageSize: 1
    };
      
    cspace.searchFields('osteology', '', searchParams, searchOptions)
      .then((searchResults) => {
        if (searchResults.results.length > 0) {
          throw new Error('Osteology ' + inventoryId + ' already exists with csid ' + searchResults.results[0].csid);
        }
        
        return createOsteoAgeEstimateGroups(estimatesByPos);
      })
      .then((osteoAgeEstimateGroups) => {
        log.info({ osteoAgeEstimateGroups : osteoAgeEstimateGroups }, 'Created age estimate groups');

        return cspace.createRecord('osteology', {
          fields: {
            InventoryID: inventoryId,
            osteoAgeEstimateGroup: osteoAgeEstimateGroups
          }
        });
      })
      .then((osteologyRecord) => {
        log.info('Created osteology ' + osteologyRecord.csid);

        return cspace.createRecord('relationships', {
          items: [{
            'one-way': false,
            type: 'affects',
            source: {
              csid: collectionObjectCsid,
              recordtype: 'cataloging'
            },
            target: {
              csid: osteologyRecord.csid,
              recordtype: 'osteology'
            }
          }]
        });
      })
      .then((relations) => {
        log.info({ relations: relations }, 'Created relations');

        resolve();
      })
      .catch((error) => {
        reject(error);
      });
  });
}

function updateOsteology(osteologyCsid, estimatesByPos) {
  return new Promise((resolve, reject) => {
    log.info('Updating osteology ' + osteologyCsid);
    
    let osteologyRecord = null;
    
    cspace.getRecord('osteology', osteologyCsid)
      .then((record) => {
        let existingOsteoAgeEstimateGroups = record.fields.osteoAgeEstimateGroup.filter((estimateGroup) => {
          return (
            estimateGroup.osteoAgeEstimateLower || 
            estimateGroup.osteoAgeEstimateUpper || 
            estimateGroup.osteoAgeEstimateAnalyst || 
            estimateGroup.osteoAgeEstimateNote ||
            (estimateGroup.osteoAgeEstimateDateGroup && estimateGroup.osteoAgeEstimateDateGroup.dateDisplayDate));
        });
        
        if (existingOsteoAgeEstimateGroups.length > 0) {
          throw new Error('Osteology ' + osteologyCsid + ' already has age estimates');
        }
        
        osteologyRecord = record;
        
        return createOsteoAgeEstimateGroups(estimatesByPos);
      })
      .then((osteoAgeEstimateGroups) => {
        log.info({ osteoAgeEstimateGroups : osteoAgeEstimateGroups }, 'Created age estimate groups');
        
        osteologyRecord.fields.osteoAgeEstimateGroup = osteoAgeEstimateGroups;
        
        return cspace.updateRecord('osteology', osteologyCsid, osteologyRecord);
      })
      .then(() => {
        log.info('Updated osteology ' + osteologyCsid);

        resolve();
      })
      .catch((error) => {
        reject(error);
      })
  });
}

function createOsteoAgeEstimateGroups(estimatesByPos) {
  return new Promise((resolve, reject) => {
    let positions = Array.from(estimatesByPos.keys()).sort();
    let estimates = [];
    
    for (let position of positions) {
      estimates.push(estimatesByPos.get(position));
    }
    
    let parseDateQueries = estimates.map((estimate) => {
      return cspace.parseStructuredDate(estimate.date);
    });

    Promise.all(parseDateQueries)
      .then((parseResults) => {
        let structuredDates = parseResults.map((parseResult) => {
          var structuredDate = null;
          
          if (parseResult) {
            structuredDate = parseResult.structuredDate;
            utils.computeScalarDates(structuredDate);
          }
          else {
            structuredDate = utils.getEmptyStructuredDate();
          }
          
          return structuredDate;
        });
        
        let osteoAgeEstimateGroups = estimates.map((estimate, index) => {
          return {
            _primary: (index === 0),
            osteoAgeEstimateLower: estimate.ageLower,
            osteoAgeEstimateUpper: estimate.ageUpper,
            osteoAgeEstimateDateGroup: structuredDates[index],
            osteoAgeEstimateAnalyst: estimate.analyst,
            osteoAgeEstimateNote: estimate.note
          };
        });
        
        resolve(osteoAgeEstimateGroups);
      })
      .catch((error) => {
        reject(error);
      });
  });
}

function validateInput(row) {
  let isValid = true;
  
  if (!row.collectionObjectCsid) {
    log.warn({ row: row }, 'Found missing collectionObjectCsid');
    isValid = false;
  }
  
  if (!row.inventoryId) {
    log.warn({ row: row }, 'Found missing inventoryId');
    isValid = false;
  }
  
  if (isNaN(parseInt(row.pos))) {
    log.warn({ row: row }, 'Found invalid pos');
    isValid = false;
  }
  
  return isValid;
}

function checkConnection() {
  let now = Date.now();
  
  if (now - lastConnectTime > connectionTimeout) {
    log.info('Reconnection needed');
    
    return connect();
  }
  else {
    return Q();
  }
}