'use strict'

// Structured date parsing code relies on datejs.
require('datejs');

module.exports = {
  getCollectionSpaceDate: function(date) {
    if (!date) {
      date = new Date();
    }
    
    return (date.getFullYear() + '-' + pad(date.getMonth() + 1) + '-' + pad(date.getDate()));
  },
  
  getEmptyStructuredDate: function() {
    return {
      dateAssociation: '',
      dateDisplayDate: '',
      dateEarliestSingleCertainty: '',
      dateEarliestSingleDay: '',
      dateEarliestSingleEra: '',
      dateEarliestSingleMonth: '',
      dateEarliestSingleQualifier: '',
      dateEarliestSingleQualifierUnit: '',
      dateEarliestSingleQualifierValue: '',
      dateEarliestSingleYear: '',
      dateLatestCertainty: '',
      dateLatestDay: '',
      dateLatestEra: '',
      dateLatestMonth: '',
      dateLatestQualifier: '',
      dateLatestQualifierUnit: '',
      dateLatestQualifierValue: '',
      dateLatestYear: '',
      dateNote: '',
      datePeriod: '',
      scalarValuesComputed: true
    }
  },
  
  /*
   * This function for computing scalar dates is taken from the UI layer and cleaned up a bit.
   */
  computeScalarDates: function(structuredDate) {
    let eYear = structuredDate.dateEarliestSingleYear;
    let eMonth = structuredDate.dateEarliestSingleMonth;
    let eDay = structuredDate.dateEarliestSingleDay;

    let lYear = structuredDate.dateLatestYear;
    let lMonth = structuredDate.dateLatestMonth;
    let lDay = structuredDate.dateLatestDay;

    let eScalarDate = null;
    let lScalarDate = null;

    if (eYear || lYear) {
      try {
          eScalarDate = setScalarDate(eYear, eMonth, eDay, lYear, lMonth, lDay, true);
          lScalarDate = setScalarDate(eYear, eMonth, eDay, lYear, lMonth, lDay, false);
        
          lScalarDate = lScalarDate.add({ days: 1 });
      }
      catch(error) {
        //console.log(error);
      }
    }
    
    structuredDate.dateEarliestScalarValue = eScalarDate.toString('yyyy-MM-dd');
    structuredDate.dateLatestScalarValue = lScalarDate.toString('yyyy-MM-dd');
  }  
};

function pad(number) {
  if (number < 10) {
    return '0' + number;
  }
  return number;
}

/*
 * The following code for computing scalar dates is taken out of the UI layer.
 */

function setScalarDate(eYear, eMonth, eDay, lYear, lMonth, lDay, earliest) {
    var firstYear = eYear, secondYear = lYear,
        firstMonth = eMonth, secondMonth = lMonth,
        firstDay = eDay, secondDay = lDay;
    
    if (!earliest) {
        firstYear = lYear;
        firstMonth = lMonth;
        firstDay = lDay;
        secondYear = eYear;
        secondMonth = eMonth;
        secondDay = eDay;
    }
    
    return firstYear ? setDate(firstYear, firstMonth, firstDay, earliest) :
                       setDate(secondYear, firstMonth || secondMonth, firstDay || secondDay, earliest);
}

function setDate(year, month, day, earliest) {
    var date = setDateYear(year);
    setDateMonth(date, month, earliest);
    setDateDay(date, day, earliest);
    return date;
}

function validate(value, field) {
    var parsed = parseInt(value, 10),
        month = arguments[2],
        year = arguments[3];

    if (field === "Month") {
        parsed -= 1;
    }
    if (!Date["validate" + field](parsed, year, month)) {
        throw "Invalid " + field;
    }
    return parsed;
}

function setDateYear(year) {
    var parsedYear = validate(year, "Year");
    var date = new Date();
    return date.set({year: parsedYear});
};

function setDateMonth(date, month, earliest) {
    var opts = {};
    if (!month) {
        opts.month = earliest ? 0 : 11;
    } else {
        opts.month = validate(month, "Month");
    }
    return date.set(opts);
}

function setDateDay(date, day, earliest) {
    var opts = {};
    if (!day) {
        opts.day = earliest ? 1 : Date.getDaysInMonth(date.getYear(), date.getMonth());
    } else {
        opts.day = validate(day, "Day", date.getYear(), date.getMonth());
    }
    return date.set(opts);
}


