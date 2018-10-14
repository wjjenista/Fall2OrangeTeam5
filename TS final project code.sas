/************************************************
***************************************************
***************************************************

This part was coded in SAS

***************************************************
***************************************************
**************************************************/


libname HW 'C:\Users\Melissa Sandahl\OneDrive\Documents\School\MSA courses\AA502\Data Viz\Well_Data\Well Data';
%let path = C:\Users\Melissa Sandahl\OneDrive\Documents\School\MSA courses\AA502\Data Viz\Well_Data\Well Data;
libname HW 'C:\Users\Bill\Documents\NCSU\Course Work\Fall\Time Series\Homework\Time Series 2';
%let path = C:\Users\Bill\Documents\NCSU\Course Work\Fall\Time Series\Homework\Time Series 2;
/*Derrick' Path*/
libname HW 'C:\Users\derri\Documents\NC State Classes\Time Series\Homework 1';
%let path = C:\Users\derri\Documents\NC State Classes\Time Series\Homework 1;

/*Importing to a Permenat Data set. Update your path to your own local drive*/
PROC IMPORT OUT= HW.Well_Data DATAFILE= "&path.\G-2866_T.xlsx" 
            DBMS=xlsx REPLACE;
     SHEET="Well"; 
     GETNAMES=YES;
RUN;

/*Importing rain data*/
PROC IMPORT OUT= HW.Rain_Data DATAFILE= "&path.\G-2866_T.xlsx" 
            DBMS=xlsx REPLACE;
     SHEET="Rain"; 
     GETNAMES=YES;
RUN;

/*Importing the Imputed values from R Code*/
PROC IMPORT OUT= HW.Well_Imputed DATAFILE= "C:\Users\derri\Documents\NC State Classes\Time Series\Data\well_imputed.csv" 
            DBMS=csv REPLACE; 
     GETNAMES=YES;
RUN;



/*Adding a Month and Year Variable to the Dataset*/
data HW.Well_Data_Modified;
set HW.Well_Data;
	Day = day(date);
	Month = month(date);
	Year = year(date);
run;

proc sql;
create table HW.Well_Data_Modified2 as
(
Select
*,
Case 
	when time >= 0 and time < 3599 then 0
	when time >= 3599 and time < 7199 then 1
	when time >= 7199 and time < 10799 then 2
	when time >= 10799 and time < 14399 then 3
	when time >= 14399 and time < 17999 then 4
	when time >= 17999 and time < 21599 then 5
	when time >= 21599 and time < 25199 then 6
	when time >= 25199 and time < 28799 then 7
	when time >= 28799 and time < 32399 then 8
	when time >= 32399 and time < 35999 then 9
	when time >= 35999 and time < 39599 then 10
	when time >= 39599 and time < 43199 then 11
	when time >= 43199 and time < 46799 then 12
	when time >= 46799 and time < 50399 then 13
	when time >= 50399 and time < 53999 then 14
	when time >= 53999 and time < 57599 then 15
	when time >= 57599 and time < 61199 then 16
	when time >= 61199 and time < 64799 then 17
	when time >= 64799 and time < 68399 then 18
	when time >= 68399 and time < 71999 then 19
	when time >= 71999 and time < 75599 then 20
	when time >= 75599 and time < 79199 then 21
	when time >= 79199 and time < 82799 then 22
	when time >= 82799 then 23
	else .
	end as Hour
From HW.Well_Data_Modified
); quit;

/* -----------------------------------------------------------
----------------RAIN DATA-------------------------------------
-----------------------------------------------------------*/

/*Creates and hour column and a date without time column*/
/*Also trims data to match well data time span*/
data hw.rain_data(keep=year month day hour rain_ft);
	set hw.rain_data;
	date2=datepart(date+50);      *"+50" makes the transitions between days/months/years correct;
	hour=hour(date+1);            *"+1" makes the transitions between hours correct;
	year=year(date2);
	month=month(date2);
	day=day(date2);
	where datepart(date) >= "01Oct2007"d and datepart(date) <= "08Jun2018"d;
	if (Year = 2018) and (Month = 6) and (Day >= 8) and (Hour>=10) then delete;
run;

/*Aggregate to the hour using SUM not average*/
Proc sql;
Create Table hw.rain_data_hourly as
Select
	Year, Month, Day, Hour,	sum(rain_ft) as rain
From
	hw.rain_data
Group BY
	Year, Month, Day, Hour
Order By
	Year, Month, Day, Hour
; Quit;

/* -----------------------------------------------------------
----------------End RAIN DATA---------------------------------
-----------------------------------------------------------*/

/*Grouping and summing the data by taking the average for the month*/
Proc sql;
Create Table HW.Well_Data_hourly as 
Select
	Year,
	Month,
	Day,
	Hour,
	AVG(Corrected) as Corrected
From
	HW.Well_Data_Modified2
Group BY
	Year, Month, Day, Hour
Order By
	Year, Month, Day, Hour
; Quit;


/******************************
*******************************
*Try to replace missing values*
*******************************
******************************/

/*Creating a base dataset that has all of the hour values that SHOULD be in the dataset*/
/*I plan to use this base to find missing values with proc sql*/
data HW.Base_Time (drop= y m d h n);
/*Loop for each Year*/
do y = 2007 to 2018;
Year = y;
/*Loop for each month*/
	do m = 1 to 12;
	Month = m;
/*Conditional processing for leap year, and months with 30 days verus 31 days*/
	if (m = 2 and year = 2008) or (m = 2 and year = 2012) or (m = 2 and year = 2016) then n = 29;
	else if m = 1 or m = 3 or m = 5 or m = 7 or m = 8 or m = 10 or m = 12 then n = 31;
	else if m = 4 or m = 6 or m = 9 or m = 11 then n = 30;
	else if (m = 2 and year ne 2008) or (m = 2 and year ne 2012) or (m = 2 and year ne 2016) then n = 28;
	else n = 0;
/*Do loop for each hour of each day*/
	do d = 1 to n;
	Day = d;
		do h = 0 to 23;
		Hour = h;
output;
end;
end;
end;
end;
run;

/*Deleting before we had data*/
/*Did this in 2 steps.*/
/*I know this could be more efficient but it works. Don't fix something that aint borken*/
Data HW.Base_Time;
	set HW.Base_Time;
	if ((Year = 2007) and (Month <= 9)) or ((Year = 2018) and (Month >= 7)) then delete;
run;
data HW.Base_Time;
set HW.Base_Time;
if (Year = 2018) and (Month = 6) and (Day >= 13) then delete;
run;

data HW.Base_Time;
set HW.Base_Time;
if (Year = 2007) and (Month = 10) and (Day = 1) and (Hour=0) then delete;
run;

/*Checking to make sure that my do loops worked correctly*/
proc sql;
select year, count(hour)
from HW.Base_Time
group by 1
; quit;

/*Joining the base time to the well data*/
/*It should be interesting to see how many missing we have and what to do with it*/
proc sql;
create table HW.Well_Data_hourly2 as
Select B.Year, B.Month, B.Day, B.Hour, M.Corrected
From HW.Base_Time as B left join HW.Well_Data_hourly as M
	on (B.Year=M.Year) and
		(B.Month=M.Month) and
		(B.Day=M.Day) and
		(B.Hour=M.Hour)
; Quit;



/******************************
*******************************
	   *Counting Missing*
*******************************
******************************/
/**/
Proc freq data = HW.Well_Data_hourly2;
	tables Corrected;
	where Corrected = .;
run;

data missing;
	set HW.Well_Data_hourly2;
	where Corrected = .;
run;

/******************************
*******************************
	   *Finish Merging*
*******************************
******************************/

/*Horizontal Merge of Melissa's Data*/
Data HW.Merged_Imputed (drop = datetime well_avg);
merge HW.Well_Data_hourly2 HW.Well_Imputed;
run;

/*Checking to make sure that the imputed worked*/
proc freq data = HW.Merged_Imputed;
	tables Imputed;
	where Imputed = .;
run;

/*Deleteing the last 4 days off of the dataset as requested*/
data HW.Merged_Imputed;
	set HW.Merged_Imputed;
	if (Year = 2018) and (Month = 6) and (Day >= 8) and (Hour>=10) then delete;
	if (Year = 2018) and (Month = 6) and (Day > 8) then delete;
run;

/*Merge rain data with well data*/
data HW.wellrain;
	merge hw.merged_imputed hw.rain_data_hourly;
	by year month day hour;
run;

/*Check for missing values in rain*/
proc freq data = hw.wellrain;
	tables rain;
	where rain = .;
run;
/*Results: no missing values for Rain -- Would have put zero for missing values as most likely there was no rain*/

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
/********************************************
              Modeling
*********************************************
********************************************/

/********************************************
                ESM
********************************************/

/*Additive seasonal with Trend*/   *Derrick, I just dumped this in as a place holder . . . Bill;
ods output PerformanceStatistics=Print_Add_Seasonal_Trend;/* This will output the MAPE and other values to the called dataset for comparison */
proc esm data=HW.Well_Data_Monthly print=all plot=all 
		 seasonality=12 back=6 lead=6 outfor=HW.Model_Add_Seasonal_Trend; 
	forecast Corrected / model=addwinters; 
	title "Additive Seasonal with Trend Model for Well G2866-T";
run;
quit;
title;

/********************************************
               ARIMA
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
	forecast back=168 lead=168 out=Residuals;
run;
quit;

/********************************************
               ARIMAX
********************************************/

proc arima data=wellrain;
identify var=imputed(1) nlag=60 crosscorr=(rain);
estimate input=(rain) p=2 method=ML;
forecast out=test;
run;
quit;


proc arima data=test;
identify var=residual stationarity=(adf=2);
run;
quit;
/*ADF test was significant -> stationary*/

proc arima data=wellrain;
identify var=imputed(1) nlag=60 crosscorr=(rain);
estimate input=(rain) p=2 q=7 method=ML;
forecast back=168 lead=168 out=arimax;
run;
quit;

/********************************************
              Calculating MAPEs
********************************************/
Data Pre_MAPE;
	set Residuals nobs=total;
	Pre_MAPE = abs(RESIDUAL/Imputed);
	if _n_ > total-168;
run;

Proc sql;
select Sum_Residuals/Obs as MAPE
From (Select sum(Pre_MAPE) as Sum_Residuals,
count(Pre_Mape) as Obs from Pre_MAPE) as sum; quit;

/*MAPE */
/*0.036947*/

