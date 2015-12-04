---
layout: post
title: "arcpy.da Cursors and Readability Part 2"
date: 2014-12-21 16:36:33 -0500
comments: true
categories: [python, arcmap, arcpy, gis]
---
arcpy.da cursors provide the simplest data structure by default (tuples).  Python generators provide a pretty neat way of customizing these cursors to increase readability.

### SearchCursor:

__Return ```dict``` instead of tuple:__
```python
def rows_as_dicts(cursor):
  """ returns rows as dicts (does not maintain field order) """
  colnames = cursor.fields
  for row in cursor:
    yield dict(zip(colnames, row))
```

__Usage__ (note the cursor is wrapped with the generator):
```python
total_cost_by_name = {}
with arcpy.da.SearchCursor(costs_table, ["name", "unit_cost", "quantity"]) as curs:
  for row in rows_as_dicts(curs):
    total_cost_by_name[row["name"]] = row["unit_cost"] * row["quantity"]
```

If using with an update cursor, you'll want to use an OrderedDict so the field/value order is maintained.  You'll also need to the use ```dict.values()``` to pass an ordered tuple back into Cursor.updateRow.

### UpdateCursor:

__Return ```collections.OrderedDict``` instead of tuple:__

```python
import collections
def rows_as_ordered_dicts(cursor):
  """ returns rows as collections.OrderedDict """
  colnames = cursor.fields
  for row in cursor:
    yield collections.OrderedDict(zip(colnames, row))
```

__Usage__ (updating):

```python
with arcpy.da.UpdateCursor(costs_table, ["unit_cost", "quantity", "total_cost"]) as curs:
  for row in rows_as_ordered_dicts(curs):
    row["total_cost"] = row["unit_cost"] * row["quantity"]

    # call .values() to convert back to tuple
    # if we didn't use OrderedDict, the values would be in random order.
    curs.updateRow( row.values() )
```
