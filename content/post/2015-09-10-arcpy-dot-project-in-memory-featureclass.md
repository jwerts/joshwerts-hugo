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
url = "/blog/2015/09/10/arcpy-dot-project-in-memory-featureclass"
+++

It's inevitable that you eventually run into this error when scripting with arcpy (arcpy.Project_management):
http://help.arcgis.com/en%20/arcgisdesktop/10.0/help/index.html#//00vp0000000m000944.htm

The standard project tool does not support in_memory workspaces.  

Here's the workaround - we just create a new featureclass using the source featureclass as a template and then exploit the spatial_reference parameter of arcpy.da.SearchCursor to project on the fly while inserting into the new featureclass.

**Function:**  

```python
from os.path import split
import arcpy

# create destination feature class using the source as a template to establish schema
# and set destination spatial reference
def project(source_fc, out_projected_fc, spatial_reference):
  """ projects source_fc to out_projected_fc using cursors (supports in_memory workspace) """
  path, name = split(out_projected_fc)
  arcpy.management.CreateFeatureclass(path, name,
                                      arcpy.Describe(source_fc).shapeType,
                                      template=source_fc,
                                      spatial_reference=web_mercator)

  # specify copy of all fields from source to destination
  fields = ["Shape@"] + [f.name for f in arcpy.ListFields(source_fc) if not f.required]

  # project source geometries on the fly while inserting to destination featureclass
  with arcpy.da.SearchCursor(source_fc, fields, spatial_reference=spatial_reference) as source_curs, \
       arcpy.da.InsertCursor(out_projected_fc, fields) as ins_curs:
      for row in source_curs:
        ins_curs.insertRow(row)
```

**Usage:**

```python
# assume we've already created this somewhere
source_fc = r"in_memory/source_fc"

# destination featureclass to be created
out_projected_fc = r"in_memory/projected_source_fc"

# destination projection
web_mercator = arcpy.SpatialReference(102100)

project(source_fc, out_projected_fc, web_mercator)
```

**Edit 2016-02-04:** Changed to function per suggestion by [Andy Garfield](https://github.com/andygarfield)
