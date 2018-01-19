+++
date = "2017-01-08T14:21:52-05:00"
title = "ESRI Javascript API 4 with Angular 2 - Transition to Webpack"
draft = false
description = "Project setup, unit tests setup, and playing around with Angular 2, ESRI JSAPI 4.0 and Typescript Part 2 - Transition to Webpack"
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
  "typescript",
  "webpack"
]
+++

Since my [first post](/blog/2016/05/17/esri-javascript-api-4-with-angular-2-and-typescript/) on Angular 2 and the ESRI API, I've transitioned from SystemJS to Webpack which I'm enjoying thoroughly.  

Sample App w/ Webpack setup:  
**[Demo](http://joshwerts.com/angular2-esri-play)**  
**[Repo](https://github.com/jwerts/angular2-esri-play)**  

IMO, Webpack has a few major advantages over SystemJS:

- Development build step is much faster and lite-server does not bog down with memory leaks (not sure why that happened with the SystemJS setup but lite-server got slower and slower until restarted).  
- Webpack takes care of bundling code for you (everything expect the ESRI requires).  
  - This setup also bundles each components' html and css in the main bundle.  
- Feels like less of a hack to use with esri - simply require in each module and that's it.  Setup is simply specifying ESRI as an "external".  Nothing really special there and it just works.  
- No need for a grunt/gulp step to minimize, etc.  Webpack is pretty comprehensive.  

**This app is just a map with a custom coordinate display component (bottom left):** 

![Coordinate component](/img/map_w_coordinates.png)

I've used a similar webpack configuration to this in a couple production apps over the last several months.  Unit testing w/ this setup and Typescript is finally starting to feel natural (instead of a large very verbose burden w/ es5).  I've found it fairly straightfoward to test domain classes and models w/ business logic where I feel you get the most bang for your buck from testing.  What I haven't quite figured out yet is how to test components (and when it's actually worth the effort).  This project contains a working test for the coordinate component...  It works, but I'm not yet convinced it's the best way to go about it.  Please comment if you have experience here!

**Coordinate Component test**:
```ts
import { TestBed, ComponentFixture } from '@angular/core/testing';
import { DebugElement } from '@angular/core';

import { CoordinateComponent } from './coordinate.component';

let fixture: ComponentFixture<CoordinateComponent>;
let component: CoordinateComponent;
let de: DebugElement;
let el: HTMLElement;
let $mapDiv;
let mapDivEl: Element;
beforeEach(() => {
  // refine the test module by declaring the test component
  TestBed.configureTestingModule({
    declarations: [CoordinateComponent]
  });

  // create component and test fixture
  fixture = TestBed.createComponent(CoordinateComponent);
  el = fixture.nativeElement;

  // get test component from the fixture
  component = fixture.componentInstance;

  // add a div to the body
  $mapDiv = $('<div>', { id: 'mapDiv' }).appendTo('body');
  mapDivEl = $mapDiv[0];

  // mock required MapView props/functions
  component.mapView = <any>{
    container: mapDivEl,
    toMap: (point) => {
      return {
        longitude: 5,
        latitude: 10
      };
    },
    zoom: 7,
    scale: 500
  };

  // runs ngOnInit
  fixture.detectChanges();
});

describe('Coordinate', () => {
  it('should update lat/long on mousemove', () => {
    mapDivEl.dispatchEvent(new Event('mousemove', {
      bubbles: true,
      cancelable: true
    }));
    // pageX, pageY
    fixture.detectChanges();
    expect(el.querySelector('#longitude').innerHTML).toBe('5.000000');
    expect(el.querySelector('#latitude').innerHTML).toBe('10.000000');
    expect(el.querySelector('#zoom').innerHTML).toBe('7');
    expect(el.querySelector('#scale').innerHTML).toBe('500');
  });
});
```