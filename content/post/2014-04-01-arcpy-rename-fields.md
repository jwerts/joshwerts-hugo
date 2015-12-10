+++
title = "arcpy: Rename Fields"
date = "2014-04-01T07:43:15-04:00"
categories = [
  "python", "arcpy"
]
tags = [
  "python",
  "arcpy",
  "gis",
  "esri"
]
description = "Simple yet powerful function for renaming fields in a feature class with arcpy"
url = "blog/2014/04/01/arcpy-rename-fields/"
+++

In ArcMap 10.2.1, esri finally added a tool to allow renaming of fields (Data Management -> Alter Field).  

![Alter Field](/img/alter_field_tool.png)

This works well for a single field, but you may need something different if:

+ you're still on 10.0/10.1,
+ you want to rename several fields at once,
+ you would prefer not to rename the fields in-place,
+ you need to rename fields in a source unsupported by the Alter Field tool (hint: shapefiles).

Here's a great function for renaming fields (and maintaining their order).  It can be used in the python console.

```python
def rename_fields(table, out_table, new_name_by_old_name):
    """ Renames specified fields in input feature class/table
    :table:                 input table (fc, table, layer, etc)
    :out_table:             output table (fc, table, layer, etc)
    :new_name_by_old_name:  {'old_field_name':'new_field_name',...}
    ->  out_table
    """
    existing_field_names = [field.name for field in arcpy.ListFields(table)]

    field_mappings = arcpy.FieldMappings()
    field_mappings.addTable(table)

    for old_field_name, new_field_name in new_name_by_old_name.iteritems():
        if old_field_name not in existing_field_names:
            message = "Field: {0} not in {1}".format(old_field_name, table)
            raise Exception(message)

        mapping_index = field_mappings.findFieldMapIndex(old_field_name)
        field_map = field_mappings.fieldMappings[mapping_index]
        output_field = field_map.outputField
        output_field.name = new_field_name
        output_field.aliasName = new_field_name
        field_map.outputField = output_field
        field_mappings.replaceFieldMap(mapping_index, field_map)

    # use merge with single input just to use new field_mappings
    arcpy.Merge_management(table, out_table, field_mappings)
    return out_table
```

The function accepts the input feature class, path to output, and a dictionary mapping the old names to the new names:

**Usage:**  

```python
# does need need to include all fields, only those you want to rename
new_name_by_old_name = { 'old_name_1':'new_name_1',
                         'old_name_2':'new_name_2' }
rename_fields(in_fc, renamed_fc, new_name_by_old_name)
```

This works by duplicating the arcpy.FieldMappings object from the existing feature class, renaming the fields within the mapping based on the input, and then calling a function that will apply that mapping.  Merge with a single input gets the job done.  Using the field mappings is a nice trick for efficiently managing fields.
