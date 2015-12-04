+++
title = "arcpy.Project in_memory Featureclass"
date = "2015-09-10"
categories = [
  "arcpy",
  "python"
]
tags = [
  "python",
  "arcpy",
  "gis",
  "esri"
]
description = "Useful workaround for projecting a feature class in_memory using arcpy"
+++

It's inevitable that you eventually run into this error when scripting with arcpy (arcpy.Project_management):
http://help.arcgis.com/en%20/arcgisdesktop/10.0/help/index.html#//00vp0000000m000944.htm

The standard project tool does not support in_memory workspaces.  

Here's the workaround - we just create a new featureclass using the source featureclass as a template and then exploit the spatial_reference parameter of arcpy.da.SearchCursor to project on the fly while inserting into the new featureclass.

```python
from os.path import split

import arcpy

# ....
# assume we've already created this somewhere
source_fc = r"in_memory/source_fc"

# destination featureclass to be created
projected_fc = r"in_memory/projected_source_fc"

# destination projection
web_mercator = arcpy.SpatialReference(102100)

# create destination feature class using the source as a template to establish schema
# and set destination spatial reference
path, name = split(projected_fc)
arcpy.management.CreateFeatureclass(path, name, 'POLYLINE',
                                    template=source_fc,
                                    spatial_reference=web_mercator)

# specify copy of all fields from source to destination
fields = ["Shape@"] + [f.name for f in arcpy.ListFields(source_fc) if not f.required]

# project source geometries on the fly while inserting to destination featureclass
with arcpy.da.SearchCursor(source_fc, fields, spatial_reference=web_mercator) as source_curs, \
     arcpy.da.InsertCursor(projected_fc, fields) as ins_curs:
    for row in source_curs:
      ins_curs.insertRow(row)
```
