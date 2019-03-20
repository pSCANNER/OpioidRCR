/*---------------------------------------------------------------------------------------------------*/
/* 11.0 Rewrite log to mask low cell count                                                                        */
/*---------------------------------------------------------------------------------------------------*/

*Determine threshold category;
%let THRESHOLDCAT=?;
%macro createThreshOldCat();
	%if %eval(&THRESHOLD.=0) %then %do;
		%let THRESHOLDCAT=0;
	%end;
	%if %eval(0<&THRESHOLD. & &THRESHOLD.<11) %then %do;
		%let THRESHOLDCAT=1-10;
	%end;
	%if %eval(10<&THRESHOLD. & &THRESHOLD.<21) %then %do;
		%let THRESHOLDCAT=11-20;
	%end;
	%if %eval(21<&THRESHOLD. & &THRESHOLD.<50) %then %do;
		%let THRESHOLDCAT=21-50;
	%end;
	%if %eval(51<&THRESHOLD. & &THRESHOLD.<100) %then %do;
		%let THRESHOLDCAT=51-100;
	%end;
	%if %eval(&THRESHOLD.>100) %then %do;
		%let THRESHOLDCAT=100+;
	%end;
%mend createThreshOldCat;
%createThreshOldCat();

%put &THRESHOLDCAT.;

*Load log file into dataset;
data _log;
infile "&DRNOC.Opioid_RCR.log" truncover;
input var1 $1000.;
run;

*copy log to dmlocal;
data _null_ ;          							*No SAS data set is created; 
    set _log; 
    FILE  "&DMLocal.Opioid_RCR.log" ;     *Output Text File; 
    PUT var1; 
run ;

*Add a header to the log;
data _header;
format var1 $1000.;
var1="Note: This SAS log has all numbers less than the low cell count threshold entered in the master.sas file masked.";
output;
var1="";
output; 
run;

*Find OBSERVATIONS keyword to replace low cell counts;
data _log;
set _header _log;
format num $10. var2 $1030.;
pos=indexw(var1,"observations");
pos1=indexw(var1,"rows");
pos2=indexw(var1,"THRESHOLD resolves to");
pos3=indexw(var1,"< CritCnt <");
pos4=indexw(var1,"< Excluded <");
var2=var1;
if pos>0 then do;
	num=scan(var1,countw(substr(var1,1,pos-1)));
	if missing(num)=1 then num=".";
	if (upcase(num) not in("NO","SELECT")) then do;
		if 0 < input(num,best.) < &threshold. then do;
			var2=TRANWRD(var1,compress(num),"[number is masked (&thresholdcat.)]");
		end;
	end;
end;
if pos1>0 then do;	
	num=scan(var1,countw(substr(var1,1,pos1-1)));
	if missing(num)=1 then num=".";
	if (upcase(num) not in("NO","SELECT")) then do;
		if 0 < input(num,best.) < &threshold. then do;
			var2=TRANWRD(var1,compress(num),"[number is masked (&thresholdcat.)]");
		end;
	end;
end;
if pos2>0 then do;
	num=scan(var1,countw(substr(var1,1,pos2+22)));	
	var2=TRANWRD(var1,compress(num),"[number is masked (&thresholdcat.)]");
end;
if pos3>0 then do;
	num=scan(var1,countw(substr(var1,1,pos3+12)));	
	var2=TRANWRD(var1,compress(num),"[number is masked (&thresholdcat.)]");
end;
if pos4>0 then do;
	num=scan(var1,countw(substr(var1,1,pos4+13)));	
	var2=TRANWRD(var1,compress(num),"[number is masked (&thresholdcat.)]");
end;
run;

*Output altered log;
data _null_ ;          							*No SAS data set is created; 
    set _log; 
    FILE  "&DRNOC.Opioid_RCR.log" ;     *Output Text File; 
    PUT var2; 
run ;

proc datasets library=work memtype=data kill nolist nowarn;
quit;
