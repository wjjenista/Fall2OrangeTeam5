/*When adjusting this line for your personal directories, copy it and comment out this one for
  ease of switching when pushing to GitHub.*/
%let path = C:\Users\Bill\Documents\NCSU\Course Work\Fall\Visualization\Well_Data;

/*Importing to a Permenat Data set. Update your path to your own local drive
  Right now, each well data set has to be manually changed in this step and the proc sql step*/
PROC IMPORT OUT= Well_Data DATAFILE= "&path.\PB-1680_T.xlsx"
            DBMS=xlsx REPLACE;
     SHEET="Well"; 
     GETNAMES=YES;
RUN;

/*Adding an Hour Variable to the Dataset*/
data Well_Data_Modified;
	set Well_Data;
	hour = hour(time+1);
	if tz_cd = "EDT" then do;
		Hour = Hour - 1;
		if Hour < 0 then Hour = 23;
		if Hour = 23 then date = date - 1;
	end;
run;

/*Grouping and summing the data by taking the average for the month*/
Proc sql;
Create Table visproj.pb1680t as
Select
	Date, Hour,	AVG(Corrected) as Depth
From
	Well_Data_Modified
Group BY
	Date, Hour
Order By
	Date, Hour
; Quit;

/*Drop extra observations before Oct 1, 2007 from well G-852*/
data visproj.g852;
	set visproj.g852;
	if date >= "01Oct2007"d;
run;

/*Create ideal date sequence by hour*/
data ideal(keep = date hour);
	date = "01Oct2007"d;
	format date MMDDYY10.;
	do until (date = "06Jul2018"d and hour = 23);
		do i = 0 to 23;
			hour = i;
			output;
		end;
		date + 1;
	end;
run;

/*Merge all wells into the same data set*/
data visproj.all_wells;
	merge   ideal
			visproj.f179(rename=(depth = f179))
			visproj.f319(rename=(depth = f319))
			visproj.f45(rename=(depth = f45))
			visproj.g1220t(rename=(depth = g1220t))
			visproj.g1260t(rename=(depth = g1260t))
			visproj.g2147t(rename=(depth = g2147t))
			visproj.g2866t(rename=(depth = g2866t))
			visproj.g3549(rename=(depth = g3549))
			visproj.g561t(rename=(depth = g561t))
			visproj.g580a(rename=(depth = g580a))
			visproj.g852(rename=(depth = g852))
			visproj.g860(rename=(depth = g860))
			visproj.pb1680t(rename=(depth = pb1680t));
	by date hour;
run;

/* Normalize all the well data*/
proc sql;
	create table visproj.normwells as
	select date, hour, (f179-mean(f179))/std(f179) as f179N,
					   (f319-mean(f319))/std(f319) as f319N,
					   (f45-mean(f45))/std(f45) as f45N,
					   (g1220t-mean(g1220t))/std(g1220t) as g1220tN,
					   (g1260t-mean(g1260t))/std(g1260t) as g1260tN,
					   (g2147t-mean(g2147t))/std(g2147t) as g2147tN,
					   (g2866t-mean(g2866t))/std(g2866t) as g2866tN,
					   (g3549-mean(g3549))/std(g3549) as g3549N,
					   (g561t-mean(g561t))/std(g561t) as g561tN,
					   (g580a-mean(g580a))/std(g580a) as g580aN,
					   (g852-mean(g852))/std(g852) as g852N,
					   (g860-mean(g860))/std(g860) as g860N,
					   (pb1680t-mean(pb1680t))/std(pb1680t) as pb1680tN
	from visproj.all_wells;
quit;	

/* Impute missing values using */
data visproj.imputed_normal;
	set visproj.normwells;
	where date > "30Sep2007"d;
	impute = mean(f179n, f319n, f45n, g1220tn, g1260tn, g2147tn, g2866tn, g3549n,
				  g561tn, g580an, g852n, g860n, pb1680tn);
	if f179n=. then f179n = impute;
	if f319n=. then f319n = impute;
	if f45n=. then f45n = impute;
	if g1220tn=. then g1220tn = impute;
	if g1260tn=. then g1260tn = impute;
	if g2147tn=. then g2147tn = impute;
	if g2866tn=. then g2866tn = impute;
	if g3549n=. then g3549n = impute;
	if g561tn=. then g561tn = impute;
	if g580an=. then g580an = impute;
	if g852n=. then g852n = impute;
	if g860n=. then g860n = impute;
	if pb1680tn=. then pb1680tn = impute;
run;

/*Calculate mean and standard deviation of original time series*/
proc sql;
	create table visproj.stats as
	select mean(f179) as f179m, std(f179) as f179sd,
	       mean(f319) as f319m, std(f319) as f319sd,
		   mean(f45) as f45m, std(f45) as f45sd,
		   mean(g1220t) as g1220tm, std(g1220t) as g1220tsd,
		   mean(g1260t) as g1260tm, std(g1260t) as g1260tsd,
		   mean(g2147t) as g2147tm, std(g2147t) as g2147tsd,
		   mean(g2866t) as g2866tm, std(g2866t) as g2866tsd,
		   mean(g3549) as g3549m, std(g3549) as g3549sd,
		   mean(g561t) as g561tm, std(g561t) as g561tsd,
		   mean(g580a) as g580am, std(g580a) as g580asd,
		   mean(g852) as g852m, std(g852) as g852sd,
		   mean(g860) as g860m, std(g860) as g860sd,
		   mean(pb1680t) as pb1680tm, std(pb1680t) as pb1680tsd
	from visproj.all_wells;
quit;

/*Change normalized data back to original with imputed values*/
data visproj.all_wells_imputed;
	merge visproj.imputed_normal visproj.all_wells;
	by date hour;
	if f179=. then f179 = 0.5413844879*f179n+0.7023787213;
	if f319=. then f319 = 0.4008264697*f319n+0.82223807;
	if f45=. then f45= 0.59710404119*f45n+0.7396640008;
	if g1220t=. then g1220t = 0.6814937506*g1220tn+0.3053106933;
	if g1260t=. then g1260t = 1.2930594085*g1260tn+3.7342019101;
	if g2147t=. then g2147t = 0.8953352697*g2147tn+3.1636347071;
	if g2866t=. then g2866t = 1.5055436803*g2866tn+5.0151520317;
	if g3549=. then g3549 = 0.3267567924*g3549n+0.263653971;
	if g561t=. then g561t = 0.7146342207*g561tn+0.7814106663;
	if g580a=. then g580a = 0.4781340228*g580an+1.0335924412;
	if g852=. then g852 = 0.5289504339*g852n+0.7333016528;
	if g860=. then g860 = 0.4091936005*g860n+1.0592613613;
	if pb1680t=. then pb1680t = 1.1237183036*pb1680tn+1.0168947464;
run;
