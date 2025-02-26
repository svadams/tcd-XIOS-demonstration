Sampling Offset
------

This example writes a single field to a file at different sampling offsets. The
field values are simply the current timestep to more easily show the behaviour.

The XML field `freq_offset` allows sampling to begin at user specified points in
the simulation. If not specified, the default value of `freq_offset` is
`freq_op - timestep` (i.e. not always zero).

Note: If not set by the user, the default value of `freq_op` varies depending
on the operation:

- **Instant**: `output_freq`
- **Other operations**: `timestep`