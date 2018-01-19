+++
date = "2018-01-16T13:51:36-05:00"
title = "Group by query in a file geodatabase"
description = "How to simulate a SQL group by query in a file geodatabase"
draft = false
categories = [
  "arcpy", "python"
]
tags = [
  "arcgis",
  "gis",
  "python",
  "arcpy",
  "esri",
  "sql"
]
+++

File geodatabase feature classes and tables lack some of the more advanced ability to query that a true relational database supports.  Sometimes these queries can be simulated with arcpy cursors; one good example is a SQL group by query.

**Typical SQL**:
```sql
SELECT field, count(*) from table group by field order by count(*) desc;
```

**In arcpy**:
```python
from collections import Counter

def group_by_count(table_or_fc, fields):
    """ Returns dictionary containing count of unique items """
    counter = Counter()
    with arcpy.da.SearchCursor(table_or_fc, fields) as curs:
        for row in curs:
            # no need to store as a tuple if only 1 field, just store the value
            if len(row) == 1:
                row = row[0]
            counter[row] += 1
    return counter


def group_by_count_formatted(table_or_fc, fields):
    """ prints out counts of unique values """
    counter = group_by_count(table_or_fc, fields)
    # sort yields highest count records first (order by count(*) desc)
    for key, count in sorted(counter.items(), reverse=True, key=lambda item: item[1]):
        print("{}: {:,}".format(str(key), count))
```

**Example usage in ArcMap Python console (single field)**:
```python
>>> group_by_count('junctions', 'ImpedanceType')
Counter({u'SmallStreet': 455145, u'LargeStreet': 28714, u'Stream': 9375, u'RailRoad': 1742})

>>> group_by_count_formatted('junctions', 'ImpedanceType')
SmallStreet: 455,145
LargeStreet: 28,714
Stream: 9,375
RailRoad: 1,742
```

**Example usage in ArcMap Python console (multiple fields)**:
```python
>>> group_by_count('junctions', ['ImpedanceType', 'InfrastructureType'])
Counter({('SmallStreet', 'New'): 318834, ('LargeStreet', 'New'): 28710, ('Stream', 'New'): 18379, ('Stream', 'Aerial'): 5806, ('RailRoad', 'New'): 4043, ('Stream', 'Underground'): 3227, ('RailRoad', 'Aerial'): 1035, ('RailRoad', 'Underground'): 668})

>>> group_by_count_formatted('junctions', ['ImpedanceType', 'InfrastructureType'])
('SmallStreet', 'New'): 318,834
('LargeStreet', 'New'): 28,710
('Stream', 'New'): 18,379
('Stream', 'Aerial'): 5,806
('RailRoad', 'New'): 4,043
('Stream', 'Underground'): 3,227
('RailRoad', 'Aerial'): 1,035
('RailRoad', 'Underground'): 668
```


These functions aren't going to be as efficient as a SQL query, but they can be quite useful sometimes for ad-hoc data exploration - especially in the Arcmap/Pro console.