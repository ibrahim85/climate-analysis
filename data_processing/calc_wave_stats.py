"""
Filename:     calc_wave_stats.py
Author:       Damien Irving, d.irving@student.unimelb.edu.au
Description:  Calcuates statistics for wave envelope data 
              presented in Hovmoller format (time, longitude)

"""

# Import general Python modules #

import sys, os, pdb
import argparse
import numpy
import csv
import re

# Import my modules #

cwd = os.getcwd()
repo_dir = '/'
for directory in cwd.split('/')[1:]:
    repo_dir = os.path.join(repo_dir, directory)
    if directory == 'phd':
        break

modules_dir = os.path.join(repo_dir, 'modules')
sys.path.append(modules_dir)

try:
    import general_io as gio
    import netcdf_io as nio
except ImportError:
    raise ImportError('Must run this script from anywhere within the phd git repo')


# Define functions #
    
def extent_stats(data_double, lons_double, threshold, lons_spacing):
    """Return key statistics regarding the extent

    NOTE: An inprovement on the extent statistic might be a simple count 
    of the number of grid cells exceeding the threshold value

    """
    
    lons_filtered = lons_double[data_double > threshold]
    if len(lons_filtered) == 0:
        start_lon, end_lon, extent = 0.0, 0.0, 0.0
    elif len(lons_filtered) == len(lons_double):
        start_lon, end_lon, extent = 0.0, lons_double[-1], len(lons_double) / 2
    else: 
        diffs = numpy.diff(lons_filtered)
        diffs_corrected = numpy.where(diffs < 0, diffs + 360, diffs)
        extent_list = numpy.split(lons_filtered, numpy.where(diffs_corrected > lons_spacing)[0] + 1)
        
        lengths = map(len, extent_list)
        max_length = max(lengths)
        max_index = lengths.index(max_length)
        result = extent_list[max_index]
        start_lon = result[0]
        end_lon = result[-1]
        extent = len(result) * lons_spacing[0]
    
    return start_lon, end_lon, extent


def amp_stats(data):
    """Return key statistics regarding the amplitude of the wave 
    envelope across the entire zonal domain"""
    
    amp_mean = numpy.mean(data)
    
    return amp_mean


def get_lons(data):
    """Check that the longitude axis has uniform spacing, then return that axis."""

    lons = data.getLongitude()[:]

    lons_spacing = numpy.unique(numpy.diff(lons))
    assert len(lons_spacing) == 1, \
    'Must be a uniformly spaced longitude axis' 

    return lons, lons_spacing


def calc_threshold(data, threshold_str):
    """Provide a default threshold for use in determining the extent of the waveform"""

    if 'pct' in threshold_str:
        pct = float(re.sub('pct', '', threshold_str))
        threshold_float = numpy.percentile(data, pct)
    else:
        threshold_float = float(threshold_str)    

    return threshold_float


def main(inargs):
    """Run the program."""

    # Read data and check inputs #

    indata = nio.InputData(inargs.infile, inargs.var, 
                           **nio.dict_filter(vars(inargs), ['time',]))
			       
    assert indata.data.getOrder() == 'tx', \
    'Input data must be time, longitude'
    
    times = indata.data.getTime().asComponentTime()
    lons, lons_spacing = get_lons(indata.data)
    
    # Duplicate input data to cater for extents that straddle the Greenwich meridian #
    
    data_double = numpy.append(indata.data, indata.data, axis=1)
    lons_double = numpy.append(lons, lons)
    
    # Calculate threshold if one is not given

    threshold = calc_threshold(indata.data, inargs.threshold)

    # Loop through every timestep, writing the statistics to file # 
    
    time_stamp = gio.get_timestamp()
    ntime = len(times) 
    with open(inargs.outfile, 'wb') as ofile:
        output = csv.writer(ofile, delimiter=',')
	output.writerow(['# '+time_stamp])
        output.writerow(['date', 'amp-mean', 'start-lon', 'end-lon', 'extent'])
        for i in range(0, ntime):
            amp_mean = amp_stats(indata.data[i, :])
            start_lon, end_lon, extent = extent_stats(data_double[i, :], lons_double, threshold, lons_spacing)
              
	    # Write result to file
	    date = gio.standard_datetime(times[i])
            output.writerow([date, amp_mean, start_lon, end_lon, extent])
 

if __name__ == '__main__':

    extra_info =""" 
example (vortex.earthsci.unimelb.edu.au):
  /usr/local/uvcdat/1.3.0/bin/cdat calc_wave_stats.py 
  env-w234-va_Merra_250hPa_30day-runmean_r360x181-hov-lat70S40S.nc env 
  zw3-stats_Merra_250hPa_30day-runmean_r360x181-hov-lat70S40S_env-w234-va-threshold7.csv

author:
  Damien Irving, d.irving@student.unimelb.edu.au

"""

    description='Calculate statistics for wave envelope data presented in Hovmoller format (time, longitude)'
    parser = argparse.ArgumentParser(description=description,
                                     epilog=extra_info, 
                                     argument_default=argparse.SUPPRESS,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument("infile", type=str, help="Input wave envelope file")
    parser.add_argument("var", type=str, help="Input wave envelope variable")
    parser.add_argument("outfile", type=str, help="Output file name")

    parser.add_argument("--time", type=str, nargs=3, metavar=('START_DATE', 'END_DATE', 'MONTHS'),
                        help="Time period [default = entire]")
    parser.add_argument("--threshold", type=str, default='75pct',
                        help="Threshold used in extent calculation. Enter a raw number or a percentile [default = 75pct]")
    
    args = parser.parse_args()            

    print 'Input file: ', args.infile
    print 'Output file: ', args.outfile  
    
    main(args)    
