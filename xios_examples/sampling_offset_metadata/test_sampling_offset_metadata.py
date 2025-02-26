from pathlib import Path
import subprocess
import netCDF4
import numpy as np
import numpy.testing as npt
import os

import xios_examples.shared_testing as xshared

this_path = os.path.realpath(__file__)
this_dir = os.path.dirname(this_path)

class TestSamplingOffsetMetadata(xshared._TestCase):
    test_dir = this_dir
    transient_outputs = ["metadata.nc", "daily_average.nc", "shifted_daily_average.nc"]
    executable = "./timesteps.exe"
    axis_size = 10

    def test_sampling_offset_metadata(self):
        self.run_mpi_xios()

        # Generate metadata netCDF file
        comparison_file = Path(self.test_dir, self.transient_outputs[0])
        subprocess.run(
            ["ncgen", "-k", "nc4", "-o", comparison_file, comparison_file.with_suffix(".cdl")],
            cwd=self.test_dir,
            check=True,
        )

        # Check the output files exist
        daily_average_file = Path(self.test_dir, self.transient_outputs[1])
        shifted_daily_average_file = Path(self.test_dir, self.transient_outputs[2])

        self.assertTrue(daily_average_file.exists())
        self.assertTrue(shifted_daily_average_file.exists())
        self.assertTrue(comparison_file.exists())

        # Open netCDF datasets
        daily_average_dataset = netCDF4.Dataset(daily_average_file, 'r')
        shifted_daily_average_dataset = netCDF4.Dataset(shifted_daily_average_file, 'r')
        expected_dataset = netCDF4.Dataset(comparison_file, 'r')

        # Check variable attributes and data match the expected values
        for variable_name in ["time_centered", "time_centered_bounds", "time_counter", "time_counter_bounds"]:
            for dataset in [daily_average_dataset, shifted_daily_average_dataset]:
                variable = dataset[variable_name]
                expected_variable = expected_dataset[variable_name]

                # Check attributes of the variable are equal
                self.assertDictEqual(variable.__dict__, expected_variable.__dict__)

                # Check variable data is equal
                npt.assert_allclose(variable, expected_variable, rtol=self.rtol)

        # Open daily_average netCDF variable
        daily_average = daily_average_dataset["daily_average"]
        shifted_daily_average = shifted_daily_average_dataset["daily_average"]

        # Check attributes of the daily_average fields are equal
        self.assertDictEqual(daily_average.__dict__, shifted_daily_average.__dict__)

        # Check data of the daily_average fields are not equal
        self.assertFalse(np.allclose(daily_average, shifted_daily_average, rtol=self.rtol))
