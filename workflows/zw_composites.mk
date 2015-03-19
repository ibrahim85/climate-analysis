# zw_composites.mk
#
# Description: Calculate composite for variable of interest (e.g. tas, pr, sic)
#
# Composite methods:
#   variable: calculate composite mean variable for times where index exceeds threshold
#   index: calculate composite mean index for times where variable anomaly exceeds threshold 
#
# Thresholds:
#   upper: e.g. > 90th percentile
#   lower: e.g. < 10th percentile  
#
# To execute:
#   make -n -B -f zw_composites.mk  (-n is a dry run) (-B is a force make)

# Define marcos
include zw_config.mk
include zw_base.mk

all : ${TARGET}

# Baseline anomaly data (calculates anomaly then running mean)

## Meridional wind
V_ANOM_RUNMEAN=${DATA_DIR}/va_${DATASET}_${LEVEL}_${TSCALE_LABEL}-anom-wrt-all_native.nc
${V_ANOM_RUNMEAN} : ${V_ORIG} 
	cdo ${TSCALE} -ydaysub $< -ydayavg $< $@
	bash ${CDO_FIX_SCRIPT} $@ va

## Zonal wind
U_ANOM_RUNMEAN=${DATA_DIR}/ua_${DATASET}_${LEVEL}_${TSCALE_LABEL}-anom-wrt-all_native.nc
${U_ANOM_RUNMEAN} : ${U_ORIG} 
	cdo ${TSCALE} -ydaysub $< -ydayavg $< $@
	bash ${CDO_FIX_SCRIPT} $@ ua

## Surface variable of interest
CVAR_ORIG=${DATA_DIR}/${COMP_VAR}_${DATASET}_surface_daily_native.nc
CVAR_ANOM_RUNMEAN=${DATA_DIR}/${COMP_VAR}_${DATASET}_surface_${TSCALE_LABEL}-anom-wrt-all_native.nc
${CVAR_ANOM_RUNMEAN} : ${CVAR_ORIG} 
	cdo ${TSCALE} -ydaysub $< -ydayavg $< $@
	bash ${CDO_FIX_SCRIPT} $@ ${COMP_VAR}


# Contour composites (zg zonal anomaly)

COMP_ZG_ZONAL_ANOM_RUNMEAN_MI_HIGH=${COMP_DIR}/zg-composite_zw_mi${METRIC_HIGH_THRESH}_${DATASET}_${LEVEL}_${TSCALE_LABEL}_native-zonal-anom.nc 
${COMP_ZG_ZONAL_ANOM_RUNMEAN_MI_HIGH} : ${ZG_ZONAL_ANOM_RUNMEAN} ${MI_HIGH_DATES} 
	${PYTHON} ${DATA_SCRIPT_DIR}/calc_composite.py $< zg $@ --date_file $(word 2,$^)

COMP_ZG_ZONAL_ANOM_RUNMEAN_MI_LOW=${COMP_DIR}/zg-composite_zw_mi${METRIC_LOW_THRESH}_${DATASET}_${LEVEL}_${TSCALE_LABEL}_native-zonal-anom.nc 
${COMP_ZG_ZONAL_ANOM_RUNMEAN_MI_LOW} : ${ZG_ZONAL_ANOM_RUNMEAN} ${MI_LOW_DATES} 
	${PYTHON} ${DATA_SCRIPT_DIR}/calc_composite.py $< zg $@ --date_file $(word 2,$^)


# Summary composite

## Step 1: Get the composite mean wind field
COMP_V_ANOM_RUNMEAN_MI_HIGH=${COMP_DIR}/va-composite_zw_mi${METRIC_HIGH_THRESH}_${DATASET}_${LEVEL}_${TSCALE_LABEL}_native.nc 
${COMP_V_ANOM_RUNMEAN_MI_HIGH} : ${V_ANOM_RUNMEAN} ${MI_HIGH_DATES} 
	${PYTHON} ${DATA_SCRIPT_DIR}/calc_composite.py $< va $@ --date_file $(word 2,$^) 

COMP_U_ANOM_RUNMEAN_MI_HIGH=${COMP_DIR}/ua-composite_zw_mi${METRIC_HIGH_THRESH}_${DATASET}_${LEVEL}_${TSCALE_LABEL}_native.nc 
${COMP_U_ANOM_RUNMEAN_MI_HIGH} : ${U_ANOM_RUNMEAN} ${MI_HIGH_DATES} 
	${PYTHON} ${DATA_SCRIPT_DIR}/calc_composite.py $< ua $@ --date_file $(word 2,$^) 

## Step 3: Plot
COMP_SUMMARY_PLOT=${COMP_DIR}/zg-composite_zw_mi${METRIC_HIGH_THRESH}_${DATASET}_${LEVEL}_${TSCALE_LABEL}_native-zonal-anom.png
${COMP_SUMMARY_PLOT} : ${COMP_ZG_ZONAL_ANOM_RUNMEAN_MI_HIGH} ${COMP_U_ANOM_RUNMEAN_MI_HIGH} ${COMP_V_ANOM_RUNMEAN_MI_HIGH}
	bash ${VIS_SCRIPT_DIR}/plot_summary_composite.sh $(word 1,$^) zg $(word 2,$^) ua $(word 3,$^) va $@ ${PYTHON} ${VIS_SCRIPT_DIR}







#########################













# Variable composite, upper threshold of MI

## Step 1: Calculate variable composite 
COMP_VAR_MI_FILE=${COMP_DIR}/${COMP_VAR}-composite_zw_mi${METRIC_HIGH_THRESH}_va_${DATASET}_${LEVEL}_${TSCALE_LABEL}-anom-wrt-all_native.nc 
${COMP_VAR_MI_FILE} : ${COMP_VAR_ANOM_RUNMEAN} ${MI_HIGH_DATES} 
	${PYTHON} ${DATA_SCRIPT_DIR}/calc_composite.py $< ${COMP_VAR} $@ --date_file $(word 2,$^) --region sh 

## Step 2: Calculate the contour composite (already done for composite envelope above)

## Step 3: Plot
COMP_VAR_MI_PLOT=${COMP_DIR}/${COMP_VAR}-composite_zw_mi${METRIC_HIGH_THRESH}_va-zg_${DATASET}_${LEVEL}_${TSCALE_LABEL}-anom-wrt-all_native.png
${COMP_VAR_MI_PLOT} : ${COMP_VAR_MI_FILE} ${ZG_ZONAL_ANOM_RUNMEAN_COMP}
	bash ${VIS_SCRIPT_DIR}/plot_composite.sh $(word 1,$^) ${COMP_VAR} $(word 2,$^) zg $@ ${PYTHON} ${VIS_SCRIPT_DIR}


# Variable composite, upper threshold of PWI + Nino phases

## Step 1: Combine the PWI and nino date lists
PWI_ELNINO_DATES=${INDEX_DIR}/dates_nino34elnino-${METRIC}${METRIC_HIGH_THRESH}_tos_${DATASET}_surface_${TSCALE_LABEL}_native.txt
${PWI_ELNINO_DATES} : ${ELNINO_DATES} ${DATE_LIST}
	${PYTHON} ${DATA_SCRIPT_DIR}/combine_dates.py $@ $< $(word 2,$^)

PWI_LANINA_DATES=${INDEX_DIR}/dates_nino34lanina-${METRIC}${METRIC_HIGH_THRESH}_tos_${DATASET}_surface_${TSCALE_LABEL}_native.txt
${PWI_LANINA_DATES} : ${LANINA_DATES} ${DATE_LIST}
	${PYTHON} ${DATA_SCRIPT_DIR}/combine_dates.py $@ $< $(word 2,$^)

## Step 2: Calculate the Nino contour composites
CONTOUR_ZONAL_ANOM_RUNMEAN_PWI_ELNINO_COMP=${COMP_DIR}/zg-composite_zw_nino34elnino-${METRIC}${METRIC_HIGH_THRESH}-${ENV_WAVE_LABEL}_env-${VAR}_${DATASET}_${LEVEL}_${TSCALE_LABEL}_native-zonal-anom.nc 
${CONTOUR_ZONAL_ANOM_RUNMEAN_PWI_ELNINO_COMP} : ${CONTOUR_ZONAL_ANOM_RUNMEAN} ${PWI_ELNINO_DATES} 
	${PYTHON} ${DATA_SCRIPT_DIR}/calc_composite.py $< zg $@ --date_file $(word 2,$^)

CONTOUR_ZONAL_ANOM_RUNMEAN_PWI_LANINA_COMP=${COMP_DIR}/zg-composite_zw_nino34lanina-${METRIC}${METRIC_HIGH_THRESH}-${ENV_WAVE_LABEL}_env-${VAR}_${DATASET}_${LEVEL}_${TSCALE_LABEL}_native-zonal-anom.nc
${CONTOUR_ZONAL_ANOM_RUNMEAN_PWI_LANINA_COMP} : ${CONTOUR_ZONAL_ANOM_RUNMEAN} ${PWI_LANINA_DATES} 
	${PYTHON} ${DATA_SCRIPT_DIR}/calc_composite.py $< zg $@ --date_file $(word 2,$^)

## Step 3: Plot
COMP_PWI_NINO_PLOT=${COMP_DIR}/zg-composite_zw_nino-${METRIC}${METRIC_HIGH_THRESH}-${ENV_WAVE_LABEL}_env-${VAR}-zg_${DATASET}_${LEVEL}_${TSCALE_LABEL}-anom-wrt-all_native.png
${COMP_PWI_NINO_PLOT} : ${CONTOUR_ZONAL_ANOM_RUNMEAN_PWI_ELNINO_COMP} ${CONTOUR_ZONAL_ANOM_RUNMEAN_COMP} ${CONTOUR_ZONAL_ANOM_RUNMEAN_PWI_LANINA_COMP}
	bash ${VIS_SCRIPT_DIR}/plot_variability_composite.sh $(word 1,$^) $(word 2,$^) $(word 3,$^) zg $@ ${PYTHON} ${VIS_SCRIPT_DIR}


# Variable composite, upper threshold of PWI + SAM phases

## Step 1: Combine the PWI and SAM date lists
PWI_SAM_POS_DATES=${INDEX_DIR}/dates_samgt75pct-${METRIC}${METRIC_HIGH_THRESH}_tos_${DATASET}_surface_${TSCALE_LABEL}_native.txt
${PWI_SAM_POS_DATES} : ${SAM_POS_DATES} ${DATE_LIST}
	${PYTHON} ${DATA_SCRIPT_DIR}/combine_dates.py $@ $< $(word 2,$^)

PWI_SAM_NEG_DATES=${INDEX_DIR}/dates_samlt25pct-${METRIC}${METRIC_HIGH_THRESH}_tos_${DATASET}_surface_${TSCALE_LABEL}_native.txt
${PWI_SAM_NEG_DATES} : ${SAM_NEG_DATES} ${DATE_LIST}
	${PYTHON} ${DATA_SCRIPT_DIR}/combine_dates.py $@ $< $(word 2,$^)

## Step 2: Calculate the SAM contour composites
CONTOUR_ZONAL_ANOM_RUNMEAN_PWI_SAM_POS_COMP=${COMP_DIR}/zg-composite_zw_samgt75pct-${METRIC}${METRIC_HIGH_THRESH}-${ENV_WAVE_LABEL}_env-${VAR}_${DATASET}_${LEVEL}_${TSCALE_LABEL}_native-zonal-anom.nc 
${CONTOUR_ZONAL_ANOM_RUNMEAN_PWI_SAM_POS_COMP} : ${CONTOUR_ZONAL_ANOM_RUNMEAN} ${PWI_SAM_POS_DATES} 
	${PYTHON} ${DATA_SCRIPT_DIR}/calc_composite.py $< zg $@ --date_file $(word 2,$^)

CONTOUR_ZONAL_ANOM_RUNMEAN_PWI_SAM_NEG_COMP=${COMP_DIR}/zg-composite_zw_samlt25pct-${METRIC}${METRIC_HIGH_THRESH}-${ENV_WAVE_LABEL}_env-${VAR}_${DATASET}_${LEVEL}_${TSCALE_LABEL}_native-zonal-anom.nc
${CONTOUR_ZONAL_ANOM_RUNMEAN_PWI_SAM_NEG_COMP} : ${CONTOUR_ZONAL_ANOM_RUNMEAN} ${PWI_SAM_NEG_DATES} 
	${PYTHON} ${DATA_SCRIPT_DIR}/calc_composite.py $< zg $@ --date_file $(word 2,$^)

## Step 3: Plot
COMP_PWI_SAM_PLOT=${COMP_DIR}/zg-composite_zw_sam-${METRIC}${METRIC_HIGH_THRESH}-${ENV_WAVE_LABEL}_env-${VAR}-zg_${DATASET}_${LEVEL}_${TSCALE_LABEL}-anom-wrt-all_native.png
${COMP_PWI_SAM_PLOT} : ${CONTOUR_ZONAL_ANOM_RUNMEAN_PWI_SAM_POS_COMP} ${CONTOUR_ZONAL_ANOM_RUNMEAN_COMP} ${CONTOUR_ZONAL_ANOM_RUNMEAN_PWI_SAM_NEG_COMP}
	bash ${VIS_SCRIPT_DIR}/plot_variability_composite.sh $(word 1,$^) $(word 2,$^) $(word 3,$^) zg $@ ${PYTHON} ${VIS_SCRIPT_DIR}


# Variable composite, lower threshold of PWI

## Step 1: Generate list of dates for use in composite creation
ANTI_DATE_LIST=${COMP_DIR}/dates_zw_${METRIC}${METRIC_LOW_THRESH}-${ENV_WAVE_LABEL}_env-${VAR}_${DATASET}_${LEVEL}_${TSCALE_LABEL}_native-${MER_METHOD}.txt 
${ANTI_DATE_LIST}: ${WAVE_STATS}
	${PYTHON} ${DATA_SCRIPT_DIR}/parse_wave_stats.py $< ${METRIC} --date_list $@ --metric_threshold ${METRIC_LOW_THRESH} --threshold_direction less

## Step 2: Get the composite variable mean
ANTICOMP_VAR_FILE=${COMP_DIR}/${COMP_VAR}-composite_zw_${METRIC}${METRIC_LOW_THRESH}-${ENV_WAVE_LABEL}_env-${VAR}_${DATASET}_${LEVEL}_${TSCALE_LABEL}-anom-wrt-all_native.nc 
${ANTICOMP_VAR_FILE} : ${COMP_VAR_ANOM_RUNMEAN} ${ANTI_DATE_LIST} 
	${PYTHON} ${DATA_SCRIPT_DIR}/calc_composite.py $< ${COMP_VAR} $@ --date_file $(word 2,$^) --region sh

## Step 3: Get the composite mean contour
CONTOUR_ZONAL_ANOM_RUNMEAN_ANTICOMP=${COMP_DIR}/zg-composite_zw_${METRIC}${METRIC_LOW_THRESH}-${ENV_WAVE_LABEL}_env-${VAR}_${DATASET}_${LEVEL}_${TSCALE_LABEL}_native-zonal-anom.nc 
${CONTOUR_ZONAL_ANOM_RUNMEAN_ANTICOMP} : ${CONTOUR_ZONAL_ANOM_RUNMEAN} ${ANTI_DATE_LIST} 
	${PYTHON} ${DATA_SCRIPT_DIR}/calc_composite.py $< zg $@ --date_file $(word 2,$^) --region sh

## Step 4: Plot
ANTICOMP_VAR_PLOT=${COMP_DIR}/${COMP_VAR}-composite_zw_${METRIC}${METRIC_LOW_THRESH}-${ENV_WAVE_LABEL}_env-${VAR}-zg_${DATASET}_${LEVEL}_${TSCALE_LABEL}-anom-wrt-all_native.png
${ANTICOMP_VAR_PLOT} : ${ANTICOMP_VAR_FILE} ${CONTOUR_ZONAL_ANOM_RUNMEAN_ANTICOMP}
	bash ${VIS_SCRIPT_DIR}/plot_composite.sh $(word 1,$^) ${COMP_VAR} $(word 2,$^) zg $@ ${PYTHON} ${VIS_SCRIPT_DIR}


# Index composite, upper threshold

## Step 1: Calculate composite
COMP_METRIC_90PCT_FILE=${COMP_DIR}/${METRIC}-composite_zw_${COMP_VAR}90pct-${ENV_WAVE_LABEL}_env-${VAR}_${DATASET}_${LEVEL}_${TSCALE_LABEL}-anom-wrt-all_native.nc
${COMP_METRIC_90PCT_FILE} : ${COMP_VAR_ANOM_RUNMEAN} ${WAVE_STATS}
	${PYTHON} ${DATA_SCRIPT_DIR}/calc_index_composite.py $(word 1,$^) ${COMP_VAR} $(word 2,$^) ${METRIC} 90pct $@ --region sh

## Step 2: Plot
COMP_METRIC_90PCT_PLOT=${COMP_DIR}/${METRIC}-composite_zw_${COMP_VAR}90pct-${ENV_WAVE_LABEL}_env-${VAR}_${DATASET}_${LEVEL}_${TSCALE_LABEL}-anom-wrt-all_native.png
${COMP_METRIC_90PCT_PLOT} : ${COMP_METRIC_90PCT_FILE}
	bash ${VIS_SCRIPT_DIR}/plot_index_composite.sh $< ${METRIC} 90pct $@ ${PYTHON} ${VIS_SCRIPT_DIR}


# Index composite, lower threshold

## Step 1: Calculate composite
COMP_METRIC_10PCT_FILE=${COMP_DIR}/${METRIC}-composite_zw_${COMP_VAR}10pct-${ENV_WAVE_LABEL}_env-${VAR}_${DATASET}_${LEVEL}_${TSCALE_LABEL}-anom-wrt-all_native.nc
${COMP_METRIC_10PCT_FILE} : ${COMP_VAR_ANOM_RUNMEAN} ${WAVE_STATS}
	${PYTHON} ${DATA_SCRIPT_DIR}/calc_index_composite.py $(word 1,$^) ${COMP_VAR} $(word 2,$^) ${METRIC} 10pct $@ --include below --region sh

## Step 2: Plot
COMP_METRIC_10PCT_PLOT=${COMP_DIR}/${METRIC}-composite_zw_${COMP_VAR}10pct-${ENV_WAVE_LABEL}_env-${VAR}_${DATASET}_${LEVEL}_${TSCALE_LABEL}-anom-wrt-all_native.png
${COMP_METRIC_10PCT_PLOT} : ${COMP_METRIC_10PCT_FILE}
	bash ${VIS_SCRIPT_DIR}/plot_index_composite.sh $< ${METRIC} 10pct $@ ${PYTHON} ${VIS_SCRIPT_DIR}


# Index composite, upper threshold (absolute value anomalies)

## Step 1: Calculate composite
COMP_METRIC_90PCTABS_FILE=${COMP_DIR}/${METRIC}-composite_zw_${COMP_VAR}90pctabs-${ENV_WAVE_LABEL}_env-${VAR}_${DATASET}_${LEVEL}_${TSCALE_LABEL}-anom-wrt-all_native.nc
${COMP_METRIC_90PCTABS_FILE} : ${COMP_VAR_ANOM_RUNMEAN} ${WAVE_STATS}
	${PYTHON} ${DATA_SCRIPT_DIR}/calc_index_composite.py $(word 1,$^) ${COMP_VAR} $(word 2,$^) ${METRIC} 10pct $@ --absolute --region sh

## Step 2: Plot
COMP_METRIC_90PCTABS_PLOT=${COMP_DIR}/${METRIC}-composite_zw_${COMP_VAR}90pctabs-${ENV_WAVE_LABEL}_env-${VAR}_${DATASET}_${LEVEL}_${TSCALE_LABEL}-anom-wrt-all_native.png
${COMP_METRIC_90PCTABS_PLOT} : ${COMP_METRIC_90PCTABS_FILE}
	bash ${VIS_SCRIPT_DIR}/plot_index_composite.sh $< ${METRIC} 90pctabs $@ ${PYTHON} ${VIS_SCRIPT_DIR}


# ASL composite, upper threshold of PWI
 
# bash calc_asl_composite.sh
