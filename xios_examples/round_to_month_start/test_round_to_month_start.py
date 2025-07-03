from typing import List
import netCDF4
import numpy as np
import numpy.testing as npt
import os

import xios_examples.shared_testing as xshared

this_path = os.path.realpath(__file__)
this_dir = os.path.dirname(this_path)

class TestSamplingOffset(xshared._TestCase):
    test_dir = this_dir
    transient_outputs = ["daily_output.nc", "monthly_output.nc"]
    executable = "./timesteps.exe"
    axis_size = 10
    bounds = [[201, 229], [301, 331], [401, 413]]

    def test_field_output(self):
        self.run_mpi_xios()
        self.check_daily_output()
        self.check_monthly_output()

    def check_daily_output(self):
        # Check the expected output file exists
        outputfile = '{}/{}'.format(self.test_dir, "daily_output.nc")
        self.assertTrue(os.path.exists(outputfile))

        rootgrp = netCDF4.Dataset(outputfile, 'r')

        # Test field contains the value sent each timestep (timestep = 1 day)
        expected_values = []
        for start, stop in self.bounds:
            expected_values += np.arange(start, stop + 1).tolist()

        self.check_dataset("daily_output.nc", rootgrp['a_field'], expected_values)

    def check_monthly_output(self):
        # Check the expected output file exists
        outputfile = '{}/{}'.format(self.test_dir, "monthly_output.nc")
        self.assertTrue(os.path.exists(outputfile))

        rootgrp = netCDF4.Dataset(outputfile, 'r')

        # Test field contains the value sent on the first day of each month
        expected_values = []
        for start, stop in self.bounds:
            expected_values += [start]

        self.check_dataset("monthly_output.nc", rootgrp['a_field'], expected_values)

        # Test field contains the average daily value for each full month (i.e. the first two months)
        expected_values = []
        for start, stop in self.bounds[:2]:
            expected_values += [(start + stop) / 2]

        self.check_dataset("monthly_output.nc", rootgrp['monthly_average'], expected_values)

    def check_dataset(self, file: str, dataset: netCDF4.Dataset, expected_values: List[int]):
        # Read data
        result = dataset[:]

        # If 'result' has masked values, we want to remove the masked values to
        # correctly validate the shape of the data
        if result.mask.any():
            result = result.compressed()
            result = np.reshape(result, (-1, self.axis_size))

        # Check dataset has correct number of timesteps and axis size
        timesteps = len(expected_values)
        self.assertEqual(result.shape, (timesteps, self.axis_size))

        # Calculate expected value and diff
        expected = np.repeat([expected_values], self.axis_size, axis=0).T
        diff = result - expected

        # prepare message for failure
        msg = (
            f"{file}[{dataset.name}]: the expected result\n {expected}\n"
            f" differs from the actual result\n {result} \n"
            f" with diff \n {diff}\n"
        )

        npt.assert_allclose(result, expected, rtol=self.rtol, err_msg=msg)
