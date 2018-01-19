+++
date = "2016-07-21T17:38:05-04:00"
title = "Fun with Python Sets (and arcpy)"
description = "Simple example of using a Python set with DeleteField"
draft = false
categories = [
  "arcpy", "python"
]
tags = [
  "arcgis",
  "gis",
  "python",
  "arcpy",
  "esri"
]
+++

I often forget about the Python `set`, so this is a fun reminder to myself to keep it in mind.  Here's a neat example of using a set for deleting fields.

This function deletes all of the fields *except* the ones you specify:  

```python
def delete_all_fields_except(fc, keep_fields):
    """ deletes all fields except those specfied as keep_fields """ 
    # create set of all possible fields but exclude OBJECTID, SHAPE, etc.
    all_fields = set(f.name for f in arcpy.ListFields(fc) if not f.required)

    # get a list of fields in the featureclass but not in the list of fields to keep
    # using set.difference()
    
    delete_fields = list(all_fields.difference(keep_fields))
    
    # delete out all the fields
    arcpy.management.DeleteField(fc, delete_fields)
```

Usage:
```python
# Assume our feature class has the following fields:
print([f.name for f in arcpy.ListFields(fc)])
# ['OBJECTID', 'Shape', 'field1', 'field2', 'field3', 'field4', 'field5']

keep_fields = ['field1', 'field3']
delete_all_fields_except(fc, keep_fields)

print([f.name for f in arcpy.ListFields(fc)])
# ['OBJECTID', 'Shape', 'field1', 'field3']
```

This is pretty simple example and you could obviously accomplish this without using set, but set is more elegant and more efficient (probably doesn't matter much here).  Perhaps I'll update this post with more advanced usage now that this is here to remind me to think about sets!


