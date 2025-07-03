Round to month start
------

This example demonstrates how to dynamically set the frequency offset such that
the XIOS meaning operations apply to each full month. To make it clearer when
output is being performed, the field values are `100 * month + day`. I.e. on
the 14th February, the field value is 214.

The calender is defined in the XML interface while the frequency offset is set
dynamically using the fortran interface.

Note: The start date (set in the XML configuration) defines when the simulation
will begin. Setting the frequency offset changes when output of a field begins.