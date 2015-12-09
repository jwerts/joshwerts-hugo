+++
date = "2015-12-07T19:11:10-05:00"
title = "GP Services: The tool is not valid"
draft = true
categories = [
  "python",
  "arcpy",
  "ArcGIS Server"
]
tags = [
  "python",
  "arcpy",
  "arcgis-server"
]
description = "Causes and solutions for the 'Tool is not valid' error when publishing a GP Service to ArcGIS Server"
+++

**ERROR 000816: The tool is not valid**  

*Dear ESRI, Your framework is not valid.*  

If you attempt to publish any sort of complex Python GP Services, you will almost inevitably run into this error and then proceed to bang your head against your desk and wonder why in the world you can't just get back the actual error.  Your tool works just fine in ArcMap, publishes fine, and then refuses as a service (*Dear ESRI, this publishing workflow is also not valid.*)  It turns out there are *many* causes for this error behind the scenes (which is even more reason why the actual error should be reported back to the user/developer, but unfortunately it's not.  I suppose you could go write some ArcObjects instead.  Bleh.).

This post will attempt to outline some of the causes along with some possible solutions and ways to debug, but first some background...


# Background

It turns out what actually happens when you publish a GP Service is that ESRI scans your Python code looking for dependencies and *attempts* to copy everything that is needed for the scripts to run in the server environment to the service's folder.  For 10.1+ (at least up to 10.3.1), this get placed in folder path which should look something like this for a service called GPService_MyService:  

```
C:\arcgisserver\directories\arcgissystem\arcgisinput\GPService_MyService\extracted\v101\
```  

Here you will find the origin .tbx (or .pyt and derived .tbx) along with any modules that it imports.  

**You can actually edit the Python directly here and just restart the service instead of re-publishing.  Sometimes this is a decent workaround for some of these issues, or at least a good way to investigate what the issue may be.**

This brings me to the first cause of issues:

# Causes and Solutions

## from style imports

When ESRI scans for dependent modules, it only seems to pick up whole modules.  In other words:

*Gets copied in:*  

```python
import my_module
```

*__Doesn't__ get copied in (and results in tool is not valid):*    

```python
from my_module import my_function
```

There's actually an ImportError occuring in the background.  The simple solution is to avoid from style imports.  A more complex solution (with other benefits) would be install all supporting modules as a site-package.


## Site-package installed in 32-bit Python but not in 64-bit Python

Another reason caused by an ImportError:

Let's say you installed the Python <a href="http://docs.python-requests.org/en/latest/">requests></a> library as a site-package in 32-bit Python (used by ArcMap) and your tool depends on this package.  Your tool would run fine in ArcMap but then fail with "the tool is not valid" once it's a GP Service because 64-bit Python utilized by ArcGIS Server would not be able to import requests.

The solution here is to make sure all external site packages are installed in both 32-bit and 64-bit Python.


## Constants  

There may be several reasons for setting a constant path to a file at the top of a .pyt.  A few possible scenarios:  

- There's a configuration file that needs to be read in.
- You're setting constant paths to featureclasses that the service operates on.

ESRI tends to overwrite these constants and set relative paths in various ways or try to copy the actual file into the extracted folder in the case of the configuration file.

Some possible solutions:  

- Make the featureclass a parameter to the tool.  Then when you go to publish, you can change that parameter to a constant value.  This is most likely the ESRI recommended way to go about this, although there are challenges.  What happens if you're not publishing through ArcMap on the server itself?  A UNC path may solve this (Have not tested this personally).
- Change the paths back in the extracted folder and restart the service.
- Add the folder of the data in question to the ArcGIS Server Data Store to try and avoid it being copied to the extracted folder (have had mixed results here).


## Licensing differences between ArcMap and ArcGIS Server

If your tool uses functionality that requires and Advanced license but then you're publishing to ArcGIS Server Standard, then you'll get the error here as well.


## Differences in extensions between ArcMap and ArcGIS Server

If your tool uses an extension (Network Analyst for example) that is available in ArcMap but not in ArcGIS Server, the you'll get the error here as well.


## Custom function tools are not registered for both ArcMap and ArcGIS Server

Just like the 2 reasons above, if a custom tool .dll is registered for 32-bit, it must also be registered for 64-bit (http://support.esri.com/en/knowledgebase/techarticles/detail/40735)


# Deeper dive into debugging

If none of the above causes seem to fit the issue, sometimes you can find the actual error by running the "extracted" .pyt (assuming you're using .pyt) directly from the command line.  Since the service runs as the arcgis local service account, you should try running at this user to rule out any security issues.  To do this, shift-right click on command line or PowerShell in the start menu.  This should give you the option to "Run as different user" in the context menu.  Enter [host]\arcgis and the service account's password.  

Now that you have a command prompt open running under the service account user:

```
cd C:\arcgisserver\directories\arcgissystem\arcgisinput\GPService_MyService\extracted\v101\
c:\python2.7\ArcGISx6410.3\python.exe GPService_MyService.pyt
```

Running this way won't run the actual tool (unless you add code to the ```if __name__ == "__main__":``` block), but it will attempt to import modules at the top of the .pyt and running any code in that context.  This can be pretty helpful for ruling out ImportError type issues or logging issues (for example, you add a file handler to a logger but the arcgis service account doesn't have permissions to create the log file in the directory specified).
