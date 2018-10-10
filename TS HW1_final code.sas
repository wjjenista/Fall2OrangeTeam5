libname HW 'C:\Users\Melissa Sandahl\OneDrive\Documents\School\MSA courses\AA502\Data Viz\Well_Data\Well Data';
%let path = C:\Users\Melissa Sandahl\OneDrive\Documents\School\MSA courses\AA502\Data Viz\Well_Data\Well Data;
libname HW 'C:\Users\Bill\Documents\NCSU\Course Work\Fall\Time Series\Homework\Time Series 2';
%let path = C:\Users\Bill\Documents\NCSU\Course Work\Fall\Time Series\Homework\Time Series 2;


/*Plot time series*/
proc timeseries data=HW.merged_imputed plots=(series decomp);
	var imputed;
run;
quit;


/*Plotting to see if the season is annual by hour (365.25 * 24)*/
proc timeseries data=HW.merged_imputed plots=(series decomp) seasonality=8766;
	var imputed;
run;
quit;


/********************************************
              Modeling
********************************************/

/*Random walk*/
proc arima data=HW.merged_imputed plot=all;
identify var=imputed(1) nlag=60 stationarity=(adf=2);
estimate method=ml;
forecast back=168 lead=168;
run;
quit;


/*AR, MA terms*/

proc arima data=HW.merged_imputed plot=all;
	identify var=imputed(1) nlag=80;
	estimate p=2 q=7 method=ml;
	forecast back=168 lead=168;
run;
quit;


