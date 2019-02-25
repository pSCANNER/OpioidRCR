%let threshold=11;

PROC FORMAT;
VALUE mask
0- &threshold = "**********";
RUN;

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
create table sum1_&k as
select facility_location, race, sex, hispanic, AgeAsOfJuly1 /*I don't have agegrp now, should change to agegrp later*/, eventyear,
count(*) as n "total number of the observations" format=mask.,
count(&var) as n_&k "number of the non-missing values in &var" format=mask.,
nmiss(&var) as nm_&k "number of the missing values in &var" format=mask.
from &tablenm
group by facility_location, race, sex, hispanic, AgeAsOfJuly1, eventyear
order by facility_location, race, sex, hispanic, AgeAsOfJuly1, eventyear;
quit;

%LET k=%EVAL(&k+1);
%LET var=%SCAN(&varlist,&k);
%end;
%LET k=%EVAL(&k-1);
data &sumnm;
merge sum1_1-sum1_&k;
by facility_location race sex hispanic AgeAsOfJuly1 eventyear;
run;

%mend summary(tablenm,sumnm);

%summary(opioid_flat_file,sum_all);

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
