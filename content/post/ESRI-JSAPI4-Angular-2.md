+++
date = "2016-05-17T20:23:08-04:00"
title = "ESRI Javascript API 4 with Angular 2 and Typescript"
draft = false
description = "Project setup, unit tests setup, and playing around with Angular 2, ESRI JSAPI 4.0 and Typescript"
categories = [
  "Angular", "JavaScript", "JSAPI"
]
tags = [
  "arcgis",
  "gis",
  "javascript",
  "REST",
  "esri",
  "angular",
  "typescript"
]
+++

<strong>Update 1/8/2017: </strong>I've transitioned to Webpack since this post: [link](/blog/2017/01/08/esri-javascript-api-4-with-angular-2---transition-to-webpack/)

This could really be a post about many things.

First, I'm a believer in client-side MV*.  Second, I'm trying to incorporate better testing into my front-end JS code.  Angular seemed like a natural fit given these 2 primary objectives.  I've done a fair amount of work now with Angular 1 and the ESRI JSAPI 3.x library.  There have been some solid success here, but Dojo `require` throughout the app and especially in unit tests have been a major headache.  You could perhaps mock all dependencies from ESRI in the unit tests or try to keep ESRI in it's own untested sandbox, but both of these strategies seems better in theory than practice.

**Aside**: ESRI does not make any of this easy.  Sure, you can get it to work... kind of.... with a lot of headaches along the way.  It all boils down to Dojo.  Don't get me wrong, the ESRI API does some amazing things and some of the new 4.0 features look incredibly promising (`.watch()` is brilliant), but there's really no solid reason why we're still forced to use Dojo.

Anyway, getting to what this post is really about....

## The App

<a href="http://joshwerts.com/jsapi4-angular2" target="_blank" ____>![Full setup](/img/jsapi4ang2_tests_liteserver_app.png)</a>  

[Live Demo](http://joshwerts.com/jsapi4-angular2/)

From a high level view, the app simply adds points to the map and shows a list of those points with their geometry and "index" attribute.  Nothing too special - just there to test some concepts.  As an added bonus, the app is served through lite-server and constantly updates as you code.  Similarly, the unit tests run continuously.

Building upon experimental work by [Rene Rubalcava](https://github.com/odoe/esrijs4-vm-angular2) and [Tom Wayson](https://github.com/tomwayson/angular2-esri-example), I was able to get an Angular 2 app properly loading dojo dependencies both in the browser and in Karma tests.

The app consists of a "model" (Angular service) to hold the points (or domain object of your choosing) - the thought being that business logic in this model would be testable without being concerned about the objects' relation to the map.  Ideally, this model wouldn't contain ESRI dependencies, but with the JSAPI 4's watch capabilities, it seems to make sense to use an `esri/core/Collection` as the underlying data structure in the model.  Also ideally, we'd just have the collection in the model, but it seems the only way to achieve the map automagically updating is if we use the points from a GraphicsLayer (passing in our Collection as the graphics property to the GraphicsLayer constructor worked in 4.0beta3, but not in 4.0 final for some reason).

### PointsModel (points.model.ts)

So here's our PointsModel (in Typescript).  We've simply wrapped a few `Collection` methods and then we can add some additional business logic like `getIndexSum()`.  `index` is just a made up attribute for sake of testing.

```ts
import { Injectable } from '@angular/core';

import Graphic from 'esri/Graphic';
import GraphicsLayer from 'esri/layers/GraphicsLayer';
import Collection from 'esri/core/Collection';

@Injectable()
export class PointsModel {
  private points: Collection = new Collection();
  pointsLayer: GraphicsLayer;
  constructor() {
    this.pointsLayer = new GraphicsLayer();
    this.points = this.pointsLayer.graphics;
  }
  addPoint(pointGraphic: Graphic) {
    this.points.add(pointGraphic);
  }
  addPoints(pointsGraphics: Graphic[]) {
    this.points.addMany(pointsGraphics);
  }
  getPointGraphics() {
    return this.points;
  }
  clear() {
    this.points.removeAll();
  }
  getIndexSum() {
    let sum = 0;
    if (this.points !== null) {
      this.points.forEach(p => sum += p.attributes.index);
    }
    return sum;
  }
}
```

### AttributeComponent (attribute.component.html)
When we add a point to the model, it not only shows up in the map, but also in the attribute list which is wired up through databinding:

```html
<div>
  <h2>Points!</h2>
  <p>Index Sum: {{pointsModel.getIndexSum()}}
  <ul>
    <li *ngFor="let point of points.toArray()">
      <span>{{point.attributes.index}} ({{point.geometry.x | number:'.5-5'}},{{point.geometry.y | number:'.5-5'}})</span>
    </li>
  </ul>
</div>
```

### MapService (map.service.ts)

Our map binding to our PointsModel (which is just a matter of adding pointsModel.pointsLayer (our GraphicsLayer) to the map):
```ts
import { Injectable } from '@angular/core';

import Map from 'esri/Map';
import GraphicsLayer from 'esri/layers/GraphicsLayer';

import { PointsModel } from './points.model';

@Injectable()
export class MapService {
  map: Map;
  pointGraphicsLayer: GraphicsLayer;
  constructor(pointsModel: PointsModel) {
    this.map = new Map({
      basemap: 'topo'
    });
    this.map.add(pointsModel.pointsLayer);
  }
}
```

### PointsModel Tests (points.model.spec.ts)
```ts
import { PointsModel } from './points.model';

import Graphic from 'esri/Graphic';
import Point from 'esri/geometry/Point';

describe('PointsModel tests', () => {
  let mockPointGraphic = new Graphic({
    attributes: {
      index: 1
    },
    geometry: new Point({
      x: 1,
      y: 2,
      spatialReference: {
        wkid: 4326
      }
    })
  });

  let pointsModel;
  beforeEach(() => {
    pointsModel = new PointsModel();
  });

  it('should contstruct it', () => {
    expect(pointsModel).toBeDefined();
    expect(pointsModel.getPointGraphics()).toBeDefined();
  });

  describe('adding and removing points', () => {
    it('should add a point to collection', () => {
       pointsModel.addPoint(mockPointGraphic);
       pointsModel.addPoint(mockPointGraphic);
       expect(pointsModel.getPointGraphics().length).toEqual(2);
    });

    it('should add points to collection', () => {
      pointsModel.addPoints([mockPointGraphic, mockPointGraphic]);
      expect(pointsModel.getPointGraphics().length).toEqual(2);
    });

    it('should clear points', () => {
      pointsModel.addPoint(mockPointGraphic);
      pointsModel.addPoint(mockPointGraphic);
      pointsModel.clear();
      expect(pointsModel.getPointGraphics().length).toEqual(0);
    });
  });

  describe('calculations', () => {
    it('should calculate the sum of the index attributes', () => {
      pointsModel.addPoints([mockPointGraphic, mockPointGraphic]);
      let sum = pointsModel.getIndexSum();
      expect(sum).toEqual(2);
    });
  });

});
```

The nice thing here is that the tests didn't balk at using the esri `Collection` that must be imported into the PointsModel (**this has been an incredibly difficult thing to do w/ Angular 1 / Dojo**).

## Setup

Setup for this is non-trivial and is based heavily on [esri/esri-system-js](https://github.com/Esri/esri-system-js) along with custom configuration in the Karma configuration and loading of dependencies locally using the [esri bower jsapi repo](https://github.com/Esri/arcgis-js-api).  In short, the esri-system-js loader loads **ALL** esri dependencies at the start of the application so they're available through import statements in Typescript files.  This was already figured out for the browser portion by Tom and Rene as referenced previously, so check out their repo's for more information there.

Getting it wired up for testing was a little more difficult but here are the key highlights.  Note that I've broken out some different configs for browser vs tests.

### dojoConfigTest.js

Fairly standard setup for loading from a **local** bower setup.

```js
(function(window) {
  // set up your dojoConfig
  window.dojoConfig = {
    baseUrl: 'app/node_modules/',
    deps: ['app/main'],
    packages: [
      'app',
      'dijit',
      'dojo',
      'dojox',
      'dstore',
      'dgrid',
      'esri', {
        name: 'moment',
        location: 'moment',
        main: 'moment'
      }
    ]
  };
});
```

### karma.conf.js

These are the changes that were added to the karma.conf.js configuration included in the [angular2 quick start repo](https://github.com/angular/quickstart):

```js
  ...

  files: [
    ... angular files, etc.
    // ********* esri load ***********
    // must be able to serve these files for dojo require
    // NOTE: karma gives a cryptic error when 
    // files can't be found  (msg || "").replace is not a function
    { pattern: 'bower_components/dojo/**/*.*', included: false, watched: false },
    { pattern: 'bower_components/dojox/**/*.*', included: false, watched: false },
    { pattern: 'bower_components/dstore/**/*.*', included: false, watched: false },     
    { pattern: 'bower_components/dgrid/**/*.*', included: false, watched: false },
    
    { pattern: 'bower_components/dijit/**/*.*', included: false, watched: false },
    { pattern: 'bower_components/esri/**/*.*', included: false, watched: false },    
    { pattern: 'bower_components/moment/**/*.js', included: false, watched: false },   

    // load dojoConfig so dojo knows where to "require" modules from
    'dojoConfigTest.js',
    
    // we need the actual dojo startup file for "requrire" to be defined
    'bower_components/dojo/dojo.js',
    
    // load in esri's systemJs util
    'node_modules/esri-system-js/dist/esriSystem.js',
    
    // load in our array of esri dependencies
    'esriLoadConfig.js',
    
    // bootstrap in the modules using esri-system-js
    'esriSystemLoadTest.js', 

    ... more angular files
]
```

### esriLoadConfig.js

Contains **ALL** esri modules required by the application:

```js
(function(window) {
  window.esriLoadConfig = {
      modules: [
      'esri/Map',
      'esri/views/MapView',
      'esri/core/Collection',
      'esri/layers/GraphicsLayer',
      'esri/Graphic',
      'esri/geometry/Point',
      'esri/geometry/SpatialReference',
      'esri/symbols/SimpleMarkerSymbol',
      'esri/Color'
    ]
  };
}(window))
```

### esriSystemLoadTest.js

Called by Karma to pre-load the esri modules before the tests run.

```js
// load esri modules needed by this application
// into a System.js module called esri
start = performance.now();
esriSystem.register(esriLoadConfig.modules, function () {
  end = performance.now();
  time = end - start;
  console.log('Loaded esri modules', time / 1000.0);
});
```

### esriSystemLoadBrowser.js

Used in the browser code (called from index.html) to load in the esri modules AND bootstrap the application once those modules are available.

```js
// load esri modules needed by this application
// into a System.js module called esri
console.log("Loading esri modules: ", esriLoadConfig.modules);
start = performance.now();
esriSystem.register(esriLoadConfig.modules, function () {
  // then bootstrap application
  end = performance.now();
  time = end - start;
  console.log('Loaded esri modules', time / 1000.0);
  System.import('app/main').then(function () {
    console.log('app/main imported');
  }, function (error) {
    console.log("System import error:", error);
  });
});
```

## Conclusion

~~This is **highly experimental** and there's **a lot of moving parts**, but it's nice to know this is possible.~~ This is getting closer to production quality.  I've left out a lot but the full repo's here:

https://github.com/jwerts/jsapi4-angular2

There will likely be updates to the repo as I continue to explore this concept (and learn Angular 2... and learn Typescript).

It could really benefit from a final build process.  Note that I've used CDN for most dependencies in index.html for the gh-pages demo to avoid loading local bower and node dependencies to Github.

**Edit 2016-06-16:** Updated Angular to **2.0.0.RC2**  
**Edit 2016-06-24:** Updated Angular to **2.0.0.RC3**  
**Edit 2016-07-05:** Updated Angular to **2.0.0.RC4**  
**Edit 2016-07-07:** Updated to use **esri-system-js 1.0 beta** which now preserves esri module names and works correctly with Typescript arcgis-js-api typings.  
**Edit 2016-09-22:** Updated Angular to **2.0.0 final**