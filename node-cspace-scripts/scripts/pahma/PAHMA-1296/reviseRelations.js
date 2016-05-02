'use strict';

let loader = require('../../../lib/CollectionSpaceLoader.js');

loader.loadCsv({
  onRow: function* (row, cspace) {
    let [inventoryId, oldCollectionObjectCsid, newCollectionObjectCsid] = row;

    // Confirm that the osteology record exists.
    
    let searchParams = { 
      fields: {
        InventoryIDs: [{
          InventoryID: inventoryId,
          _primary: true
        }]
      },
      operation: 'and'
    };
    
    let searchResults = yield cspace.searchFields('osteology', '', searchParams, { pageSize: 0 });
    
    if (searchResults.results.length === 0) {
      throw new Error('Osteology ' + inventoryId + ' does not exist');
    }
    
    if (searchResults.results.length > 1) {
      throw new Error('Multiple osteologies found with inventory ID ' + inventoryId);
    }
    
    let osteologyCsid = searchResults.results[0].csid;

    loader.log.info('Found osteology ' + osteologyCsid + ' with inventory ID ' + inventoryId);
    
    // Confirm that the osteology record is related to the old collection object.

    let related = yield cspace.findRelated('collectionobject', oldCollectionObjectCsid, 'osteology', { pageSize: 0 });
  
    let items = related.items.filter((item) => {
      return (item.number === inventoryId && item.csid === osteologyCsid);
    });

    if (items.length === 0) {
      throw new Error('Collection object ' + oldCollectionObjectCsid + ' is not related to osteology ' + inventoryId);
    }
    
    // Delete the old relation.
  
    yield cspace.deleteRelation({
      'one-way': false,
      type: 'affects',
      source: {
        csid: oldCollectionObjectCsid,
        recordtype: 'cataloging'
      },
      target: {
        csid: osteologyCsid,
        recordtype: 'osteology'
      }
    });

    loader.log.info('Deleted relation from collection object ' + oldCollectionObjectCsid + ' to osteology ' + osteologyCsid);
      
    // Create the new relation.
  
    yield cspace.createRecord('relationships', {
      items: [{
        'one-way': false,
        type: 'affects',
        source: {
          csid: newCollectionObjectCsid,
          recordtype: 'cataloging'
        },
        target: {
          csid: osteologyCsid,
          recordtype: 'osteology'
        }
      }]
    });

    loader.log.info('Created relation from collection object ' + newCollectionObjectCsid + ' to osteology ' + osteologyCsid);
  }
});