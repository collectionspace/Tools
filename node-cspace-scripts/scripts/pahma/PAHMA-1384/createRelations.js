'use strict';

let loader = require('../../../lib/CollectionSpaceLoader.js');

loader.loadCsv({
  onRow: function* (row, cspace) {
    let [objectNumber1, csid1, csid2, objectNumber2] = row;
  
    let related = yield cspace.findRelated('collectionobject', csid1, 'collectionobject', { pageSize: 0 });
    
    let items = related.items.filter((item) => {
      return (item.csid === csid2);
    });
    
    if (items.length > 0) {
      throw new Error('Collection object ' + csid1 + ' is already related to collection object ' + csid2);
    }

    loader.log.info('Relating collection object ' + csid1 + ' to collection object ' + csid2);
    
    yield cspace.createRecord('relationships', {
      items: [{
        'one-way': false,
        type: 'affects',
        source: {
          csid: csid1,
          recordtype: 'cataloging'
        },
        target: {
          csid: csid2,
          recordtype: 'cataloging'
        }
      }]
    });
  }
});