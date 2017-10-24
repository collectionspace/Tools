/*
 * Utility functions for PAHMA-CSpace.
 */

/*
 * The following four functions, used for generating sortable object numbers, are copied from pahma.js in the CollectionSpace UI layer.
 */

var pad = function(s, len) {
  if (len - s.length + 1 > 0) {
    return (new Array((len - s.length + 1)).join("0")) + s;
  } else {
    return s;
  }
};

var isNumber = function(n) {
  return !isNaN(parseFloat(n)) && isFinite(n);
};

var trim = function(s) {
  var l = 0;
  var r = s.length - 1;
  while (l < s.length && s[l] == ' ') {
    l++;
  }
  while (r > l && s[r] == ' ') {
    r -= 1;
  }
  return s.substring(l, r + 1);
};

var createSortableObjectNumber = function(objnum) {
  var objRe = /^([cC](ons|ONS)?[\-\. ]?)?([A-Z]+)?([\-\. ])?(\d+)([\-\. ])?(\d+)?([\.\- ]+)?(\d+)?([\.\- ]+)?(.*)$/;
  var objTokens = objRe.exec(objnum);
  if (objTokens == null) {
    return objnum;
  } else {
    for (i = 0; i < objTokens.length; i = i + 1) {
      if (!objTokens[i]) {
        objTokens[i] = '';
      } else {
        if (isNumber(objTokens[i])) {
          objTokens[i] = pad(objTokens[i], 6);
        }
      }
      objTokens[i] = objTokens[i] + ' ';
    }
    if (objTokens[3] == ' ') objTokens[3] == ''; // zap empty alphabetic prefix
    return trim(objTokens[3] + objTokens[5] + objTokens[7] + objTokens[9] + objTokens[11]);
  }
};

/*
 * Exports
 */

module.exports = {
  computeSortableObjectNumber: createSortableObjectNumber
};