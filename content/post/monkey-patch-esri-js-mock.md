+++
date = "2018-03-23T13:41:03-04:00"
title = "Monkey-patching the ESRI JSAPI to mock services"
description = "Intercepting functions through monkey-patching to mock server calls"
categories = [
  "JavaScript", "JSAPI"
]
tags = [
  "arcgis",
  "gis",
  "javascript",
  "REST",
  "esri"
]
+++

Lately I've been working on a project where I'm unable to access the client's ArcGIS Server services 
directly and don't have the data/environment to publish locally.  Working directly on the server is slow and I wanted a way to mock in a few services just to get started on some UI elements.  There are some online services that help w/ mocking HTTP calls, but I didn't really want to put the data out there in the cloud....

So how about some **monkey-patching**?

### Concept

Here's the basic concept - since nothing is really closed in JavaScript, we can intercept global functions, perform some action and then allow the function to continue as usual.  Here's a simple example - let's say we want to log the url of all XHR requests to the console:

```js
// place this anonymous closure somewhere in your code before any service calls.
// could be in a script tag in index.html for instance.
(function (open) {

  // REPLACE the open function with a new function
  XMLHttpRequest.prototype.open = function (method, url, async, user, password) {

    // log out the url
    console.log('XHR request to: ', url);

    // after we do our work, call the ORIGINAL open function so we continue normally.
    open.apply(this, arguments);
  };

  // pass the ORIGINAL function in as a parameter.
})(XMLHttpRequest.prototype.open);

```

**Example output in Chrome console:**  
![XHR logging in chrome console](/img/xhr_logging.png)

### FeatureLayer (XHR) Example

_Some_ of the JSAPI uses XHR to pass queries.  For instance, this is an example of intercepting and mocking out service calls from a JSAPI 4.6 FeatureLayer.  In this case, we're just checking the URL on each call and changing it to our JSON (which is simply previous ArcGIS Server calls saved out into .json files).  There are 3 steps here based on how ESRI has implemented the FeatureLayer:  

1. When the FeatureLayer is instantiated, a call is made to the endpoint w/ `f=json` to retrieve the service's schema.  
2. At 4.x ESRI performs a `returnCountOnly` call to get the total count of features.  
3. Then, the API tries to iterate through the objectIds with actual query calls to get all of the features, but we're just returning a single response.  There's a major gotcha here:  Make sure ` "exceededTransferLimit": false` is set to `false` in the json or the API will just keep iterating indefinitely trying to get all of the features.  

```js
(function (open) {
  XMLHttpRequest.prototype.open = function (method, url, async, user, password) {
    if (url === 'http://server/arcgis/rest/services/myservice/MapServer/5?f=json') {
      console.log('open', method, url, async, user, password);
      url = 'http://localhost:8080/app/mocks/ags/my_ags_service_info.json';
    }

    if (url.indexOf('http://server/arcgis/rest/services/myservice/MapServer/5/query') > -1) {
      if (url.indexOf('returnCountOnly') > -1) {
        console.log('open', method, url, async, user, password);
        url = 'http://localhost:8080/app/mocks/ags/my_ags_service_5_values_count.json';
      } else {
        console.log('open', method, url, async, user, password);
        url = 'http://localhost:8080/app/mocks/ags/my_ags_service_5_values.json';
      }
    }
    open.apply(this, arguments);
  };
})(XMLHttpRequest.prototype.open);
```

### QueryTask (jsonp) Example

Other parts of the API use jsonp instead of XHR to handle requests so we can't intercept via XMLHttpRequest.  Here's a slightly different approach to handle a `QueryTask.execute` call by patching the class's `execute` function itself.

```js
// NOTE: requires here are with a Webpack setup.
import QueryTask = require('esri/tasks/QueryTask');
import Point = require('esri/geometry/Point');
import FeatureSet = require('esri/tasks/support/FeatureSet');
import esriRequest = require('esri/request');

(function (execute) {
  QueryTask.prototype.execute = function (query, requestOptions?) {
    if (this.url.indexOf('http://server/arcgis/rest/services/myservice/MapServer/5?f=json') > -1) {

      // create a new Promise and do our own call to the local mocked json response.
      return new Promise((resolve, reject) => {
        esriRequest('http://localhost:8080/app/mocks/ags/my_features.json').then(response => {
          let featureSet = new FeatureSet(response.data);

          // In some cases geometries weren't correctly created and needed to fix.
          for (let f of featureSet.features) {
            f.geometry = new Point({
              x: f.geometry.x,
              y: f.geometry.y,
              spatialReference: {
                wkid: 4326
              }
            });
          }
          // resolve the promise with our mocked FeatureSet
          resolve(featureSet);
        }, error => reject(error));
      });
    }
  }
  return execute.apply(this, arguments);
})(QueryTask.prototype.execute);
```

There are probably better ways to accomplish this and I definitely wouldn't suggest doing anything like this for a production app, but it can still be useful in some cases.