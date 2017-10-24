'use strict';

let fs = require('fs');
let path = require('path');
let csv = require('csv');
let bunyan = require('bunyan');
let CollectionSpace = require('collectionspace');
let Q = require('q');

let log = bunyan.createLogger({ name: path.basename(process.argv[1], '.js') });

let cspace = new CollectionSpace({
  host: process.env.CSPACE_HOST,
  port: process.env.CSPACE_PORT,
  ssl: (process.env.CSPACE_SSL === 'true'),
  tenant: process.env.CSPACE_TENANT
});

let user = process.env.CSPACE_USER;
let password = process.env.CSPACE_PW;

/*
 * Path to a CSV file (csid, inventoryId) containing osteology records that originated in cspace, or were modified in cspace since import.
 * 
 * Generated with the following command in psql:
 * 
 * \copy (select h.name, oc.inventoryid
 *        from hierarchy h
 *        left outer join collectionspace_core core on core.id=h.id
 *        left outer join osteology_common oc on oc.id=h.id
 *        where h.primarytype = 'OsteologyTenant15' and core.updatedby <> 'osteo-import@pahma.cspace.berkeley.edu')
 *   to '~/osteo-modified.csv' csv
 */
let modifiedRecordsFilePath = process.argv[2];

/*
 * Path to the CSV file containing osteology data exported from FileMaker, which was used to import osteology records into cspace.
 * This can be found attached to https://issues.collectionspace.org/browse/PAHMA-1292.
 */
let importFilePath = process.argv[3];

let modifiedRecords = new Map();

let radioFields = [
  'Acetabulum_L',
  'Acetabulum_R',
  'Auricular_surf_L',
  'Auricular_surf_R',
  'C1_complete',
  'C1_L_arch',
  'C1_R_arch',
  'C2_centrum',
  'C2_complete',
  'C2_L_arch',
  'C2_R_arch',
  'C3_centrum',
  'C3_complete',
  'C3_L_arch',
  'C3_R_arch',
  'C4_centrum',
  'C4_complete',
  'C4_L_arch',
  'C4_R_arch',
  'C5_centrum',
  'C5_complete',
  'C5_L_arch',
  'C5_R_arch',
  'C6_centrum',
  'C6_complete',
  'C6_L_arch',
  'C6_R_arch',
  'C7_centrum',
  'C7_complete',
  'C7_L_arch',
  'C7_R_arch',
  'Calcaneus_L',
  'Calcaneus_R',
  'Capitate_L',
  'Capitate_R',
  'Carpals_L_complete',
  'Carpals_R_complete',
  'Clavicle_L',
  'Clavicle_R',
  'Coccyx',
  'Coccyx_complete',
  'Cranium',
  'Cuboid_L',
  'Cuboid_R',
  'Ethmoid',
  'Femur_L_complete',
  'Femur_L_JS_D',
  'Femur_L_JS_P',
  'Femur_L_shaft_D',
  'Femur_L_shaft_M',
  'Femur_L_shaft_P',
  'Femur_R_complete',
  'Femur_R_JS_D',
  'Femur_R_JS_P',
  'Femur_R_shaft_D',
  'Femur_R_shaft_M',
  'Femur_R_shaft_P',
  'Fibula_L_complete',
  'Fibula_L_JS_D',
  'Fibula_L_JS_P',
  'Fibula_L_shaft_D',
  'Fibula_L_shaft_M',
  'Fibula_L_shaft_P',
  'Fibula_R_complete',
  'Fibula_R_JS_D',
  'Fibula_R_JS_P',
  'Fibula_R_shaft_D',
  'Fibula_R_shaft_M',
  'Fibula_R_shaft_P',
  'Frontal_L',
  'Frontal_R',
  'Glenoid_L',
  'Glenoid_R',
  'Hamate_L',
  'Hamate_R',
  'Humerus_L_complete',
  'Humerus_L_JS_D',
  'Humerus_L_JS_P',
  'Humerus_L_shaft_D',
  'Humerus_L_shaft_M',
  'Humerus_L_shaft_P',
  'Humerus_R_complete',
  'Humerus_R_JS_D',
  'Humerus_R_JS_P',
  'Humerus_R_shaft_D',
  'Humerus_R_shaft_M',
  'Humerus_R_shaft_P',
  'Hyoid',
  'Ilium_L',
  'Ilium_R',
  'Int_cuneif_2_L',
  'Int_cuneif_2_R',
  'Ischium_L',
  'Ischium_R',
  'L1_centrum',
  'L1_complete',
  'L1_L_arch',
  'L1_R_arch',
  'L2_centrum',
  'L2_complete',
  'L2_L_arch',
  'L2_R_arch',
  'L3_centrum',
  'L3_complete',
  'L3_L_arch',
  'L3_R_arch',
  'L4_centrum',
  'L4_complete',
  'L4_L_arch',
  'L4_R_arch',
  'L5_centrum',
  'L5_complete',
  'L5_L_arch',
  'L5_R_arch',
  'Lacrimal_L',
  'Lacrimal_R',
  'Lat_cuneif_3_L',
  'Lat_cuneif_3_R',
  'Lunate_L',
  'Lunate_R',
  'Mandible_L',
  'Mandible_R',
  'Manubrium',
  'Maxilla_L',
  'Maxilla_R',
  'MC1_L',
  'MC1_R',
  'MC2_L',
  'MC2_R',
  'MC3_L',
  'MC3_R',
  'MC4_L',
  'MC4_R',
  'MC5_L',
  'MC5_R',
  'MC_L_complete',
  'MC_R_complete',
  'Med_cuneif_1_L',
  'Med_cuneif_1_R',
  'MT1_L',
  'MT1_R',
  'MT2_L',
  'MT2_R',
  'MT3_L',
  'MT3_R',
  'MT4_L',
  'MT4_R',
  'MT5_L',
  'MT5_R',
  'MT_L_complete',
  'MT_R_complete',
  'Nasal_L',
  'Nasal_R',
  'Navicular_L',
  'Navicular_R',
  'Occipital',
  'Occipital_L_pars_lateralis',
  'Occipital_pars_basilaris',
  'Occipital_R_pars_lateralis',
  'Orbit_L',
  'Orbit_R',
  'Os_coxae_L',
  'Os_coxae_R',
  'Palatine_L',
  'Palatine_R',
  'Parietal_L',
  'Parietal_R',
  'Patella_L',
  'Patella_R',
  'Pisiform_L',
  'Pisiform_R',
  'Pubis_L',
  'Pubis_R',
  'Radius_L_complete',
  'Radius_L_JS_D',
  'Radius_L_JS_P',
  'Radius_L_shaft_D',
  'Radius_L_shaft_M',
  'Radius_L_shaft_P',
  'Radius_R_complete',
  'Radius_R_JS_D',
  'Radius_R_JS_P',
  'Radius_R_shaft_D',
  'Radius_R_shaft_M',
  'Radius_R_shaft_P',
  'Rib10_L',
  'Rib10_R',
  'Rib11_L',
  'Rib11_R',
  'Rib12_L',
  'Rib12_R',
  'Rib1_L',
  'Rib1_R',
  'Rib2_L',
  'Rib2_R',
  'Rib3_L',
  'Rib3_R',
  'Rib4_L',
  'Rib4_R',
  'Rib5_L',
  'Rib5_R',
  'Rib6_L',
  'Rib6_R',
  'Rib7_L',
  'Rib7_R',
  'Rib8_L',
  'Rib8_R',
  'Rib9_L',
  'Rib9_R',
  'Ribs_L_complete',
  'Ribs_R_complete',
  'S1_centrum',
  'S1_complete',
  'S1_L_ala',
  'S1_R_ala',
  'S2_centrum',
  'S2_complete',
  'S2_L_ala',
  'S2_R_ala',
  'S3_centrum',
  'S3_complete',
  'S3_L_ala',
  'S3_R_ala',
  'S4_centrum',
  'S4_complete',
  'S4_L_ala',
  'S4_R_ala',
  'S5_centrum',
  'S5_complete',
  'S5_L_ala',
  'S5_R_ala',
  'Sacrum',
  'Sacrum_complete',
  'Sacrum_L_alae',
  'Sacrum_R_alae',
  'Scaphoid_L',
  'Scaphoid_R',
  'Scapula_L',
  'Scapula_R',
  'Sphenoid',
  'Sternum',
  'T10_centrum',
  'T10_complete',
  'T10_L_arch',
  'T10_R_arch',
  'T11_centrum',
  'T11_complete',
  'T11_L_arch',
  'T11_R_arch',
  'T12_centrum',
  'T12_complete',
  'T12_L_arch',
  'T12_R_arch',
  'T1_centrum',
  'T1_complete',
  'T1_L_arch',
  'T1_R_arch',
  'T2_centrum',
  'T2_complete',
  'T2_L_arch',
  'T2_R_arch',
  'T3_centrum',
  'T3_complete',
  'T3_L_arch',
  'T3_R_arch',
  'T4_centrum',
  'T4_complete',
  'T4_L_arch',
  'T4_R_arch',
  'T5_centrum',
  'T5_complete',
  'T5_L_arch',
  'T5_R_arch',
  'T6_centrum',
  'T6_complete',
  'T6_L_arch',
  'T6_R_arch',
  'T7_centrum',
  'T7_complete',
  'T7_L_arch',
  'T7_R_arch',
  'T8_centrum',
  'T8_complete',
  'T8_L_arch',
  'T8_R_arch',
  'T9_centrum',
  'T9_complete',
  'T9_L_arch',
  'T9_R_arch',
  'Talus_L',
  'Talus_R',
  'Tarsals_L_complete',
  'Tarsals_R_complete',
  'Temporal_L',
  'Temporal_R',
  'Tibia_L_complete',
  'Tibia_L_JS_D',
  'Tibia_L_JS_P',
  'Tibia_L_shaft_D',
  'Tibia_L_shaft_M',
  'Tibia_L_shaft_P',
  'Tibia_R_complete',
  'Tibia_R_JS_D',
  'Tibia_R_JS_P',
  'Tibia_R_shaft_D',
  'Tibia_R_shaft_M',
  'Tibia_R_shaft_P',
  'Trapezium_L',
  'Trapezium_R',
  'Trapezoid_L',
  'Trapezoid_R',
  'Triquetral_L',
  'Triquetral_R',
  'Ulna_L_complete',
  'Ulna_L_JS_D',
  'Ulna_L_JS_P',
  'Ulna_L_shaft_D',
  'Ulna_L_shaft_M',
  'Ulna_L_shaft_P',
  'Ulna_R_complete',
  'Ulna_R_JS_D',
  'Ulna_R_JS_P',
  'Ulna_R_shaft_D',
  'Ulna_R_shaft_M',
  'Ulna_R_shaft_P',
  'Vertebrae_complete',
  'Vomer',
  'Zygomatic_L',
  'Zygomatic_R'
];


getModifiedRecords()
  .then(getImportedValues)
  .then(getCurrentValues)
  .then(compareValues)
  .then(flipValues)
  .then(() => {
    log.info("Done");
  })
  .catch((error) => {
    log.error(error);
  });

/*
 * Read the csids and inventory ids of osteology records that were created/last modified in cspace,
 * from the supplied CSV file. This populates the modifiedRecords map.
 */
function getModifiedRecords() {
  log.info("Getting modified records");
  
  let input = fs.createReadStream(modifiedRecordsFilePath);

  let parser = csv.parse();

  let transformer = csv.transform((row, callback) => {
    let [csid, inventoryId] = row;
    
    modifiedRecords.set(inventoryId, {
      csid: csid
    });
    
    callback();
  }, {
    parallel: 1
  });

  input.pipe(parser).pipe(transformer);

  return new Promise((resolve, reject) => {
    transformer.on('finish', () => {
      log.info('Found ' + modifiedRecords.size + ' modified osteology records');
      
      resolve(transformer.finished);
    });

    transformer.on('error', (error) => {
      reject(error);
    });
  });
}

/*
 * For each record in the modifiedRecords map, read the values that were loaded from FileMaker,
 * from the supplied CSV. Store these in the importedValues property of the record.
 */
function getImportedValues() {
  log.info("Getting imported values");
  
  let recordCount = modifiedRecords.size;
  let foundCount = 0;
  
  let input = fs.createReadStream(importFilePath);

  let parser = csv.parse({
    columns: true
  });

  let transformer = csv.transform((row, callback) => {
    let inventoryId = row.InventoryID;
    
    if (modifiedRecords.has(inventoryId)) {
      foundCount++;

      let record = modifiedRecords.get(inventoryId);
      record.importedValues = row;
  
      log.info('Found imported values for ' + inventoryId + ' (' + foundCount + '/' + recordCount + ')');
    };
    
    callback();
  }, {
    parallel: 1
  });

  input.pipe(parser).pipe(transformer);

  return new Promise((resolve, reject) => {
    transformer.on('finish', () => {
      /*
       * Check for any records in the modifiedRecords map for which imported values were
       * not found. This means that the record was either created in cspace, or there
       * were no percentage values present in FileMaker.
       */
      
      for (let [inventoryId, record] of modifiedRecords.entries()) {
        if (!record.importedValues) {
          log.warn('Could not find imported values for ' + inventoryId + ', ' + record.csid);
        }
      }
      
      for (let [inventoryId, record] of modifiedRecords.entries()) {
        if (record.importedValues) {
          log.info({ values : record.importedValues }, 'Imported values for ' + inventoryId);
        }
      }
      
      resolve();
    });

    transformer.on('error', (error) => {
      reject(error);
    });
  });
}

/*
 * For each record in the modifiedRecords map, retrieve the current values from
 * cspace. Store these in the currentValues property of the record.
 */
function getCurrentValues() {
  log.info("Getting current values");
  
  let readRecords = Q.async(function*() {
    yield cspace.connect(user, password);
    
    let count = 0;
    
    for (let [inventoryId, record] of modifiedRecords.entries()) {
      count++;
      
      let osteoRecord = yield cspace.getRecord('osteology', record.csid);
      record.currentValues = osteoRecord.fields;

      log.info('Found current values for ' + inventoryId + ' (' + count + ')');
    }
    
    for (let [inventoryId, record] of modifiedRecords.entries()) {
      if (!record.currentValues) {
        log.warn('Could not find current values for ' + inventoryId + ', ' + record.csid);
      }
    }
    
    for (let [inventoryId, record] of modifiedRecords.entries()) {
      if (record.currentValues) {
        log.info({ values : record.currentValues }, 'Current values for ' + inventoryId);
      }
    }    
  });
  
  return readRecords();
}

/*
 * For each record in the modifiedRecords map, check if the imported percentage values
 * were "corrected", i.e. changed to appear correctly in the incorrect UI. If any
 * imported field value was "1", "2a", "2b", or "3", and that field's value is still
 * the same, then the record has most likely not been corrected. If a record does not have
 * imported values, then any percentage values were originally set in the cspace UI, so
 * the record is considered "corrected".
 */
function compareValues() {
  log.info("Comparing values");

  for (let [inventoryId, record] of modifiedRecords.entries()) {
    if (record.importedValues) {
      let imported = record.importedValues;
      
      let current = record.currentValues;
      let uncorrectedValues = {};
      
      for (let fieldName of radioFields) {
        let importedValue = imported[fieldName];

        if (importedValue && importedValue !== '0' && importedValue !== 'C') {
          let currentValue = current[fieldName];
          
          if (currentValue === importedValue) {
            uncorrectedValues[fieldName] = currentValue;
          }
        }
      }
      
      if (Object.keys(uncorrectedValues).length > 0) {
        log.warn({ values : uncorrectedValues }, 'Record appears to be uncorrected: ' + inventoryId + ' (' + record.csid + ') ' + current.updatedBy);
        record.corrected = false;
      }
      else {
        record.corrected = true;
      }
    }  
    else {
      record.corrected = true;
    }
  }
  
  return Promise.resolve();
}

/*
 * For each record in the modifiedRecords map, if the record was "corrected" to appear
 * properly in the incorrect UI, it now has to be updated to appear correctly in the
 * correct UI. The percentage values must be flipped:
 *   1  -> 3
 *   2a -> 2b
 *   2b -> 2a
 *   3  -> 1
 */
function flipValues() {
  log.info("Flipping values");
  
  let doUpdates = Q.async(function*() {
    for (let [inventoryId, record] of modifiedRecords.entries()) {
      if (record.corrected) {
        log.info("Flipping values in " + inventoryId);
      
        let current = record.currentValues;
        let needsUpdate = false;
      
        for (let fieldName of radioFields) {
          let currentValue = current[fieldName];
          let newValue = currentValue;
        
          if (currentValue === '1') {
            newValue = '3';
          } 
          else if (currentValue === '2a') {
            newValue = '2b';
          }
          else if (currentValue === '2b') {
            newValue = '2a';
          }
          else if (currentValue === '3') {
            newValue = '1';
          }
        
          if (newValue !== currentValue) {
            log.info('Changing ' + fieldName + ': ' + currentValue + ' => ' + newValue);
          
            current[fieldName] = newValue;
            needsUpdate = true;
          }
        }

        if (needsUpdate) {
          log.info({ values: record.currentValues }, 'Updating ' + inventoryId + ' (' + record.csid + ')');

          try {
            yield cspace.updateRecord('osteology', record.csid, {
              fields: record.currentValues
            });
          }
          catch(error) {
            log.error({ error: error }, 'Error updating ' + inventoryId + ' (' + record.csid + ')');
          }
        }
        else {
          log.info('No update needed for ' + inventoryId + ' (no flippable values found)');
        }
      }
      else {
        log.info('No update needed for ' + inventoryId + ' (was not corrected in cspace)');
      }
    }
  });
  
  return doUpdates();
}