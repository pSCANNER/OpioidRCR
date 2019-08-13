
proc printto log="&DRNOC.Opioid_RCR.log"; 
run;

/*SUMMARY TABLE - ALL*/
%macro summary(tablenm,sumnm);
proc contents data=dmlocal.&tablenm out=contents (keep=name type) noprint;
run;

data vars;
 set contents;
 if type=1 and index(upcase(name),"_DATE") then chk=1;
 	else if type=1 and index(upcase(name),"CT_NALOXONE") then chk=1;
	else if upcase(name) in ("DAYSTODEATH", "BINARY_RACE", "BINARY_SEX", "BINARY_HISPANIC","AGEASOFJULY1","EVENTYEAR","FIRSTOPIOIDDATE","INDEXDATE",
		"LOOKBACK_BEFORE_INDEX_OPIOID", "OBS_START", "TIMEFROMINDEXOPIOIDTOOUD") then chk=1;
	else if type=2 then chk=1;
	else chk=0; 
run;

proc sql noprint;
select name
into: varlist separated by " "
from vars /*(obs=3)*/
where chk=0 ;
quit;

%let k=1;
%let var=%scan(&varlist,&k);
%do %while ("&var" NE "");

proc sql noprint;
create table sum_&k as
select "ALL x ALL" as Type length=50, facility_location, state, race, sex, hispanic, AGEGRP1, eventyear,
count(*) as n "total number of the observations",
nmiss(&var) as nm_&var "number of the missing values in &var",
sum(&var) as n_&var "total number of positive values in &var"
from DMLocal.&tablenm
group by facility_location, state, race, sex, hispanic, AGEGRP1, eventyear
order by facility_location, state, race, sex, hispanic, AGEGRP1, eventyear;

create table sum2_&k as
select "Facility_location x Eventyear x State" as Type, facility_location, state, eventyear,
count(*) as n "total number of the observations",
nmiss(&var) as nm_&var "number of the missing values in &var",
sum(&var) as n_&var "total number of positive values in &var"
from DMLocal.&tablenm
group by facility_location, state, eventyear
order by facility_location, state, eventyear;

create table sum3_&k as
select "State x Eventyear" as Type, state, eventyear,
count(*) as n "total number of the observations",
nmiss(&var) as nm_&var "number of the missing values in &var",
sum(&var) as n_&var "total number of positive values in &var"
from DMLocal.&tablenm
group by state, eventyear
order by state, eventyear;

create table sum4_&k as
select "Race x Eventyear x State" as Type, race, eventyear, state,
count(*) as n "total number of the observations",
nmiss(&var) as nm_&var "number of the missing values in &var",
sum(&var) as n_&var "total number of positive values in &var"
from DMLocal.&tablenm
group by race, eventyear, state
order by race, eventyear, state;

create table sum5_&k as
select "Sex x Eventyear x State" as Type, sex, eventyear, state,
count(*) as n "total number of the observations",
nmiss(&var) as nm_&var "number of the missing values in &var",
sum(&var) as n_&var "total number of positive values in &var"
from DMLocal.&tablenm
group by sex, eventyear, state
order by sex, eventyear, state;

create table sum6_&k as
select "Hispanic x Eventyear x State" as Type, hispanic, eventyear, state,
count(*) as n "total number of the observations",
nmiss(&var) as nm_&var "number of the missing values in &var",
sum(&var) as n_&var "total number of positive values in &var"
from DMLocal.&tablenm
group by hispanic, eventyear, state
order by hispanic, eventyear, state;

create table sum7_&k as
select "Agegrp1 x Eventyear x State" as Type, AGEGRP1, eventyear, state,
count(*) as n "total number of the observations",
nmiss(&var) as nm_&var "number of the missing values in &var",
sum(&var) as n_&var "total number of positive values in &var"
from DMLocal.&tablenm
group by AGEGRP1, eventyear, state
order by AGEGRP1, eventyear, state;
quit;

proc append base=sum_&k data=sum2_&k force nowarn; run;
proc append base=sum_&k data=sum3_&k force nowarn; run;
proc append base=sum_&k data=sum4_&k force nowarn; run;
proc append base=sum_&k data=sum5_&k force nowarn; run;
proc append base=sum_&k data=sum6_&k force nowarn; run;
proc append base=sum_&k data=sum7_&k force nowarn; run;
proc sort data=sum_&k; by type facility_location state race sex hispanic AGEGRP1 eventyear;run;

data sum_&k;
  set sum_&k;
  if 0 < n < &THRESHOLD then n = .t;
  if 0 < n_&var < &THRESHOLD then n_&var = .t;
  if 0 < nm_&var < &THRESHOLD then nm_&var = .t;
  %LET k=%EVAL(&k+1);
  %LET var=%SCAN(&varlist,&k);
  %end;
  %LET k=%EVAL(&k-1);
data DRNOC.&sumnm;
  merge sum_1-sum_&k;
  by type facility_location state race sex hispanic AGEGRP1 eventyear;
run;

PROC EXPORT DATA=DRNOC.&sumnm
            OUTFILE= "&DRNOC&sumnm..csv" 
            DBMS=CSV REPLACE;
RUN;

%mend summary;

/*All*/
%summary(opioid_flat_file,sum_all);


%macro tab(name, var);
PROC SQL NOPRINT;
  CREATE TABLE DMLocal.&name AS
  SELECT *
  FROM DMLocal.opioid_flat_file
  WHERE &var =1
  ;
QUIT;
%mend tab;
/*SUMMARY TABLE - Guideline A*/
%tab(opioid_flat_file_GL_A, GL_A_DENOM_FOR_ST) 
%summary(opioid_flat_file_GL_A,sum_all_GL_A)
/*SUMMARY TABLE - Guideline B*/
%tab(opioid_flat_file_GL_B, GL_B_DENOM_FOR_ST) 
%summary(opioid_flat_file_GL_B,sum_all_GL_B)
/*SUMMARY TABLE - CHRONIC OPIOID USE*/
%tab(opioid_flat_file_cou, CHRONIC_OPIOID_IND) 
%summary(opioid_flat_file_cou,sum_chronic_opioid)
/*SUMMARY TABLE - OUD current*/
%tab(opioid_flat_file_oud, opioid_ud_any_cy)   
%summary(opioid_flat_file_oud,sum_oud);
/*SUMMARY TABLE -OVERDOSE current*/
%tab(opioid_flat_file_odh, od_cy)
%summary(opioid_flat_file_odh,sum_overdose)
/*SUMMARY TABLE -OUD or SUD current*/
%tab(opioid_flat_file_osud, oud_sud_cy)
%summary(opioid_flat_file_osud,sum_osud)
/*SUMMARY TABLE -SUD current*/
%tab(opioid_flat_file_sud, substance_ud_any_cy)
%summary(opioid_flat_file_sud,sum_sud)
/*SUMMARY TABLE -AUD current*/
%tab(opioid_flat_file_aud, alcohol_ud_any_cy)
%summary(opioid_flat_file_aud,sum_aud)
/*SUMMARY TABLE - OPIOID EXPOSURE */
%tab(opioid_flat_file_oep, OPIOID_EXP_IND)
%summary(opioid_flat_file_oep,sum_opioid_exposure)
