---
layout: post
title: "Debugging Server Object Extensions (SOEs) in Style"
date: 2015-04-12 17:09:42 -0400
comments: true
categories: ["ArcObjects", "python", "requests", "ArcGIS Server"]
---
Server Object Extensions (SOEs) can be incredibly powerful, but they can also be a pain to debug.

#### Typical workflow:  
1. Rebuild solution  
2. Open ArcGIS Manager in browser -> Site -> Extensions -> Update Extension by selecting .soe file.
3. Restart all of the services that depended on the SOE.  
4. Attach Visual Studio to process.  

Steps 2 & 3 are the really annoying ones, but they can be automated!

It turns out this is really a post about REST and Python.

When you update an SOE through the ArcGIS Manager app (http://localhost/arcgis/manager), the web application is actually making calls to ArcGIS Server REST admin endpoints.

### Automate with Python

I'll cut to the chase.  

**See the full script here:**  
https://github.com/jwerts/soe-updater

Usage (simply run from command line after rebuilding SOE solution):
```
C:\Projects\_General\_Code\soe-updater>python update_soe.py

Retrieving token...
Retrieved: oUK04q-J8ORWDUrSWGPfq8zAU29u3q5_YZ79ZvcFZx8kFneOMb5Z2Y2Yf19
Uploading SOE...
Uploaded: ibd792bae-a986-4861-8ac3-c16d42f4d610
Updating SOE...
Updated!
Starting services...
Starting service_folder/service.MapServer
Started!
```

Your SOE will be updated and services restarted.  You can re-attach to the service processes or if you're using ```System.Diagnostics.Debugger.Launch();``` in your ```Init()``` function, you'll automatically be greeted with the dialog to attach your process once the script finishes and the services restart.

<br/><br/>
Now a little explanation of what's going on...

### REST API Calls

#### Generate token
Because we're going to automate this, we need a preliminary step.  We'll generate a token that can be passed to subsequent steps.
```
http://localhost/arcgis/rest/tokens
```

#### Upload the SOE
The .soe file that gets generated after building in Visual Studio is uploaded to ArcGIS Server and returns an itemID.
```
http://localhost/arcgis/admin/uploads/upload
```

#### Update the SOE
Another call references the uploaded .soe through the itemID and updates the extension.
```
http://localhost/arcgis/admin/services/types/extensions/update
```

#### Restart services
After the SOE is updated, all services that use it are stopped and must be restarted.  This can also be accomplished through REST calls:
```
http://localhost/arcgis/admin/services/[service_folder]/[service_name]/start
```

These calls are all pretty straightford to automate in a Python script using the requests library (http://docs.python-requests.org/en/latest/).
