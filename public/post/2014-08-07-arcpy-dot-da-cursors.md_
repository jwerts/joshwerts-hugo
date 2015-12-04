---
layout: post
title: "arcpy.da Cursors and Readability Part 1"
date: 2014-08-07 18:36:54 -0400
comments: true
categories: [python, arcmap, arcpy, gis]
---

The arcpy.da cursors (ie: arcpy.da.SearchCursor) are far and away better than the regular cursors (ie: arcpy.SearchCursor).  They're more pythonic, incredibly flexible, faster, and allow context management (with).  However, their straight-out-of-the-box-use may be a little hard to read and maintain.

### Fun with Tuples

arcpy.da cursors return tuples (instead of objects that feel too much like writing ArcObjects).  

#### Good:

It's perfectly valid to use tuple indexes to access the fields:

```python
total_cost_by_name = {}
with arcpy.da.SearchCursor(costs_table, ["name", "unit_cost", "quantity"]) as curs:
    for row in curs:
        total_cost_by_name[row[0]] = row[1] * row[2]
```

#### Better:

This works fine, but the intent of our calculation is not really clear without some mental mapping.  How about this?
```python
total_cost_by_name = {}
with arcpy.da.SearchCursor(costs_table, ["name", "unit_cost", "quantity"]) as curs:
    for row in curs:
        name = row[0]
        unit_cost = row[1]
        quantity = row[2]

        total_cost_by_name[name] = unit_cost * quantity
```

The intent in the calculation is much more clear here, but we've gained a lot of verbosity that is perhaps unnecessary.  

#### Best:

Of course, you could set the variables all on one line `name, unit_cost, quantity = row[0], row[1], row[2]`, but even better would be to take advantage of python's tuple unpacking:  `name, unit_cost, quantity = row`.  Taking that one step further, why not unpack every tuple as it's iterated over.  Now we have a process that is both concise and highly readable:

```python
total_cost_by_name = {}
with arcpy.da.SearchCursor(costs_table, ["name", "unit_cost", "quantity"]) as curs:
    for name, unit_cost, quantity in curs:
        total_cost_by_name[name] = unit_cost * quantity
```

Now what if we want to update a total cost field in the featureclass using an UpdateCursor instead?

```python
with arcpy.da.UpdateCursor(costs_table, ["unit_cost", "quantity", "total_cost"]) as curs:
    for unit_cost, quantity, total_cost in curs:
        total_cost = unit_cost * quantity
        curs.updateRow( (unit_cost, quantity, total_cost) )
```