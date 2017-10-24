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
  port: process.env.CSPACE_PORT,
  ssl: (process.env.CSPACE_SSL === 'true'),
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
  },
  
  loadIterable({items: itemProducer, onItem: itemHandler, stopOnFailedItem}) {
    return new Promise((resolve, reject) => {
      connect()
        .then(() => {
          return getItems(itemProducer);
        })
        .then((items) => {
          return processIterable(items, itemHandler, stopOnFailedItem);
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

function getItems(itemProducer) {
  log.info('Getting items');
  
  if (itemProducer) {
    return itemProducer(cspace);
  }
  
  return Promise.resolve([]);
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

function processIterable(items, itemHandler, stopOnFailedItem) {
  return new Promise((resolve, reject) => {
    let count = 0;
    
    let processor = Q.async(function* () {
      for (let item of items) {
        try {
          yield processItem(item, itemHandler);
        }
        catch(error) {
          if (stopOnFailedItem) {
            log.warn('Stopping processing because of a failed item');
            throw(error);
          }
          else {
            // Log the error, but let processing continue.
            log.warn(error);
          }
        }

        count++;
        
        if (exitRequest) {
          throw exitRequest;
        }
      
        yield checkConnection();
      }
    });
  
    processor()
      .then(() => {
        log.info('Processed ' + count + ' items');
        resolve(count);
      })
      .catch((error) => {
        reject(error);
      });
  });
}

function processItem(item, itemHandler) {
  return new Promise((resolve, reject) => {
    let processor = Q.async(itemHandler);
  
    processor(item, cspace)
      .then(() => {
        resolve();
      })
      .catch((error) => {
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