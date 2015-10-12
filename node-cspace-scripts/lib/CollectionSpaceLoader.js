'use strict';

let CollectionSpace = require('collectionspace');
let Q = require('q');
let fs = require('fs');
let path = require('path');
let csv = require('csv');
let bunyan = require('bunyan');

let log = bunyan.createLogger({ name: path.basename(process.argv[1], '.js') });
let user = process.env.CSPACE_USER;
let password = process.env.CSPACE_PW;
let inputFilePath = process.argv[2];

let lastConnectTime = null;
let connectionTimeout = 30 * 60 * 1000; // 30 minutes (in ms)

let exitRequest = null;

process.on('SIGINT', function() {
  log.info('Received SIGINT');
  
  exitRequest = {
    reason: 'Received SIGINT'
  };
});


let cspace = new CollectionSpace({
  host: process.env.CSPACE_HOST,
  port: '',
  ssl: true,
  tenant: process.env.CSPACE_TENANT
});

module.exports = {
  log: log,
  
  loadCsv({onRow: rowHandler, stopOnFailedRow}) {
    return new Promise((resolve, reject) => {
      connect()
        .then(() => {
          return processInputFile(rowHandler, stopOnFailedRow);
        })
        .then(disconnect)
        .then(finish)
        .then(() => {
          resolve();
        })
        .catch((error) => {
          if (error && (error === exitRequest)) {
            log.info('Exiting by request: ' + error.reason);
            
            resolve();
          }
          else {
            log.error(error);
        
            reject(error);
          }
        });
    });
  }
};

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
  log.info('Loading complete');
  
  return Promise.resolve();
}

function processInputFile(rowHandler, stopOnFailedRow) {
  let input = fs.createReadStream(inputFilePath);

  let parser = csv.parse();

  let transformer = csv.transform((row, callback) => {
    let processRow = Q.async(rowHandler);
    
    processRow(row, cspace)
      .then(
        () => {
          return Promise.resolve();
        },
        (error) => {
          if (stopOnFailedRow) {
            log.warn('Processing will stop because of a failed row');
            return Promise.reject(error);
          }
          
          // Log the error, but let processing continue.
          log.warn(error);
          return Promise.resolve();
        }
      )
      .then(() => {
        if (exitRequest) {
          throw exitRequest;
        }
        
        return checkConnection();
      })
      .then(() => {
        callback();
      })
      .catch((error) => {
        callback(error);
      });
  }, {
    parallel: 1
  });

  input.pipe(parser).pipe(transformer);

  return new Promise((resolve, reject) => {
    transformer.on('finish', () => {
      log.info('Processed ' + transformer.finished + ' rows');
      
      resolve(transformer.finished);
    });

    transformer.on('error', (error) => {
      reject(error);
    });
  });
}

function checkConnection() {
  if (Date.now() - lastConnectTime > connectionTimeout) {
    log.info('Reconnection needed');
    
    return connect();
  }
  
  return Promise.resolve();
}