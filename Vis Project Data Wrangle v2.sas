/*When adjusting this line for your personal directories, copy it and change the path--DON'T delete it.*/
%let path = C:\Users\Bill\Documents\NCSU\Course Work\Fall\Visualization\Well_Data;

/*Define macro variables for each well file as well as for other uses*/
%let well_1 = F-179;
%let well_2 = F-319;
%let well_3 = F-45;
%let well_4 = G-1220_T;
%let well_5 = G-1260_T;
%let well_6 = G-2147_T;
%let well_7 = G-2866_T;
%let well_8 = G-3549;
%let well_9 = G-561_T;
%let well_10 = G-580A;
%let well_11 = G-852;
%let well_12 = G-860;
%let well_13 = PB-1680_T;

%let well2_1 = F179;
%let well2_2 = F319;
%let well2_3 = F45;
%let well2_4 = G1220;
%let well2_5 = G1260;
%let well2_6 = G2147;
%let well2_7 = G2866;
%let well2_8 = G3549;
%let well2_9 = G561;
%let well2_10 = G580;
%let well2_11 = G852;
%let well2_12 = G860;
%let well2_13 = PB1680;


%macro loadwell;
	%do i=1 %to 13;
	/*Importing to a Permenant Data set. Update your path to your own local drive
  	  Right now, each well data set has to be manually changed in this step and the proc sql step*/
	PROC IMPORT OUT= Well_Data DATAFILE= "&path.\&&well_&i...xlsx"
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
		Create Table visproj.&&well2_&i as
		Select
			Date, Hour,	AVG(Corrected) as Depth
		From
			Well_Data_Modified
		Group BY
			Date, Hour
		Order By
			Date, Hour
		; Quit;
	%end;
%mend loadwell;

%loadwell

/*Drop extra observations before Oct 1, 2007 from well G-852*/
data visproj.&well2_11;
	set visproj.&well2_11;
	if date >= "01Oct2007"d;
run;

/*Create ideal date sequence by hour*/
data ideal(keep = date hour);
	date = "01Oct2007"d;
	format date MMDDYY10.;
	do until (date = "08Jun2018"d and hour = 23);
		do i = 0 to 23;
			hour = i;
			output;
		end;
		date + 1;
	end;
run;

/*Merge all wells into the same data set*/
%macro mergewells;
	data visproj.all_wells;
		merge   ideal
			%do i=1 %to 13;
				visproj.&&well2_&i(rename=(depth = &&well2_&i))
			%end;;
		by date hour;
	run;
%mend mergewells;

%mergewells

/* Normalize all the well data*/

%macro normwells;
	proc sql;
		create table visproj.normwells as
		select date, 
		%do i=1 %to 13;
		 	(&&well2_&i-mean(&&well2_&i))/std(&&well2_&i) as &&well2_&i..N,
		%end; hour
		from visproj.all_wells;
	quit;	
%mend normwells;

%normwells

/* Impute missing values using */

%macro imputewells;
	data visproj.imputed_normal;
		set visproj.normwells;
		where date > "30Sep2007"d;
		impute = mean(&well2_1.N, &well2_2.N, &well2_3.N, &well2_4.N, &well2_5.N, &well2_6.N, &well2_7.N, &well2_8.N,
				  &well2_9.N, &well2_10.N, &well2_11.N, &well2_12.N, &well2_13.N);
	%do i=1 %to 13;
		if &&well2_&i..N=. then &&well2_&i..N = impute;
	%end;
		run;
%mend imputewells;

%imputewells

/*Calculate mean and standard deviation of original time series*/
proc sql;
	create table visproj.stats as
	select mean(f179) as f179m, std(f179) as f179sd,
	       mean(f319) as f319m, std(f319) as f319sd,
		   mean(f45) as f45m, std(f45) as f45sd,
		   mean(g1220) as g1220m, std(g1220) as g1220sd,
		   mean(g1260) as g1260m, std(g1260) as g1260sd,
		   mean(g2147) as g2147m, std(g2147) as g2147sd,
		   mean(g2866) as g2866m, std(g2866) as g2866sd,
		   mean(g3549) as g3549m, std(g3549) as g3549sd,
		   mean(g561) as g561m, std(g561) as g561sd,
		   mean(g580) as g580m, std(g580) as g580sd,
		   mean(g852) as g852m, std(g852) as g852sd,
		   mean(g860) as g860m, std(g860) as g860sd,
		   mean(pb1680) as pb1680m, std(pb1680) as pb1680sd
	from visproj.all_wells;
quit;

/*Change normalized data back to original with imputed values*/
data visproj.all_wells_imputed;
	merge visproj.imputed_normal visproj.all_wells;
	by date hour;
	where date > "30Sep2007"d;
	if f179=. then f179 = 0.5413844879*f179n+0.7023787213;
	if f319=. then f319 = 0.4008264697*f319n+0.82223807;
	if f45=. then f45= 0.59710404119*f45n+0.7396640008;
	if g1220=. then g1220 = 0.6814937506*g1220n+0.3053106933;
	if g1260=. then g1260 = 1.2930594085*g1260n+3.7342019101;
	if g2147=. then g2147 = 0.8953352697*g2147n+3.1636347071;
	if g2866=. then g2866 = 1.5055436803*g2866n+5.0151520317;
	if g3549=. then g3549 = 0.3267567924*g3549n+0.263653971;
	if g561=. then g561 = 0.7146342207*g561n+0.7814106663;
	if g580=. then g580 = 0.4781340228*g580n+1.0335924412;
	if g852=. then g852 = 0.5289504339*g852n+0.7333016528;
	if g860=. then g860 = 0.4091936005*g860n+1.0592613613;
	if pb1680=. then pb1680 = 1.1237183036*pb1680n+1.0168947464;
	if date > "08Jun2018"d or date=. then;
	else output;
run;

%let span = 720;

/*Run ARIMA model for each well*/
%macro arima;
	%do i=1 %to 13;
		proc arima data=visproj.all_wells_imputed plot=all;
			identify var=&&well2_&i(1) nlag=80;
			estimate p=2 q=7 method=ml;
			forecast back=&span lead=&span out=&&well2_&i;
		run;
		quit;
	%end;
%mend arima;

%arima

/*Calculate MAPE for each well*/
%macro mape;
	%do i=1 %to 13;
		Data Pre_MAPE&i;
			set &&well2_&i nobs=total;
			Pre_MAPE&i = abs(RESIDUAL/&&well2_&i);
			MAE&i = abs(Residual);
			if _n_ > total-&span;
		run;

		Proc sql;
			select mean(pre_mape&i) as MAPE&i, mean(mae&i) as MAE&i
			from pre_mape&i;
		quit;
	%end;
%mend mape;

%mape

/*Reorganize data for Tableau plotting*/
%macro organize;
/*	Change name of actual data to "ACTUAL" in ARIMA output datasets*/
	%do i=1 %to 13;
		data &&well2_&i;
			set &&well2_&i(rename=(&&well2_&i=actual));
			well = "&&well2_&i";
		run;

/*	Merge ARIMA output data with ideal date series*/
		data &&well2_&i;
			merge ideal &&well2_&i;
		run;
	%end;
%mend organize;

%organize

/*Combine all datasets for Tableau*/
%macro combine;
data visproj.forTableau;
	length well $ 6;
	set %do i=1 %to 13; &&well2_&i %end;;
run;
%mend combine;

%combine

/*Add Lat and Long coordinates as well as MAPE, MAE, and model*/
data visproj.fortableau;
	set visproj.fortableau;
	select(strip(well));
		when('G3549') do;
			latitude = 25.49305556;
			longitude = -80.34916667;
			MAPE = 0.578721; 
			MAE = 0.187873;
			Model = "Arima(2,1,7)";
			end;
		when('G860') do;
			latitude = 25.62194444;
			longitude = -80.32277778;
			MAPE = 0.318903 ; 
			MAE = 0.271878;
			Model = "Arima(2,1,7)";
			end;
		when('G580') do;
			latitude = 25.66722222;
			longitude = -80.30250000;
			MAPE = 0.29329; 
			MAE = 0.38472;
			Model = "Arima(2,1,7)";
			end;
		when('F179') do;
			latitude = 25.74555556;
			longitude = -80.24638889;
			MAPE = 0.915321; 
			MAE = 0.885944;
			Model = "Arima(2,1,7)";
			end;
		when('F319') do;
			latitude = 25.70472222;
			longitude = -80.28833333;
			MAPE = 0.353586; 
			MAE = 0.368216;
			Model = "Arima(2,1,7)";
			end;
		when('F45') do;
			latitude = 25.82888889;
			longitude = -80.20416667;
			MAPE =0.975333; 
			MAE = 1.082993;
			Model = "Arima(2,1,7)";
			end;
		when('G852') do;
			latitude = 25.91027778;
			longitude = -80.17555556;
			MAPE = 0.688452; 
			MAE = 1.0161791;
			Model = "Arima(2,1,7)";
			end;
		when('G561') do;
			latitude = 26.09583333;
			longitude = -80.13888889;
			MAPE = 0.610515; 
			MAE = 1.296146;
			Model = "Arima(2,1,7)";
			end;
		when('G1220') do;
			latitude = 26.13111111;
			longitude = -80.14638889;
			MAPE = 2.114E12; 
			MAE = 1.2682;
			Model = "Arima(2,1,7)";
			end;
		when('G2147') do;
			latitude = 26.25055556;
			longitude = -80.10138889;
			MAPE = 0.317931; 
			MAE = 1.5564261;
			Model = "Arima(2,1,7)";
			end;
		when('G1260') do;
			latitude = 26.31777778;
			longitude = -80.11527778;
			MAPE = 0.429088; 
			MAE = 2.520005;
			Model = "Arima(2,1,7)";
			end;
		when('G2866') do;
			latitude = 26.27805556;
			longitude = -80.11305556;
			MAPE = 0.355103; 
			MAE = 2.920378;
			Model = "Arima(2,1,7)";
			end;
		when('PB1680') do;
			latitude = 26.36666667;
			longitude = -80.09472222;
			MAPE = 1.083209; 
			MAE = 1.809895;
			Model = "Arima(2,1,7)";
			end;
		otherwise;
	end;
run;

data visproj.fortableau;
	set visproj.fortableau;
	datetime = dhms(date, hour, 0, 0);
	CI_95 = u95-l95;
	format datetime datetime20.;
run;

proc export data=visproj.fortableau outfile="&path.\allwellstableau.csv"
            DBMS=csv REPLACE;
run;
