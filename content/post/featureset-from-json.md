+++
date = "2016-10-14T10:07:44-04:00"
title = "FeatureClass from JSON"
description = "How to create a FeatureSet/FeatureClass from JSON (in memory)"
categories = [
  "python", "arcpy"
]
tags = [
  "python",
  "arcpy",
  "gis",
  "esri"
]
+++
I keep forgetting how to do this after several months pass by and it's certainly not obvious...  

ESRI provides a tool for converting JSON to FeatureClass but it requires reading the JSON from a .json file: [JSON to Features](http://pro.arcgis.com/en/pro-app/tool-reference/conversion/json-to-features.htm).  That extra step of writing out and reading from a file just seems completely unnecessary.  

Here's the alternative lesser known and not obvious way to do it:

```python
valid_featureset_json = \
"""{
    "displayFieldName": "",
    "fieldAliases": {
        "OBJECTID": "OBJECTID",
        "Description": "Description"
    },
    "geometryType": "esriGeometryPoint",
    "spatialReference": {
        "wkid": 4326,
        "latestWkid": 4326
    },
    "fields": [
        {
            "name": "OBJECTID",
            "type": "esriFieldTypeOID",
            "alias": "OBJECTID"
        },
        {
            "name": "Description",
            "type": "esriFieldTypeString",
            "alias": "Description",
            "length": 50
        }
    ],
    "features": [
        {
            "attributes": {
                "OBJECTID": 1,
                "Description": "This is a test feature."
            },
            "geometry": {
                "x": -123.80816799999991,
                "y": 39.40451500000006
            }
        },
        {
            "attributes": {
                "OBJECTID": 2,
                "Description": "This is aanother test feature."
            },
            "geometry": {
                "x": -123.80816839299996,
                "y": 39.404514814000095
            }
        }
    ]
}"""

# convert to RecordSet object (should be able to use this most places FeatureSet would be called for)
record_set = arcpy.AsShape(valid_featureset_json, True)

# If you need a FeatureClass, just copy into one
output_fc = r'in_memory\\output_fc'
arcpy.management.CopyFeatures(record_set, output_fc)
```

And that's it!  No need to write the json to file.
