'use strict';

let loader = require('../../../lib/CollectionSpaceLoader.js');

loader.loadCsv({
  onRow: function* (row, cspace) {
    let [objectNumber, collectionObjectCsid, title] = row;
    
    // Get the collection object.
    
    let record = yield cspace.getRecord('collectionobject', collectionObjectCsid);
    let titleGroups = record.fields.titleGroup;
    let updateRequired = false;
    
    // Check if the title already exists.
    
    let index = titleGroups.findIndex((titleGroup) => {
      return (titleGroup.title === title);
    });
    
    if (index >= 0) {
      loader.log.warn('Collection object ' + collectionObjectCsid + ' already has title: ' + title);
      
      if (index > 0) {
        loader.log.warn('Existing title needs to be moved from position ' + index);
      }
      else {
        let existingTitleGroup = titleGroups[0];
        
        if (!existingTitleGroup.titleType) {
          loader.log.info('Supplying missing type for existing title');
          
          existingTitleGroup.titleType = 'Title';
          updateRequired = true;
        }
        else if (existingTitleGroup.titleType != 'Title') {
          loader.log.warn('Existing title has type: ' + existingTitleGroup.titleType);
        }
      }
    }
    else {
      // Update the title, making the new title the primary.
      
      // First remove any empty title groups.
      
      titleGroups = titleGroups.filter((titleGroup) => {
        return (
          titleGroup.title ||
          (titleGroup.titleTranslationSubGroup && titleGroup.titleTranslationSubGroup[0].titleTranslation)
        );
      });
      
      // Set all remaining title groups to be non-primary.
      
      titleGroups.forEach((titleGroup) => {
        titleGroup._primary = false;
      });
      
      // Prepend the new title, setting it as the primary.
      
      titleGroups.unshift({
        _primary: true,
        title: title,
        titleLanguage: '',
        titleType: 'Title',
        titleTranslationSubGroup: [{
          _primary: true,
          'de-urned-titleTranslationLanguage': 'English',
          titleTranslation: '',
          titleTranslationLanguage: "urn:cspace:pahma.cspace.berkeley.edu:vocabularies:name(languages):item:name(eng)'English'"
        }]
      });
    
      record.fields.titleGroup = titleGroups;
      updateRequired = true;
    }
    
    if (updateRequired) {
      loader.log.info({ titleGroups: record.fields.titleGroup }, 'Updating title for collection object ' + collectionObjectCsid);
      
      yield cspace.updateRecord('collectionobject', collectionObjectCsid, record);

      loader.log.info('Updated collectionobject ' + collectionObjectCsid);
    }
  }
})