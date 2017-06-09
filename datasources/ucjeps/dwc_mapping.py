# header is ("4solr field", "darwin core field")
dwc_mapping = [
    ("accessionnumber_s", "catalogNumber"),
    ("alllocalities_ss", "tbd"),
    ("associatedtaxa_ss", "associatedTaxa"),
    ("blob_ss", "associatedMedia"),
    ("briefdescription_txt", "dynamicProperties"),
    ("collcountry_s", "country"),
    ("collcounty_s", "county"),
    ("collectioncode", "collectionCode"),
    ("collectiondate_s", "verbatimEventDate"),
    ("collector_ss", "recordedBy"),
    ("collectornumber_s", "recordNumber"),
    ("collectorverbatim_s", "tbd"),
    ("collstate_s", "stateProvince"),
    ("comments_ss", "occurrenceRemarks"),
    ("coordinatesource_s", "georeferenceSources"),
    ("coordinateuncertainty_f", "coordinateUncertaintyInMeters"),
    #("coordinateuncertaintyunit_s", "coordinateUncertaintyInMeters"),
    ("createdat_dt", "tbd"),
    ("csid_s", "occurrenceID"),
    ("cultivated_s", "establishmentMeans"),
    ("datum_s", "geodeticDatum"),
    ("depth_s", "verbatimDepth"),
    #("depthunit_s", "verbatimDepthUnit"),
    ("determination_s", "scientificName"),
    ("determinationdetails_s", "identificationRemarks"),
    ("determinationqualifier_s", "identificationQualifier"),
    ("earlycollectiondate_dt", "eventDate"),
    ("elevation_s", "verbatimElevation"),
    #("elevationunit_s", "verbatimElevationUnit"),
    ("family_s", "family"),
    ("habitat_s", "habitat"),
    ("hastypeassertions_s", "tbd"),
    ("id", "tbd"),
    ("labelfooter_s", "tbd"),
    ("labelheader_s", "tbd"),
    ("latecollectiondate_dt", "eventDate"),
    ("latlong_p", "tbd"),
    ("loannumber_s", "tbd"),
    ("loanstatus_s", "tbd"),
    ("locality_s", "verbatimLocality"),
    ("localitynote_s", "localityRemarks"),
    ("localitysource_s", "tbd"),
    ("localitysourcedetail_s", "georeferenceRemarks"),
    ("localname_s", "vernacularName"),
    ("location_0_coordinate", "decimalLatitude"),
    ("location_1_coordinate", "decimalLongitude"),
    ("majorgroup_s", "tbd"),
    ("maxdepth_s", "tbd"),
    ("maxelevation_s", "tbd"),
    ("mindepth_s", "tbd"),
    ("minelevation_s", "tbd"),
    ("numberofobjects_s", "tbd"),
    ("objectcount_s", "tbd"),
    ("otherlocalities_ss", "tbd"),
    ("othernumber_ss", "otherCatalogNumbers"),
    ("phase_s", "reproductiveCondition"),
    ("posttopublic_s", "tbd"),
    ("previousdeterminations_ss", "previousIdentifications"),
    ("references_ss", "tbd"),
    ("sex_s", "sex"),
    ("sheet_s", "tbd"),
    ("taxonbasionym_s", "originalNameUsage"),
    ("termformatteddisplayname_s", "tbd"),
    ("trscoordinates_s", "tbd"),
    ("typeassertions_ss", "typeStatus"),
    ("ucbgaccessionnumber_s", "tbd"),
    ("updatedat_dt", "modified")
]

id_column = 0
csid_column = 1
accessionnumber_column = 2
determination_column = 3
termformatteddisplayname_column = 4
family_column = 5
taxonbasionym_column = 6
majorgroup_column = 7
collector_column = 8
collectornumber_column = 9
collectiondate_column = 10
earlycollectiondate_column = 11
latecollectiondate_column = 12
locality_column = 13
collcounty_column = 14
collstate_column = 15
collcountry_column = 16
elevation_column = 17
minelevation_column = 18
maxelevation_column = 19
elevationunit_column = 20
habitat_column = 21
location_0_coordinate_column = 22
location_1_coordinate_column = 23
latlong_column = 24
trscoordinates_column = 25
datum_column = 26
coordinatesource_column = 27
coordinateuncertainty_column = 28
coordinateuncertaintyunit_column = 29
localitynote_column = 30
localitysource_column = 31
localitysourcedetail_column = 32
updatedat_dt_column = 33
labelheader_column = 34
labelfooter_column = 35
previousdeterminations_column = 36
localname_column = 37
briefdescription_txt_column = 38
depth_column = 39
mindepth_column = 40
maxdepth_column = 41
depthunit_column = 42
associatedtaxa_column = 43
typeassertions_column = 44
cultivated_column = 45
sex_column = 46
phase_column = 47
othernumber_column = 48
ucbgaccessionnumber_column = 49
determinationdetails_column = 50
loanstatus_column = 51
loannumber_column = 52
collectorverbatim_column = 53
otherlocalities_column = 54
alllocalities_column = 55
hastypeassertions_column = 56
determinationqualifier_column = 57
comments_column = 58
numberofobjects_column = 59
objectcount_column = 60
sheet_column = 61
createdat_dt_column = 62
posttopublic_column = 63
references_column = 64
blob_column = 65
