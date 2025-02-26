Sampling Offset - Metadata
------

This example writes the average of a single field over a 24 hour time period to
two files. In one file the field has no offset, in the second it has an offset
of 12 hours. The field values are simply the current timestep to more easily
show the behaviour.

The generated outputs (variable attributes and data) are compared to
`metadata.cdl` and found to be equal despite the second file specifying an
offset. However, as expected, the `daily_average` variable is different in each
of the files (`test_sampling_offset_time_bounds.py` line 63).

This means you cannot identify from the metadata that an offset was used when
creating the data.

For a demonstration of starting sampling at user specified points in a
simulation, see the [Sampling Offset](../sampling_offset) example.
