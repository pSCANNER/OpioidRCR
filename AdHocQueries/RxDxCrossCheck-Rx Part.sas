/*1) Edit this section to define the macro parameters;*/

*Values below the TOP_N_DX_BY_FREQ parameter will be used as number of DX codes that will be used;
%let TOP_N_DX_BY_FREQ =100;

/*4) Edit this section to reflect locations for the libraries/folders for PCORNET Dataand Output folders*/
/********** FOLDER CONTAINING INPUT DATA FILES AND CDM DATA ***************************************/
/* IMPORTANT NOTE: end of path separators are needed;                                               */
/*   Windows-based platforms:    "\", e.g. "C:\user\sas\" and not "C:\user\sas";                    */
/*   Unix-based platforms:      "/", e.g."/home/user/sas/" and not "/home/user/sas";                */
/*                                                                                                  */
/********** FOLDER CONTAINING INPUT DATA FILES AND CDM DATA ***************************************/;

/*Data in CDM Format*/          libname indata '/schaeffer-a/sch-projects/dua-data-projects/PSCANNER/data/';

/*NDC/ICD9 Codes File Location*/  %LET input=/schhome/users/QiaohongHu/Opioid/input/;	
								  %LET valueset=NDC-MATCH.csv;
								  %LET drugname=rxcui_name.csv;/*This is list of raw rx names*/
								  %LET string=string-to-match.csv;/*This is list of strings that will be used to search*/								
/*SAS input Files*/              libname input "&input.";
/*CSV Output Files*/              %LET output=/schhome/users/QiaohongHu/Opioid/output/;
/*SAS Output Files*/              libname output "&output.";
/*CSV Output Files*/              %LET local=/schhome/users/QiaohongHu/Opioid/local/;
/*SAS Output Files*/              libname local "&local.";



/*---------------------------------------------------------------------------------------------------*/
/*                                       End of User Inputs                                          */
/*---------------------------------------------------------------------------------------------------*/



PROC IMPORT OUT=local.valueset
            DATAFILE= "&input&valueset"
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2;
RUN;
PROC IMPORT OUT=local.drugname
            DATAFILE= "&input&drugname"
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2;
RUN;
PROC IMPORT OUT=local.string
            DATAFILE= "&input&string"
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2;
RUN;
proc sql;
	create table want1 as
		select patid,rxnorm_cui
		from indata.prescribing
		order by rxnorm_cui;
quit;
data local.valueset;set local.valueset;if rxcui ne .;run;
proc sort data=local.valueset;
by rxcui;
run;

data want1;
set want1;
rxcui=input(rxnorm_cui,8.);
drop rxnorm_cui;
run;
proc sort data=want1;
by rxcui;
run;
data opioid1;
merge local.valueset(in=a) want1;
by rxcui;
if a;
if patid ne .;
keep patid rxcui;
run;

proc sql;
	create table rxpt as
		select distinct patid
		from opioid1 order by patid;
quit;


proc sql;
	create table want2 as
		select patid,dx,raw_dx_type
		from indata.diagnosis
		order by patid;
quit;
proc sql outobs=&TOP_N_DX_BY_FREQ;
    create table dxrx as
        select count(want2.dx) as cnt, want2.dx
        from want2,rxpt
		where want2.patid=rxpt.patid
        group by want2.dx
        order by cnt desc;
quit;

proc sort data=want2;
by dx;
run;

proc sort data=dxrx;
by dx;
run;

data opioid2;
merge want2 dxrx(in=a);
by dx;
if a;
run;

proc sort data=opioid2 nodupkey;
by patid dx;
run;
proc sort data=want1;
by patid;
run;

data rxdx;
merge opioid2(in=a) want1;
by patid;
if a;
drop cnt;
if rxcui ne .;
run;

proc sql;
create table crosscheck as
select rxcui
from rxdx
order by rxcui;
quit;

data checkresult;
merge local.valueset (in=a) crosscheck;
by rxcui;
if a then delete;
keep rxcui;
run;

proc sql;
	create table local.rxnotinc as
		select count(rxcui) as cnt,rxcui
		from checkresult
		group by rxcui
		order by cnt desc;
quit;

proc sort data=local.rxnotinc;
by rxcui;
run;

proc sort data=local.drugname;
by rxnorm_cui;
run;
data output.rxnotinc;
merge local.rxnotinc(in=a) local.drugname(rename=(rxnorm_cui=rxcui));
by rxcui;
if a;
run;

%macro missing;
proc sql noprint;
select string
into:string separated by " "
from local.string;
quit;

%LET k=1;
%LET stnm=%SCAN(&string,&k);
%DO %WHILE ("&stnm" NE "");
proc sql;
create table output.&stnm as
select rxcui,raw_rx_med_name,raw_rx_med_name,cnt,raw_rx_ndc
from output.rxnotinc
where upcase(raw_rx_med_name) contains "&stnm";
quit;
proc sort data=output.&stnm;
by descending cnt;
run;
%LET k=%EVAL(&K+1);;
%LET stnm=%SCAN(&string,&k);
%end;
%mend;
%missing;


/************************************ END OF CODE *********************************************/

