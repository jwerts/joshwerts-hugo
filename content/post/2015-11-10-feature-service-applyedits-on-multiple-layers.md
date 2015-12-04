+++
title = "Feature Service applyEdits on Multiple Layers"
date = "2015-11-10T13:09:37-05:00"
categories = [
  "ArcGIS Server", "JavaScript"
]
tags = [
  "arcgis",
  "gis",
  "javascript",
  "REST",
  "esri"
]
description = "Javascript wrapper for applying edits to multiple layers on a feature service in single request to FeatureService REST API endpoint"
+++

If you've worked with any of the esri web API's over the last several years, chances are you've used a Feature Service to edit an SDE feature class at some point.  Using the web API's, the obvious way to do this would be to construct a <a href="https://developers.arcgis.com/javascript/jsapi/featurelayer-amd.html">FeatureLayer</a> and call its <a href="https://developers.arcgis.com/javascript/jsapi/featurelayer-amd.html#applyedits">applyEdits</a> method.  In reality, this is just a wrapper around the ArcGIS Server REST API's applyEdits endpoint on an individual service layer.  

*Example:*

```
http://[host]/arcgis/rest/services/[folder]/[service]/[layerid]/FeatureServer/applyEdits
```

But what happens if you want to applyEdits to multiple layers within the Feature Service instead of just one layer?  You've got a few standard API options after constructing multiple feature layers:

- Call applyEdits on each FeatureLayer with <a href="https://dojotoolkit.org/api/?qs=1.10/dojo/promise/all">dojo/promise/all</a>:

```js
// construct FeatureLayers
flayer1 = new FeatureLayer("http://MyServer/arcgis/rest/services/MyServiceFolder/MyService/0");
flayer2 = new FeatureLayer("http://MyServer/arcgis/rest/services/MyServiceFolder/MyService/1");

// call applyEdits
var deferred1 = flayer.applyEdits(adds1, deletes1, updates1);
var deferred2 = flayer.applyEdits(adds2, deletes2, updates2);

// use dojo/All to respond to success or failure when both operations finish
all([deferred1, deferred2]).then(function(results) {
  // Do something with results.
  // Note that you'll still need to check each edit in each layer for "success"
}, function(error) {
  // uh oh, one of them failed.  
});
```

- Chain promises for each FeatureLayer:

```js
// construct FeatureLayers
flayer1 = new FeatureLayer("http://MyServer/arcgis/rest/services/MyServiceFolder/MyService/0");
flayer2 = new FeatureLayer("http://MyServer/arcgis/rest/services/MyServiceFolder/MyService/1");

// call applyEdits
flayer.applyEdits(adds1, deletes1, updates1).then(function(result1) {
  // do something with result
  // Note that you'll still need to check each edit for "success"
  flayer2.applyEdits(adds2, deletes2, updates2).then(function(result2) {
    // do something with result
    // Note that you'll still need to check each edit for "success"
  }, function(error) {
    // flayer 2 error
  });
}, function(error) {
  // flayer 1 error
});
```

**Either of these options would work, but what if the 2 layer edits depended on each other?**    

Usually when I'm editing multiple layers at once, they have some sort of relation to each other.  This may or may not be defined in the database, but at any rate - if one edit fails, I'd really like the other edit to also fail so we don't end up with an inconsistency in the database.  Additionally, wouldn't it be nice to only send one request to the server, especially when there's many layers?

### One Request to Rule Them All

It turns out that the ArcGIS Server REST API also has an <a href="http://resources.arcgis.com/en/help/rest/apiref/fsserviceedits.html">applyEdits</a> endpoint on the Feature Service itself - it's just not wrapped in the web API's.

This makes it possible to send multiple edits in a single request AND make sure nothing gets stored on any layers if any one of the layer edits fails.

There's nothing in the ESRI web API's that directly hit this endpoint, so I give to you: FeatureService.js.

```
bower install featureservice-esri-jsapi
```

#### Usage:

```js
var package_path = window.location.pathname.substring(0, window.location.pathname.lastIndexOf('/'));
var dojoConfig = {
  async: true,
  packages: [
    {
      name: 'feature-service',
      location: package_path + '/js/lib/bower_components/featureservice-esri-jsapi/dist',
      main: 'FeatureService.min'
    }
  ]
};

require(
  [
    'feature-service'
  ], function(FeatureService) {
    'use strict';

    var service = new FeatureService("http://[server]/arcgis/rest/MyService");
    var edits = [
      {
        id: 2,  // id of layer in service
        adds: [
          addGraphic
        ],
        updates: [
          updateGraphic
        ],
        deletes: [
          1, 2  // just objectids of features to delete.
        ]
      },
      {
        id: 5,  // id of layer in service
        adds: [
          someGraphic,
          anotherGraphic,
          yetAnotherGraphic
        ]
      }
    ];

    var deferred = service.applyEdits(edits);
    deferred.then(function(result) {
      // result is an array
      // each array value contains an object with layer id and objectids of successful edits:
      /*
      [
        {
          id: int id of feature service layer
          adds: [oid, oid, oid, ...],
          updates: [oid, oid oid, ...],
          deletes: [oid, oid, oid, ...]
        },
        ...
      ]
      */
      // layer 2 results
      console.log(result[0].id);
      console.log(result[0].adds);
      console.log(result[0].updates);
      console.log(result[0].deletes);

      // layer 5 results
      console.log(result[1].id);
      console.log(result[1].adds);
      console.log(result[1].updates);
      console.log(result[1].deletes);

    }, function(error) {
      /* error callback can be called for 2 reasons
        1. Regular service faults (server 500 error, etc)
        2. One or more of the edits failed (but server still responded with 200)

        In case 1, the error is a standard esri error object with code and message.
        In case 2, the error is an object with code (200) and message plus an additional
        errors property which contains an array of error objects.
        Error object contains code, description, and id (layer id).
      */
      // case 2
      if (error.code === 200) {
        for (var i; i<error.errors.length; i++) {
          var err = error.errors[i];
          console.log(err.id);
          console.log(err.code);
          console.log(err.description);
        }
      }
    });
});

```

Currently only the applyEdits endpoint is implemented, but this is really the most useful.  There are a couple of personal design decisions here:

- The service always sends rollbackOnFailure as true.  This seems to be the most likely use case.
- If any single edit fails, the fault handler is triggered.  This is different from the jsapi's FeatureLayer, where even if there's a failure, it will still trigger the success handler and you have to check each result for failures.  This class does it for you.

If you find this useful, please leave a comment or feel free to fork!    
https://github.com/jwerts/featureservice-esri-jsapi.git

As a side note, this could have been a separate post on _"Unit testing esri Javascript API services with Karma/Mocha/Chai/Sinon"_.  Perhaps in the future...
