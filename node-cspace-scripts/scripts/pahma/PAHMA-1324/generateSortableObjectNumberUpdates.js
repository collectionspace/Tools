'use strict';

let fs = require("fs");
let loader = require('../../../lib/CollectionSpaceLoader.js');
let sql = fs.createWriteStream('update.sql');

/*
 * The input CSV should be generated with the following psql command:
 * 
 * \copy (select cc.id, cc.objectnumber, cp.sortableobjectnumber 
 *        from collectionobjects_common cc
 *        left outer join collectionobjects_pahma cp on cc.id=cp.id)
 *   to '~/objectnumbers.csv' csv quote as '"'
 */

loader.loadCsv({
  onRow: function*(row, cspace) {
    let [id, objectNumber, sortableObjectNumber] = row;
  
    let newSortableObjectNumber = computeSortableObjectNumber(objectNumber);
    
    if (newSortableObjectNumber !== sortableObjectNumber) {
      loader.log.info(sortableObjectNumber + " => " + newSortableObjectNumber);
      
      sql.write("UPDATE collectionobjects_pahma SET sortableobjectnumber = '" + sqlEscape(newSortableObjectNumber) + "' WHERE id = '" + id + "' AND (sortableobjectnumber = '" + sqlEscape(sortableObjectNumber) + "'" + (sortableObjectNumber === '' ? " OR sortableobjectnumber IS NULL" : '') + ");\n");
    }
  }
})
.then(() => {
  loader.log.info('Closing SQL file');
  sql.end();
});

function sqlEscape(str) {
  return str.replace("'", "''");
}

function pad(s, len) {
  if (len - s.length + 1 > 0) {
    return (new Array((len - s.length + 1)).join("0")) + s;
  }
  else {
    return s;
  }
};

function isNumber(n) {
  return !isNaN(parseFloat(n)) && isFinite(n);
}

var objectNumberPattern = /^([cC](ons|ONS)?[\-\. ]?)?([A-Za-z]+(-[A-Za-z]+)?)?([\-\. ])?(\d+)([\-\. ])?(\d+)?([\.\- ]+)?(\d+)?([\.\- ]+)?(.*)$/;
//                          1    2                   3         4              5         6    7         8     9          10    11         12

function computeSortableObjectNumber(objectNumber) {
  var sortableObjectNumber = objectNumber;
  var tokens = objectNumberPattern.exec(objectNumber);

  if (tokens) {
    var parts = [tokens[3], tokens[6], tokens[8], tokens[10], tokens[12]]
      .filter(function(token) {
        return token;
      })
      .map(function(token) {
        return (isNumber(token) ? pad(token, 6) : token);
      });

    sortableObjectNumber = parts.join(' ').trim();
  }

  return sortableObjectNumber;
}
