/*
Copyright 2010 

Licensed under the Educational Community License (ECL), Version 2.0. 
You may not use this file except in compliance with this License.

You may obtain a copy of the ECL 2.0 License at
https://source.collectionspace.org/collection-space/LICENSE.txt
*/

/*global jQuery, fluid, cspace:true*/
"use strict";

cspace = cspace || {};

(function ($, fluid) {
    fluid.log("DataSource.js loaded");
    
    
    /**
     * Builds a resourceSpec structure for all additional resources that will need to be fetched.
     */
    var buildResourceSpec = function (that) {
        var sources = that.options.sources;        
        that.resourceSpec = {};
        if (!sources) {
            return;
        }
        for (var key in sources) {
            var source = sources[key];
            if (!source.href) {
                continue;
            }
            that.resourceSpec[key] = {
                href: source.href,
                options: {
                    dataType: "json",
                    error: cspace.util.provideErrorCallback(that, source.href, "errorFetching"),
                    success: function (data) {
                        if (!data) {
                            that.displayErrorMessage(fluid.stringTemplate(that.lookupMessage("emptyResponse"), {
                                url: source.href
                            }));
                            return;
                        }
                        if (data.isError === true) {
                            fluid.each(data.messages, function (message) {
                                that.displayErrorMessage(message);
                            });
                            return;
                        }
                    }
                },
                forceCache: true
            };
        }
    };
    
    var fetchResourcesCallback = function (that) {
        var recordType = that.options.recordType;
        return function (resourceSpec) {
            var model;
            var schema = that.options.schema;
            
            if (resourceSpec[recordType]) {
                model = resourceSpec[recordType].resourceText;
                delete resourceSpec[recordType];
            }
            
            if (schema) {
                // TODO: Need to refactor this somehow.
                var schemaModel = {};
                schemaModel[recordType] = model;
                model = cspace.util.getBeanValue(model ? schemaModel : {}, recordType, schema);
            }
            
            // For all aditional resources the existing model is merged with the data from those resources.
            fluid.each(resourceSpec, function (resource, key) {
                var source = that.options.sources[key];
                var targetModel = {};
                fluid.model.copyModel(targetModel, resource.resourceText);
                targetModel = fluid.model.getBeanValue(targetModel, source.resourcePath);
                fluid.invokeGlobalFunction(source.merge, [targetModel, fluid.model.getBeanValue(model, source.path)]);
                fluid.model.setBeanValue(model, source.path, targetModel);
            });
            
            that.events.afterFetchResources.fire(model);
        };
    };
    
    cspace.dataSource = function (options) {
        var that = fluid.initLittleComponent("cspace.dataSource", options);
        fluid.initDependents(that);
        buildResourceSpec(that);
        
        // Publics method that will either provide a full existing model or create a new model based on 
        // whether csid was provided or not.
        that.provideModel = function (csid) {
            var recordType = that.options.recordType;
            var resourceSpec = fluid.copy(that.resourceSpec);
            if (csid) {
                resourceSpec[recordType] = {
                    href: cspace.util.buildUrl(null, that.options.baseUrl, recordType, csid, that.options.fileExtension),
                    options: {
                        dataType: "json"
                    }
                };
            }
            fluid.fetchResources(resourceSpec, fetchResourcesCallback(that));
        };
        
        // Need events in order to be able to track asynchronous resource fetching. 
        fluid.instantiateFirers(that, that.options);
        return that;
    };
    
    /**
     * Default merge function for lists of rows used in users dataSource.
     * %param target: target structure that will be used as a result value.
     * %param source: source structure that will be used to alter the target structure. 
     */
    cspace.dataSource.mergeRoles = function (target, source) {
        fluid.transform(target, function (item) {
            item.roleId = item.csid;
            item.roleName = item.number;
            item.roleSelected = false;
            delete item.number;
            delete item.csid;
            delete item.summary;
            delete item.recordtype;
            if (source) {
                $.each(source, function (i, value) {
//                    NOTE: Have to compare csid's because roleNames, as
//                    it turns out are inconsistent.
//                    if (item.roleName === value.roleName) {
                    if (item.roleId === value.roleId) {
                        item.roleSelected = true;
                        return false;
                    }
                });
            }
        });
    };
    
    /**
     * Default merge function for lists of permissions used in role dataSource.
     * %param target: target structure that will be used as a result value.
     * %param source: source structure that will be used to alter the target structure. 
     */
    cspace.dataSource.mergePermissions = function (target, source) {
        fluid.transform(target, function (item) {
            item.resourceName = item.summary;
            item.permission = fluid.find(source, function (value) {
                if (item.resourceName === value.resourceName) {
                    return value.permission;
                }
            }) || "delete";
            delete item.summary;
            delete item.number;
            delete item.csid;
            delete item.recordtype;
        });
    };    
    
    fluid.defaults("cspace.dataSource", {
        gradeNames: ["fluid.littleComponent"],
        events: {
            afterFetchResources: null
        },
        mergePolicy: {
            schema: "nomerge"
        },
        invokers: {
            displayErrorMessage: "cspace.util.displayErrorMessage",
            lookupMessage: "cspace.util.lookupMessage"
        },
        recordType: "", // Main record's type, generally inhereted from parent dataContext.
        baseUrl: cspace.componentUrlBuilder("%tenant/%tname"), // Url that will be put in the base path when building main record's fetch url.
        fileExtension: "",
        schema: null, // Schema that will fill the model if necessary.
        sources: null // Structure that describes all additional resources that will be merged with the base model.
    });
    
})(jQuery, fluid);