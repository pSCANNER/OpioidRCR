
/* Edit this section to reflect locations for the libraries/folders for PCORNET Data
   and Output folders*/
%LET percent=0.8;  /*The cut off point of co-occur DX codes*/
/********** FOLDER CONTAINING INPUT DATA FILES AND CDM DATA ***************************************/
/* IMPORTANT NOTE: end of path separators are needed;                                               */
/*   Windows-based platforms:    "\", e.g. "C:\user\sas\" and not "C:\user\sas";                    */
/*   Unix-based platforms:      "/", e.g."/home/user/sas/" and not "/home/user/sas";                */
/*                                                                                                  */
/********** FOLDER CONTAINING INPUT DATA FILES AND CDM DATA ***************************************/;
/*Data in CDM Format*/          libname indata '';
/*File Location*/  		%LET input= ' ';	
								%LET valueset=NDC-MATCH.csv;
								%LET drugname=rxcui_name.csv;
								%LET string=string-to-match.csv;
/********** FOLDER CONTAINING SUMMARY FILES TO BE EXPORTED*/;
/*CSV Output Files*/              %LET output=;
/*SAS Output Files*/              libname output "&output.";
/*********** FOLDER CONTAINING FINAL DATASETS TO BE KEPT LOCAL**********/;
/*CSV Output Files*/              %LET local=;
/*SAS Output Files*/              libname local "&local.";



/*---------------------------------------------------------------------------------------------------*/
/*                                       End of User Inputs                                          */
/*---------------------------------------------------------------------------------------------------*/

/*****************************************************************************************************/
/**************************** PLEASE DO NOT EDIT CODE BELOW THIS LINE ********************************/
/*****************************************************************************************************/
PROC IMPORT OUT=local.valueset
            DATAFILE= "&input&valueset"
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


/*************TABLE1:RXCUI Table with frequency of co-occurrence with 100 most common Dx that co-occur with known RXCUI codes************/
/*1) Clean data set and extract necessary info*/
proc sql;
	create table want1 as
		select patid,rxnorm_cui,raw_rx_med_name,encounterid
		from indata.prescribing
		order by rxnorm_cui;
quit;

data local.valueset;
set local.valueset;
if rxcui ne .;
run;

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
/*2)Match known OPIOID RXCUI codes to get a list of patients whose prescriptions have OPIOID ---P(RX)*/
data opioid1;
merge local.valueset(in=a) want1;
by rxcui;
if a;
if patid ne .;
keep patid rxcui raw_rx_med_name encounterid;
run;

proc sql;
	create table opioidrx as
		select patid,encounterid
		from opioid1 
		order by patid,encounterid;
quit;

/*3)Get a list of patient with DX codes from diagnosis table ---P(DX)*/
proc sql;
	create table want2 as
		select patid,dx,raw_dx_type,encounterid
		from indata.diagnosis
		order by patid;
quit;
/*4)Match OPIOID patient list to get list of 80% most common DX that co-occur with known RXCUI codes ---P(DX|RX)*/
proc sql;
    create table dxcount as
        select count(dx) as fdx,dx
        from want2
        group by dx
        order by fdx desc;
quit;
proc sort data=want2;
by patid encounterid;
run;

data dxrx1;
merge want2 opioidrx(in=a);
by patid encounterid;
if a;
run;
proc sql;
create table dxrx2 as
select dxrx1.dx,dxcount.fdx
from dxrx1,dxcount
where dxrx1.dx=dxcount.dx;
quit;

proc sort data=dxrx2 nodupkey;
by dx;
run;
proc sort data=dxrx2;
by descending fdx;
run;

PROC SQL noprint;
SELECT count(*) into :obs
FROM dxrx2;
QUIT;

%let TOP_N_DX_BY_FREQ =%sysevalf(&obs *&percent,integer);

data dxrx;
set dxrx2(obs=&TOP_N_DX_BY_FREQ);
run;


/*5)Match known DX codes with P(DX) list and get a list of patient from diagnosis table whose prescription have OPIOID ---P(DX|RX)'*/
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

/*6)Match back P(DX|RX)' with want1(RXCUI codes list from prescribing table) and delete those who has already existed in value set --- P(RX'|DX|RX) */
proc sql;
	create table opioiddx as
		select patid,encounterid
		from opioid2 
		order by patid,encounterid;
quit;

proc sql;
    create table rxcount as
        select count(rxcui) as frx,rxcui
        from want1
        group by rxcui;
quit;

proc sort data=want1;
by patid encounterid;
run;

data rxdx1;
merge want1 opioiddx(in=a);
by patid encounterid;
if a;
if rxcui ne .;
run;
proc sql;
create table rxdx2 as
select rxdx1.rxcui,rxcount.frx,rxdx1.raw_rx_med_name
from rxdx1,rxcount
where rxdx1.rxcui=rxcount.rxcui;
quit;

proc sort data=rxdx2 nodupkey;
by rxcui;
run;

data rxdx;
merge rxdx2 local.valueset(in=a);
by rxcui;
if a then delete;
run;

data output.table1;
set rxdx;
run;


/*************TABLE2:Table with frequency overll (not co-occurring)************/
/*1) Clean data set and extract necessary info*/
proc sql;
	create table want1 as
		select patid,rxnorm_cui,raw_rx_med_name,encounterid
		from indata.prescribing
		order by rxnorm_cui;
quit;
data want1;
set want1;
rxcui=input(rxnorm_cui,8.);
drop rxnorm_cui;
run;
proc sql;
	create table want2 as
		select patid,dx,raw_dx_type,encounterid
		from indata.diagnosis
		order by patid;
quit;
/*2) Use sql to get frequencies*/
proc sql;
    create table rxcount as
        select count(rxcui) as frx,rxcui,raw_rx_med_name
        from want1
        group by rxcui;
quit;
proc sql;
    create table dxcount as
        select count(dx) as fdx,dx
        from want2
        group by dx
        order by fdx desc;
quit;
data output.table2rx;
set rxcount;
run;
data output.table2dx;
set dxcount;
run;

/*************TABLE3:inner join Table 1 with Table 2 on RXCUI************/
proc sql; 
	create table output.table3 as 
   select * from output.table1,output.table2rx
      where table1.rxcui=table2.rxcui
	order by frx;
quit;
/*************TABLE4:search drug names in Table 3 for opioid strings, add a column 0=no match 1=match************/

%macro crosscheck;
Proc sql noprint;
      select 'Upcase(raw_rx_med_name) contains '''||strip(Upcase(string))||''''
      into :strings separated by ' OR '
      from local.string
      ;

      create table one as
      select *
      from output.table3
      where &strings;
Quit;
%mend;
%crosscheck;
data two;
set one;
match=1;
run;
proc sort data=output.table3 out=table3;
by rxcui;
run;
data output.table4;
merge two table3;
by rxcui;
run;
data output.table4;
set output.table4;
if match ne 1 then match=0;
run;
proc sort data=output.table4;
by descending frx;
run;

PROC EXPORT DATA= output.table1
            OUTFILE= "/schhome/users/QiaohongHu/Opioid/output/table1.csv" 
            DBMS=CSV LABEL REPLACE;
     PUTNAMES=YES;
RUN;
PROC EXPORT DATA= output.table2rx
            OUTFILE= "/schhome/users/QiaohongHu/Opioid/output/table2rx.csv" 
            DBMS=CSV LABEL REPLACE;
     PUTNAMES=YES;
RUN;
PROC EXPORT DATA= output.table2dx
            OUTFILE= "/schhome/users/QiaohongHu/Opioid/output/table2dx.csv" 
            DBMS=CSV LABEL REPLACE;
     PUTNAMES=YES;
RUN;
PROC EXPORT DATA= output.table3
            OUTFILE= "/schhome/users/QiaohongHu/Opioid/output/table3.csv" 
            DBMS=CSV LABEL REPLACE;
     PUTNAMES=YES;
RUN;
PROC EXPORT DATA= output.table4
            OUTFILE= "/schhome/users/QiaohongHu/Opioid/output/table4.csv" 
            DBMS=CSV LABEL REPLACE;
     PUTNAMES=YES;
RUN;
