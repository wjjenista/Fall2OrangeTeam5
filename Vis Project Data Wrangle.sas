%let path = C:\Users\Bill\Documents\NCSU\Course Work\Fall\Visualization\Well_Data;

/*Importing to a Permenat Data set. Update your path to your own local drive*/
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

/*Open csv file*/
ods csvall file="&path.\All Wells.csv";

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

ods csvall close;	

