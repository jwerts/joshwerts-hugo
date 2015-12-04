+++
title = "arcpy: Reorder Fields"
date = "2014-04-17"
categories = [
  "python",
  "arcpy"
]
tags = [
  "python",
  "arcgis",
  "esri",
  "arcpy",
  "gis"
]
description = "Reorder fields in a feature class with arcpy"
+++

Here's another handy function for re-ordering fields in a feature class.  Like the ```rename_fields``` function previously posted, it recreates the existing field mappings and modifies as necessary.  The output is a new feature class with fields in the order specified.  

The only caveat is that required fields always get pushed to the front (so the featureclass will start with OBJECTID, Shape, rest of fields...).  After required fields are out of the way, the rest of the fields are added in the order specified in the ```field_order``` list.  If any fields are missing, they are added to the end of the feature class.

```python
import arcpy

def reorder_fields(table, out_table, field_order, add_missing=True):
    """
    Reorders fields in input featureclass/table
    :table:         input table (fc, table, layer, etc)
    :out_table:     output table (fc, table, layer, etc)
    :field_order:   order of fields (objectid, shape not necessary)
    :add_missing:   add missing fields to end if True (leave out if False)
    -> path to output table
    """
    existing_fields = arcpy.ListFields(table)
    existing_field_names = [field.name for field in existing_fields]

    existing_mapping = arcpy.FieldMappings()
    existing_mapping.addTable(table)

    new_mapping = arcpy.FieldMappings()

    def add_mapping(field_name):
        mapping_index = existing_mapping.findFieldMapIndex(field_name)

        # required fields (OBJECTID, etc) will not be in existing mappings
        # they are added automatically
        if mapping_index != -1:
            field_map = existing_mapping.fieldMappings[mapping_index]
            new_mapping.addFieldMap(field_map)

    # add user fields from field_order
    for field_name in field_order:
        if field_name not in existing_field_names:
            raise Exception("Field: {0} not in {1}".format(field_name, table))

        add_mapping(field_name)

    # add missing fields at end
    if add_missing:
        missing_fields = [f for f in existing_field_names if f not in field_order]
        for field_name in missing_fields:
            add_mapping(field_name)

    # use merge with single input just to use new field_mappings
    arcpy.Merge_management(table, out_table, new_mapping)
    return out_table
```

**Usage:**    

```python
new_field_order = ["field2", "field3", "field1"]
reorder_fields(in_fc, out_fc, new_field_order)
```

I've tested this in 10.1.1+ - it may work in 10.0 as well and should work with any license level.
