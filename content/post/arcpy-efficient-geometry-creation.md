+++
date = "2016-02-04T15:10:09-05:00"
title = "arcpy: Efficient Geometry Creation"
categories = [
  "python", "arcpy"
]
tags = [
  "python",
  "arcpy",
  "gis",
  "esri"
]
description = "A few tricks to optimize creating a large number of geometries"
draft = false
+++

Sometimes every second counts... and even if it doesn't, it's still interesting to see the quirks of a familiar library.

It turns out that object creation can be somewhat expensive (especially when you're talking about Python --> ArcObjects --> COM).  With arcpy (and underlying ArcObjects), there are some objects which can be reused to gain some efficiency.  

An interesting example is simply creating a polyline from a pair of points.

## Example: Creating a 2 point polyline

### Simplest form:
In its simplest form, you may write:

```python
def create_line_simple(point1_x_and_y, point2_x_and_y, spatial_ref):
    """ creates polyline from pair of (x,y) tuples """
    start_point = arcpy.Point(*point1_x_and_y)
    end_point = arcpy.Point(*point2_x_and_y)
    array = arcpy.Array([start_point, end_point])
    polyline = arcpy.Polyline(array, spatial_ref)
    return polyline

# Usage:
polyline = create_line_simple((-81.60, 36.20), (-81.70, 36.30), arcpy.SpatialReference(4326))
```

There's nothing wrong with this code.  In fact, if you're only creating a few polylines, stop here.  It's readable and gets the job done.

### A little more efficient:

However, if you're creating thousands of polylines, some time can be saved by reusing arcpy.Point objects.

```python
# modules scoped private variables
_start_point = arcpy.Point()
_end_point = arcpy.Point()

def create_line_reuse_points(point1_x_and_y, point2_x_and_y, spatial_ref):
    """ creates polyline from pair of (x,y) tuples """
    _start_point.X, _start_point.Y = point1_x_and_y
    _end_point.X, _end_point.Y = point2_x_and_y
    array = arcpy.Array([_start_point, _end_point])
    polyline = arcpy.Polyline(array, spatial_ref)
    return polyline
```

In this case, we're creating 2 module scoped points only once and then setting the X and Y properties on those points.  The arcpy.Polyline constructor reads X and Y from those points, but it doesn't maintain a reference to the points.  Setting properties on the existing objects is a bit more efficient than creating new objects every time and since references aren't maintained to those objects, we're safe from a memory perspective.

### Even more efficient:

Why not go ahead and reuse the arcpy.Array as well?  Once again, arcpy.Polyline() only reads data from the array and doesn't maintain a reference.  Make sure to removeAll() from array to clean up.

```python
# modules scoped private variables
_start_point = arcpy.Point()
_end_point = arcpy.Point()
_array = arcpy.Array()

def create_line_reuse_points_array(point1_x_and_y, point2_x_and_y, spatial_ref):
    """ creates polyline from pair of (x,y) tuples """
    _start_point.X, _start_point.Y = point1_x_and_y
    _end_point.X, _end_point.Y = point2_x_and_y
    _array.add(_start_point)
    _array.add(_end_point)
    polyline = arcpy.Polyline(_array, spatial_ref)
    _array.removeAll()
    return polyline
```

## How much more efficient is this approach?

Here are the results (in seconds) for creating 100,000 polylines with each function (Python 3.4.1 w/ ArcGIS Pro on Core i7-4712HQ):  

```
Create line simple:
0:00:21.071529

Create line reuse points:
0:00:17.813275

Create line reuse points and array:
0:00:16.277035
```

Is it a huge difference?  Not really.  But if you have a process that creates a large amount of geometries, it's worth considering reusing a few objects.

Here's the full test script to produce the above results:  

```python
import arcpy
from datetime import datetime as dt


def time_me(n):
    """ decorator to print total time to run function n number of times """
    def time_me_decorator(f):
        def wrapper(*args):
            start = dt.now()
            for _ in range(n):
                f(*args)
            print(dt.now() - start)
        return wrapper
    return time_me_decorator


REPETITIONS = 100000

######## Simple Case

@time_me(REPETITIONS)
def create_line_simple(point1_x_and_y, point2_x_and_y, spatial_ref):
    """ creates polyline from pair of (x,y) tuples """
    start_point = arcpy.Point(*point1_x_and_y)
    end_point = arcpy.Point(*point2_x_and_y)
    array = arcpy.Array([start_point, end_point])
    polyline = arcpy.Polyline(array, spatial_ref)
    return polyline


######## Reuses the point objects

# modules scoped private functions
_start_point = arcpy.Point()
_end_point = arcpy.Point()

@time_me(REPETITIONS)
def create_line_reuse_points(point1_x_and_y, point2_x_and_y, spatial_ref):
    """ creates polyline from pair of (x,y) tuples """
    _start_point.X, _start_point.Y = point1_x_and_y
    _end_point.X, _end_point.Y = point2_x_and_y
    array = arcpy.Array([_start_point, _end_point])
    polyline = arcpy.Polyline(array, spatial_ref)
    return polyline


######## Reuses the point and array objects

# modules scoped private functions
_start_point = arcpy.Point()
_end_point = arcpy.Point()
_array = arcpy.Array()

@time_me(REPETITIONS)
def create_line_reuse_points_array(point1_x_and_y, point2_x_and_y, spatial_ref):
    """ creates polyline from pair of (x,y) tuples """
    _start_point.X, _start_point.Y = point1_x_and_y
    _end_point.X, _end_point.Y = point2_x_and_y
    _array.add(_start_point)
    _array.add(_end_point)
    polyline = arcpy.Polyline(_array, spatial_ref)
    _array.removeAll()
    return polyline


# Run our tests
if __name__ == "__main__":
    WGS_84 = arcpy.SpatialReference(4326)
    POINT1 = (-81.674525, 36.216630)
    POINT2 = (-81.675351, 36.213886)

    print("Create line simple:")
    create_line_simple(POINT1, POINT2, WGS_84)
    print("")

    print("Create line reuse points:")
    create_line_reuse_points(POINT1, POINT2, WGS_84)
    print("")

    print("Create line reuse points and array:")
    create_line_reuse_points_array(POINT1, POINT2, WGS_84)
```
