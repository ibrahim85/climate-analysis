function usage {
    echo "USAGE: bash $0 varfile var contfile contvar outfile python_exe code_dir"
    echo "   varfile:     Input file name for colour plot"
    echo "   var:         Variable long name for colour plot"
    echo "   contfile:    Input file name for contour plot"
    echo "   contvar:     Variable long name for contour plot"
    echo "   outfile:     Output file name"
    echo "   python_exe:  Python executable"
    echo "   code_dir:    Directory that plot_map.py is in"
    echo "   e.g. bash $0 tas_data.nc tas zg_data.nc zg plot.png /usr/local/anaconda/bin/python ~/climate-analysis/visualisation"
    exit 1
}

nargs=7

if [ $# -ne $nargs ] ; then
  usage
fi

varfile=$1
var=$2
contfile=$3
contvar=$4
outfile=$5
python_exe=$6
code_dir=$7
  

if [ $var == 'surface_air_temperature' ] ; then
    ticks="-2.5 -2.0 -1.5 -1.0 -0.5 0 0.5 1.0 1.5 2.0 2.5" 
    extend=both
    palette=RdBu_r
    significance="--infile ${varfile} p_value_annual none none none hatching0 1 PlateCarree --infile ${varfile} p_value_DJF none none none hatching0 3 PlateCarree --infile ${varfile} p_value_MAM none none none hatching0 4 PlateCarree --infile ${varfile} p_value_JJA none none none hatching0 5 PlateCarree --infile ${varfile} p_value_SON none none none hatching0 6 PlateCarree"
elif [ $var == 'sea_ice_fraction' ] ; then
    ticks="-0.13 -0.11 -0.09 -0.07 -0.05 -0.03 -0.01 0.01 0.03 0.05 0.07 0.09 0.11 0.13"
    extend=both
    palette=RdBu_r
    significance="--infile ${varfile} p_value_annual none none none hatching0 1 PlateCarree --infile ${varfile} p_value_DJF none none none hatching0 3 PlateCarree --infile ${varfile} p_value_MAM none none none hatching0 4 PlateCarree --infile ${varfile} p_value_JJA none none none hatching0 5 PlateCarree --infile ${varfile} p_value_SON none none none hatching0 6 PlateCarree --units ice_fraction --spstereo_limit -50"
elif [ $var == 'precipitation' ] ; then
    ticks="-1.0 -0.8 -0.6 -0.4 -0.2 0 0.2 0.4 0.6 0.8 1.0" 
    extend=both
    palette=BrBG
    significance="--infile ${varfile} p_value_annual none none none hatching0 1 PlateCarree --infile ${varfile} p_value_DJF none none none hatching0 3 PlateCarree --infile ${varfile} p_value_MAM none none none hatching0 4 PlateCarree --infile ${varfile} p_value_JJA none none none hatching0 5 PlateCarree --infile ${varfile} p_value_SON none none none hatching0 6 PlateCarree --units mm/day"
elif [ $var == 'envva' ] ; then
    ticks="0 1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0" 
    extend=max
    palette=brewer_YiOrRd_09
else
    echo "Unknown variable: $var"
    exit 1
fi

if [ $contvar == 'geopotential_height' ] ; then
    levels="-150 -120 -90 -60 -30 0 30 60 90 120 150" 
elif [ $contvar == 'streamfunction' ] ; then
    levels="-6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6" 
else
    echo "Unknown variable: $contvar"
    exit 1
fi


${python_exe} ${code_dir}/plot_map.py 3 2 \
--infile ${varfile} ${var}_annual none none none colour0 1 PlateCarree \
--infile ${varfile} ${var}_DJF none none none colour0 3 PlateCarree \
--infile ${varfile} ${var}_MAM none none none colour0 4 PlateCarree \
--infile ${varfile} ${var}_JJA none none none colour0 5 PlateCarree \
--infile ${varfile} ${var}_SON none none none colour0 6 PlateCarree \
--palette ${palette} \
--colourbar_ticks ${ticks} \
--output_projection SouthPolarStereo \
--subplot_headings Annual none DJF MAM JJA SON \
--infile ${contfile} ${contvar}_annual none none none contour0 1 PlateCarree \
--infile ${contfile} ${contvar}_DJF none none none contour0 3 PlateCarree \
--infile ${contfile} ${contvar}_MAM none none none contour0 4 PlateCarree \
--infile ${contfile} ${contvar}_JJA none none none contour0 5 PlateCarree \
--infile ${contfile} ${contvar}_SON none none none contour0 6 PlateCarree \
--contour_levels ${levels} \
--figure_size 9 16 \
--extend ${extend} \
--ofile ${outfile} \
--hatch_bounds 0.0 0.01 \
--hatch_styles bwdlines_tight ${significance} \
--exclude_blanks
