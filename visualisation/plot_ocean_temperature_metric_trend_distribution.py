"""
Filename:     plot_ocean_temperature_metric_trend_distribution.py
Author:       Damien Irving, irving.damien@gmail.com
Description:  Plot the distribution of trends OHC difference

"""

# Import general Python modules

import sys, os, pdb
import argparse

import matplotlib.pyplot as plt
import seaborn
import numpy

import iris
import iris.quickplot as qplt
from iris.util import rolling_window
from scipy import stats


# Import my modules

cwd = os.getcwd()
repo_dir = '/'
for directory in cwd.split('/')[1:]:
    repo_dir = os.path.join(repo_dir, directory)
    if directory == 'climate-analysis':
        break

modules_dir = os.path.join(repo_dir, 'modules')
sys.path.append(modules_dir)

try:
    import general_io as gio
    import convenient_universal as uconv
except ImportError:
    raise ImportError('Must run this script from anywhere within the climate-analysis git repo')


# Define functions

def plot_trend_distribution(trend_data, exponent, model, experiment):
    """ """

    assert exponent == '22', 'Data re-scaled assuming original unit of 10^22 J'
    trend_data = trend_data * 1e8

    seaborn.despine(left=True)
    seaborn.distplot(trend_data, hist=True, color="orange", 
                     kde_kws={"shade": True}, label=experiment)

    plt.legend(loc='best')
    plt.title('12-year trends in hemispheric OHC difference, %s'  %(model))
    plt.ylabel('Density')
    plt.xlabel('Trend ($10^{14} W$)')


def calc_diff_trends(sthext_cube, notsthext_cube, window=144):
    """Calculate trends in difference between southern extratropics and rest of globe.

    A window of 144 matches the length of the Argo record 
      (i.e. 12 years of annually smoothed monthly data)

    """

    diff = sthext_cube - notsthext_cube
    diff_windows = rolling_window(diff.data, window=window, axis=0)    
    x_axis_windows = rolling_window(diff.coord('time').points, window=window, axis=0)

    ntimes = diff_windows.shape[0]
    trends = numpy.zeros(ntimes)
    for i in range(0, ntimes):
        x = x_axis_windows[i, :]
        y = diff_windows[i, :]
        slope, intercept, r_value, p_value, std_err = stats.linregress(x, y)
        trends[i] = slope

    # convert units from J/month to J/s so can be expressed as Watts (1 J = W.s)
    assert 'days' in str(diff.coord('time').units)
    hours_in_day = 24
    minutes_in_hour = 60
    seconds_in_minute = 60

    trends = trends / (hours_in_day * minutes_in_hour * seconds_in_minute)

    return trends


def main(inargs):
    """Run the program."""
    
    model, experiment, run = gio.get_cmip5_file_details(inargs.infile)

    # Read data
    try:
        time_constraint = gio.get_time_constraint(inargs.time)
    except AttributeError:
        time_constraint = iris.Constraint()

    data_dict = {}
    with iris.FUTURE.context(cell_datetime_objects=True):
        data_dict[(model, experiment, run, 'globe')] = iris.load_cube(inargs.infile, 'ocean heat content globe' & time_constraint)
        data_dict[(model, experiment, run, 'sthext')] = iris.load_cube(inargs.infile, 'ocean heat content southern extratropics' & time_constraint)
        data_dict[(model, experiment, run, 'notsthext')] = iris.load_cube(inargs.infile, 'ocean heat content outside southern extratropics' & time_constraint)

    # Calculate the annual mean timeseries
    for key, value in data_dict.iteritems():
        data_dict[key] = value.rolling_window('time', iris.analysis.MEAN, 12)
    tex_units, exponent = uconv.units_info(str(value.units))

    # Calculate trends in 
    diff_trends = calc_diff_trends(data_dict[(model, experiment, run, 'sthext')], 
                                   data_dict[(model, experiment, run, 'notsthext')])

    # Plot
    fig = plt.figure()  #figsize=[15, 7])
    plot_trend_distribution(diff_trends, exponent, model, experiment)

    # Write output
    plt.savefig(inargs.outfile, bbox_inches='tight')
    infile_history = data_dict[(model, experiment, run, 'globe')].attributes['history']
    gio.write_metadata(inargs.outfile, file_info={inargs.outfile:infile_history})


if __name__ == '__main__':

    extra_info =""" 
author:
  Damien Irving, irving.damien@gmail.com
    
"""

    description='Plot the spatial trend in ocean heat content'
    parser = argparse.ArgumentParser(description=description,
                                     epilog=extra_info, 
                                     argument_default=argparse.SUPPRESS,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument("infile", type=str, help="Input ocean heat content file")
    parser.add_argument("outfile", type=str, help="Output file name")
    
    parser.add_argument("--time", type=str, nargs=2, metavar=('START_DATE', 'END_DATE'),
                        help="Time period [default = entire]")

    args = parser.parse_args()            
    main(args)
