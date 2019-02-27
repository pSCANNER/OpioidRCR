

%let threshold=11;


/*SUMMARY TABLE - ALL*/
%macro summary(tablenm,sumnm);
proc contents data=&tablenm out=contents (keep=name) noprint;
run;

proc sql noprint;
select name
into: varlist separated by " "
from contents
where name not in ("facility_location","race","sex","hispanic","AgeAsOfJuly1","eventyear");
quit;

%let k=1;
%let var=%scan(&varlist,&k);
%do %while ("&var" NE "");

proc sql;
create table sum_&k as
select facility_location, race, sex, hispanic, AgeAsOfJuly1 /*I don't have agegrp now, should change to agegrp later*/, eventyear,
count(*) as n "total number of the observations",
count(&var) as n_&k "number of the non-missing values in &var" ,
nmiss(&var) as nm_&k "number of the missing values in &var" 
from &tablenm
group by facility_location, race, sex, hispanic, AgeAsOfJuly1, eventyear
order by facility_location, race, sex, hispanic, AgeAsOfJuly1, eventyear;
quit;

data sum_&k;
set sum_&k;
if 0<n<&threshold then n=.t;
if 0<n_&k<&threshold then n_&k=.t;
if 0<nm_&k<&threshold then nm_&k=.t;
%LET k=%EVAL(&k+1);
%LET var=%SCAN(&varlist,&k);
%end;
%LET k=%EVAL(&k-1);
data &sumnm;
merge sum_1-sum_&k;
by facility_location race sex hispanic AgeAsOfJuly1 eventyear;
run;

%mend summary(tablenm,sumnm);

%summary(dmlocal.opioid_flat_file,three.sum_all);

/*SUMMARY TABLE - STD HISTORY*/
PROC SQL NOPRINT;
  CREATE TABLE opioid_flat_file_std AS
  SELECT *
  FROM opioid_flat_file
  WHERE ADMIT_DATE IS NOT NULL AND ANY_STD_POST=1
  ;
QUIT;

%summary(opioid_flat_file_std,sum_std);

/*SUMMARY TABLE - CHRONIC OPIOID USE HISTORY*/
PROC SQL NOPRINT;
  CREATE TABLE opioid_flat_file_cou AS
  SELECT *
  FROM opioid_flat_file
  WHERE ADMIT_DATE IS NOT NULL AND CHRONIC_OPIOID = 1
  ;
QUIT;

%summary(opioid_flat_file_cou,sum_chronic_opioid);

/*SUMMARY TABLE -OVERDOSE HISTORY*/
PROC SQL NOPRINT;
  CREATE TABLE opioid_flat_file_odh AS
  SELECT *
  FROM opioid_flat_file
  WHERE ADMIT_DATE IS NOT NULL AND PAST_OD = 1
  ;
QUIT;

%summary(opioid_flat_file_odh,sum_overdose);

/*SUMMARY TABLE -SUD HISTORY*/
PROC SQL NOPRINT;
  CREATE TABLE opioid_flat_file_sud AS
  SELECT *
   FROM opioid_flat_file(where=(ADMIT_DATE IS NOT NULL))
  WHERE SedHypAnx_Use_DO_Any_Prior = 1 AND Opioid_Use_DO_Any_Prior ne 1 AND Alcohol_Use_DO_Any_Prior ne 1
  ;
QUIT;

%summary(opioid_flat_file_sud,sum_sud);

/*SUMMARY TABLE -OUD+SUD, NOT AUD*/

PROC SQL NOPRINT;
  CREATE TABLE opioid_flat_file_osud AS
  SELECT *
   FROM opioid_flat_file(where=(ADMIT_DATE IS NOT NULL))
  WHERE SedHypAnx_Use_DO_Any_Prior = 1 AND Opioid_Use_DO_Any_Prior = 1 AND Alcohol_Use_DO_Any_Prior ne 1
  ;
QUIT;

%summary(opioid_flat_file_osud,sum_osud);


/*SUMMARY TABLE - OUD */

PROC SQL NOPRINT;
  CREATE TABLE opioid_flat_file_oud AS
  SELECT *
   FROM opioid_flat_file(where=(ADMIT_DATE IS NOT NULL))
  WHERE  Opioid_Use_DO_Any_Prior = 1 
  ;
QUIT;

%summary(opioid_flat_file_oud,sum_oud);

/*SUMMARY TABLE - OPIOID EXPOSURE */

PROC SQL NOPRINT;
  CREATE TABLE opioid_flat_file_oep AS
  SELECT *
   FROM opioid_flat_file(where=(ADMIT_DATE IS NOT NULL))
  WHERE  Opioid_flag = 1 
  ;
QUIT;

%summary(opioid_flat_file_oep,sum_opioid_exposure);
