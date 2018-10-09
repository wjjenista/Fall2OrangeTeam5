libname HW 'C:\Users\Melissa Sandahl\OneDrive\Documents\School\MSA courses\AA502\Data Viz\Well_Data\Well Data';
%let path = C:\Users\Melissa Sandahl\OneDrive\Documents\School\MSA courses\AA502\Data Viz\Well_Data\Well Data;


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

/*Plotting to see if the season is monthly by hour (30 * 24)*/
proc timeseries data=HW.merged_imputed plots=(series decomp) seasonality=720;
	var imputed;
run;
quit;

/*Plotting to see the if season is daily*/
proc timeseries data=HW.merged_imputed plots=(series decomp) seasonality=24;
	var imputed;
run;
quit;

/*Seems to fit most with annual season */
/*Moving forward with annual seasonality (length = 8766)*/

/*Questions to answer:
1. Is seasonality stochastic or deterministic? Dickey fuller test
	If it is stochastic, take differences
	If it is deterministic, model seasonality with either dummy variables or trigonometric
	functions. Would have to do trigonometric functions here due to season length. 
	Can't use adf test due to seasonal length. Instead try out seasonal differencing and see 
	what it looks like modeled.
2. Any random walk? Dickey Fuller test
3. Correlation in Y? Try AR terms.
4. Correlation in errors? Try MA terms.
5. Try terms until white noise plot looks good.
*/





/********************************************
              Modeling
********************************************/


/*Is seasonality stochastic or deterministic?
can't test adf due to season length*/
/*See what happens in proc arima with seasonal differencing */

proc arima data=HW.merged_imputed plot=all;
identify var=imputed(8766);
estimate method=ml;
forecast back=168 lead=168;
run;
quit;

/*Based on ACF plots, looks like there is random walk
  Add this and see what it looks like*/
proc arima data=HW.merged_imputed plot=all;
identify var=imputed(1,8766);
estimate method=ml;
forecast back=168 lead=168;
run;
quit;
/*forecast looks weird...*/

/*After adding random walk, try AR, MA terms
  Use automated search for AR, MA terms*/
proc arima data=HW.merged_imputed plot=all;
identify var=imputed(1,8766) nlag=80 minic scan esacf P=(0:60) Q=(0:60);
estimate method=ml;
forecast back=168 lead=168;
run;
quit;

/*Best model based on SCAN method*/
proc arima data=HW.merged_imputed plot=all;
identify var=imputed(1,8766) nlag=80;
estimate p=24 q=28 method=ml;
forecast back=168 lead=168;
run;
quit;
/*well that didn't work out... white noise plot is awful*/



/*Try deterministic seasonality instead of stochastic*/
/*Create sets of sin/cos functions*/

data HW.well_hourly_trig;
set HW.merged_imputed;
pi=constant("pi");
s1=sin(2*pi*1*_n_/8766);
c1=cos(2*pi*1*_n_/8766);
s2=sin(2*pi*2*_n_/8766);
c2=cos(2*pi*2*_n_/8766);
s3=sin(2*pi*3*_n_/8766);
c3=cos(2*pi*3*_n_/8766);
s4=sin(2*pi*4*_n_/8766);
c4=cos(2*pi*4*_n_/8766);
s5=sin(2*pi*5*_n_/8766);
c5=cos(2*pi*5*_n_/8766);
s6=sin(2*pi*6*_n_/8766);
c6=cos(2*pi*6*_n_/8766);
s7=sin(2*pi*7*_n_/8766);
c7=cos(2*pi*7*_n_/8766);
run;

/*Model deterministic seasonality. Start with 1 sin/cos terms*/
proc arima data=HW.well_hourly_trig plot=all;
identify var=imputed crosscorr=(s1 c1);
estimate input=(s1 c1) method=ml;
forecast back=168 lead=168;
run;
quit;

/*Looks like random walk. ADF test to see if need to take differences*/
proc arima data=HW.well_hourly_trig plot=all;
identify var=imputed crosscorr=(s1 c1) nlag=30 stationarity=(adf=2);
estimate input=(s1 c1) method=ml;
forecast back=168 lead=168;
run;
quit;


/*Adding random walk term*/
proc arima data=HW.well_hourly_trig plot=all;
identify var=imputed(1) crosscorr=(s1 c1);
estimate input=(s1 c1) method=ml;
forecast back=168 lead=168;
run;
quit;



/*Adding more sin/cos terms*/
proc arima data=HW.well_hourly_trig plot=all;
identify var=imputed(1) crosscorr=(s1 c1 s2 c2 s3 c3);
estimate input=(s1 c1 s2 c2 s3 c3) method=ml;
forecast back=168 lead=168;
run;
quit;


/*Adding even more sin/cos terms*/
proc arima data=HW.well_hourly_trig plot=all;
identify var=imputed(1) crosscorr=(s1 c1 s2 c2 s3 c3 s4 c4 s5 c5);
estimate input=(s1 c1 s2 c2 s3 c3 s4 c4 s5 c5) method=ml;
forecast back=168 lead=168 out=well_out;
run;
quit;


/*Not seeing major differences with more sin/cos terms
  Not sure how many should be added*/
/*Stick with 5*/

/*AR, MA terms*/


/*automated search for MA, AR terms*/
proc arima data=HW.well_hourly_trig plot=all;
	identify var=imputed(1) crosscorr=(s1 c1 s2 c2 s3 c3 s4 c4 s5 c5) nlag=80 minic scan esacf P=(0:60) Q=(0:60);
	estimate input=(s1 c1 s2 c2 s3 c3 s4 c4 s5 c5) method=ml;
	forecast back=168 lead=168;
run;
quit;

/*results from automated test: p of 27 q of 2*/
proc arima data=HW.well_hourly_trig plot=all;
	identify var=imputed(1) crosscorr=(s1 c1 s2 c2 s3 c3 s4 c4 s5 c5) nlag=80;
	estimate p=27 q=2 input=(s1 c1 s2 c2 s3 c3 s4 c4 s5 c5) method=ml;
	forecast back=168 lead=168;
run;
quit;

/*still not close to white noise*/




/*Testing without seasonality
Only differencing at lag 1 with AR, MA terms*/
/*Check adf test to see if more than 1 difference needed*/

proc arima data=HW.merged_imputed plot=all;
identify var=imputed(1) nlag=60 stationarity=(adf=2);
estimate method=ml;
*forecast back=168 lead=168;
run;
quit;


/*Automated search for AR, MA terms*/

proc arima data=HW.merged_imputed plot=all;
	identify var=imputed(1) nlag=40 minic scan esacf P=(0:60) Q=(0:60);
	estimate method=ml;
	*forecast back=168 lead=168;
run;
quit;

/*Trying different combinations of AR, MA terms
These two models were the best*/

proc arima data=HW.merged_imputed plot=all;
	identify var=imputed(1) nlag=80;
	estimate p=26 q=2 method=ml;
	forecast back=168 lead=168;
run;
quit;

proc arima data=HW.merged_imputed plot=all;
	identify var=imputed(1) nlag=80;
	estimate p=6 q=4 method=ml;
	forecast back=168 lead=168;
run;
quit;
