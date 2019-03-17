
proc printto log="&DRNOC.Opioid_RCR.log"; run;




data dmlocal.opioid_flat_model;
set dmlocal.opioid_flat_file;
TimeFromIndexOpioidToOUD=Opioid_Use_DO_Post_date - FirstOpioidDate;


run;
data dmlocal.opioid_flat_model;
set dmlocal.opioid_flat_model;
if TimeFromIndexOpioidToOUD>0 then Opioid_Use_DO_indicator=1;
else Post_Rx_Opioid_Use_DO_indicator=0;
run;
proc sort data=dmlocal.opioid_flat_file;
by encounterid;
run;
proc sort data=indata.encounter;
by encounterid;
run;
data dmlocal.opioid_flat_file;
merge indata.encounter(keep=encounterid providerid) dmlocal.opioid_flat_file(in=a);
by encounterid;
if a;
run;
data dmlocal.opioid_flat_file_exc_cancer;
set dmlocal.opioid_flat_file;
where Cancer_Inpt_Dx_Year_Prior=0 and CANCER_PROC_FLAG=0;
run;

data dmlocal.opioid_flat_file_binary;
set dmlocal.opioid_flat_file_exc_cancer;
format BINARY_RACE $10. BINARY_SEX $10. BINARY_HISPANIC $10.;
IF race IN ("NI","OT") then BINARY_RACE = "MISSING";
ELSE IF race="05" then BINARY_RACE = "01";
ELSE BINARY_RACE = "00";
IF sex in ("NI","OT") then BINARY_SEX = "MISSING";
ELSE IF sex = "F" then BINARY_SEX="01";
ELSE BINARY_SEX ="00";
IF hispanic IN ("NI","OT") then BINARY_HISPANIC= "MISSING";
ELSE IF hispanic = "Y" then BINARY_HISPANIC="01";
ELSE BINARY_HISPANIC = "00";
drop race sex hispanic;
run;

proc sort data=dmlocal.opioid_flat_file;
by patid eventyear;
run;

data opioid_flat_model;
set dmlocal.opioid_flat_file; 
by patid;
retain count 0;
if first.patid then count=0;
if opioid_flag=1 then count=1;
run;
data opioid_flat_model;
set opioid_flat_model;
retain opioid_any_prior;
by patid;
if first.patid then opioid_any_prior=0;
opioid_any_prior+count;
run;

proc sort data=opioid_flat_model out=dmlocal.opioid_flat_model;
by patid descending opioid_any_prior descending eventyear;
where opioid_any_prior in (0,1);
run;

data dmlocal.opioid_flat_model;
set dmlocal.opioid_flat_model;
by patid;
if first.patid;
drop count;
run;

data dmlocal.opioid_flat_model_exc_cancer;
set dmlocal.opioid_flat_model;
where Cancer_Inpt_Dx_Year_Prior=0 and CANCER_PROC_FLAG=0;
run;


/*SUMMARY TABLE - ALL*/
%macro summary(tablenm,sumnm);
proc contents data=dmlocal.&tablenm out=contents (keep=name type) noprint;
run;

proc sql noprint;
select name
into: varlist separated by " "
from contents
where type = 1 AND name not in ("facility_location","race","sex","hispanic","AGEGRP1","eventyear") ;
quit;

ods select nlevels;
ods table nlevels=n_levels;
proc freq data=dmlocal.&tablenm nlevels noprint;
table &varlist ;
run;

proc sql noprint;
select tablevar
into:binvar separated by " "
from n_levels
where nlevels <= 2;
quit;

%let k=1;
%let var=%scan(&binvar,&k);
%do %while ("&var" NE "");

proc sql noprint;
create table sum_&k as
select facility_location, race, sex, hispanic, AGEGRP1, eventyear,
count(*) as n "total number of the observations",
nmiss(&var) as nm_&k "number of the missing values in &var",
sum(&var) as n_&k "total number of positive values in &var"
from DMLocal.&tablenm
group by facility_location, race, sex, hispanic, AGEGRP1, eventyear
order by facility_location, race, sex, hispanic, AGEGRP1, eventyear;
quit;

data sum_&k;
  set sum_&k;
  if 0 < n < &THRESHOLD then n = .t;
  if 0 < n_&k < &THRESHOLD then n_&k = .t;
  if 0 < nm_&k < &THRESHOLD then nm_&k = .t;
  %LET k=%EVAL(&k+1);
  %LET var=%SCAN(&binvar,&k);
  %end;
  %LET k=%EVAL(&k-1);
data DRNOC.&sumnm;
  merge sum_1-sum_&k;
  by facility_location race sex hispanic AGEGRP1 eventyear;
run;

%mend summary;

%summary(opioid_flat_file,sum_all);

/*SUMMARY TABLE - ALL NO CANCER*/
PROC SQL NOPRINT;
  CREATE TABLE DMLocal.opioid_flat_file_exc_cancer AS
  SELECT *
  FROM DMLocal.opioid_flat_file
  WHERE Cancer_Inpt_Dx_Year_Prior=0 AND CANCER_PROC_FLAG=0
  ;
QUIT;

%summary(opioid_flat_file_exc_cancer,sum_all_exc_cancer);

/*SUMMARY TABLE - STD HISTORY*/
PROC SQL NOPRINT;
  CREATE TABLE DMLocal.opioid_flat_file_std AS
  SELECT *
  FROM DMLocal.opioid_flat_file_exc_cancer
  WHERE ADMIT_DATE IS NOT NULL AND ANY_STD_Year_Prior=1
  ;
QUIT;

%summary(opioid_flat_file_std,sum_std);

/*SUMMARY TABLE - CHRONIC OPIOID USE HISTORY*/
PROC SQL NOPRINT;
  CREATE TABLE DMLocal.opioid_flat_file_cou AS
  SELECT *
  FROM DMLocal.opioid_flat_file_exc_cancer
  WHERE ADMIT_DATE IS NOT NULL AND CHRONIC_OPIOID_CURRENT_PRIOR = 1
  ;
QUIT;

%summary(opioid_flat_file_cou,sum_chronic_opioid);

/*SUMMARY TABLE -OVERDOSE HISTORY*/
PROC SQL NOPRINT;
  CREATE TABLE DMLocal.opioid_flat_file_odh AS
  SELECT *
  FROM DMLocal.opioid_flat_file_exc_cancer
  WHERE ADMIT_DATE IS NOT NULL AND OD_PRE = 1
  ;
QUIT;

%summary(opioid_flat_file_odh,sum_overdose);

/*SUMMARY TABLE -SUD Only*/
PROC SQL NOPRINT;
  CREATE TABLE DMLocal.opioid_flat_file_sud AS
  SELECT *
   FROM DMLocal.opioid_flat_file_exc_cancer(where=(ADMIT_DATE IS NOT NULL))
  WHERE Substance_Use_DO_Any_Prior = 1 AND Opioid_Use_DO_Any_Prior ne 1 AND Alcohol_Use_DO_Any_Prior ne 1
  ;
QUIT;

%summary(opioid_flat_file_sud,sum_sud);

/*SUMMARY TABLE -OUD+SUD, NOT AUD*/

PROC SQL NOPRINT;
  CREATE TABLE DMLocal.opioid_flat_file_osud AS
  SELECT *
   FROM DMLocal.opioid_flat_file_exc_cancer(where=(ADMIT_DATE IS NOT NULL))
  WHERE Substance_Use_DO_Any_Prior = 1 AND Opioid_Use_DO_Any_Prior = 1 AND Alcohol_Use_DO_Any_Prior ne 1
  ;
QUIT;

%summary(opioid_flat_file_osud,sum_osud);

/*SUMMARY TABLE - OUD Only*/

PROC SQL NOPRINT;
  CREATE TABLE DMLocal.opioid_flat_file_oud AS
  SELECT *
   FROM DMLocal.opioid_flat_file_exc_cancer(where=(ADMIT_DATE IS NOT NULL))
  WHERE Substance_Use_DO_Any_Prior ne 1 AND Opioid_Use_DO_Any_Prior = 1 AND Alcohol_Use_DO_Any_Prior ne 1
  ;
QUIT;

%summary(opioid_flat_file_oud,sum_oud);

/*SUMMARY TABLE -AUD Only*/

PROC SQL NOPRINT;
  CREATE TABLE DMLocal.opioid_flat_file_aud AS
  SELECT *
   FROM DMLocal.opioid_flat_file_exc_cancer(where=(ADMIT_DATE IS NOT NULL))
  WHERE Substance_Use_DO_Any_Prior ne 1 AND Opioid_Use_DO_Any_Prior ne 1 AND Alcohol_Use_DO_Any_Prior = 1
  ;
QUIT;

%summary(opioid_flat_file_aud,sum_aud);

/*SUMMARY TABLE - OPIOID EXPOSURE */

PROC SQL NOPRINT;
  CREATE TABLE DMLocal.opioid_flat_file_oep AS
  SELECT *
   FROM DMLocal.opioid_flat_file_exc_cancer(where=(ADMIT_DATE IS NOT NULL))
  WHERE  Opioid_flag = 1 
  ;
QUIT;

%summary(opioid_flat_file_oep,sum_opioid_exposure);

/*SUMMARY TABLE - PROVIDER LEVEL*/


proc sql noprint;
create table mixedmodel as
select*,sum(opioid_flag) as sum, count(*) as cnt
from dmlocal.opioid_flat_model_exc_cancer
group by providerid,eventyear;
quit;

data dmlocal.mixedmodel;
set mixedmodel;
OPIOID_RX_RATE=sum/cnt;
drop sum cnt;
run;

%macro providersummary(tablenm,sumnm);

proc contents data=dmlocal.&tablenm out=contents (keep=name type) noprint;
run;

proc sql noprint;
select name
into: varlist separated by " "
from contents
where type = 1 AND name not in ("facility_location","race","sex","hispanic","AGEGRP1","eventyear") ;
quit;

ods select nlevels;
ods table nlevels=n_levels;
proc freq data=dmlocal.&tablenm nlevels noprint;
table &varlist ;
run;

proc sql noprint;
select tablevar
into:binvar separated by " "
from n_levels
where nlevels <= 2;
quit;

%let k=1;
%let var=%scan(&binvar,&k);
%do %while ("&var" NE "");


proc sql;
create table sum_&k as
select facility_location, race, sex, hispanic, agegrp1, eventyear,providerid,
count(*) as n "total number of the observations",
count(&var) as n_&k "number of the non-missing values in &var" ,
nmiss(&var) as nm_&k "number of the missing values in &var" 
from dmlocal.&tablenm
group by facility_location, race, sex, hispanic, agegrp1, eventyear, providerid
order by facility_location, race, sex, hispanic, agegrp1, eventyear, providerid;
quit;

data sum_&k;
set sum_&k;
if 0<n<&threshold then n=.t;
if 0<n_&k<&threshold then n_&k=.t;
if 0<nm_&k<&threshold then nm_&k=.t;
%LET k=%EVAL(&k+1);
%LET var=%SCAN(&binvar,&k);
%end;
%LET k=%EVAL(&k-1);
data DRNOC.&sumnm;
merge sum_1-sum_&k;
by facility_location race sex hispanic agegrp1 eventyear providerid;
run;

%mend providersummary(tablenm,sumnm);

%providersummary(mixedmodel,sum_provider);

/*Summary Table - all non cancer (strata B) - BINARY*/

%macro binarysummary(tablenm,sumnm);
proc contents data=dmlocal.&tablenm out=contents (keep=name type) noprint;
run;

proc sql noprint;
select name
into: varlist separated by " "
from contents
where type = 1 AND name not in ("facility_location","BINARY_RACE","BINARY_SEX","BINARY_HISPANIC",,"eventyear") ;
quit;

ods select nlevels;
ods table nlevels=n_levels;
proc freq data=dmlocal.&tablenm nlevels noprint;
table &varlist ;
run;

proc sql noprint;
select tablevar
into:binvar separated by " "
from n_levels
where nlevels <= 2;
quit;

%let k=1;
%let var=%scan(&binvar,&k);
%do %while ("&var" NE "");

proc sql noprint;
create table sum_&k as
select facility_location, binary_race, binary_sex, binary_hispanic,  eventyear,
mean(AgeAsOfJuly1) as mean_age "mean age of each strata" format=10.,
count(*) as n "total number of the observations",
nmiss(&var) as nm_&k "number of the missing values in &var",
sum(&var) as n_&k "total number of positive values in &var"
from DMLocal.&tablenm
group by facility_location, binary_race, binary_sex, binary_hispanic,  eventyear
order by facility_location, binary_race, binary_sex, binary_hispanic, eventyear;
quit;

data sum_&k;
  set sum_&k;
  if 0 < n < &THRESHOLD then n = .t;
  if 0 < n_&k < &THRESHOLD then n_&k = .t;
  if 0 < nm_&k < &THRESHOLD then nm_&k = .t;
  %LET k=%EVAL(&k+1);
  %LET var=%SCAN(&binvar,&k);
  %end;
  %LET k=%EVAL(&k-1);
data DRNOC.&sumnm;
  merge sum_1-sum_&k;
  by facility_location binary_race binary_sex binary_hispanic eventyear;
run;

%mend binarysummary;

%binarysummary(opioid_flat_file_binary,sum_binary);

%put Turning off log capturing to rewrite log file and mask all numbers less than the low cell count threshold;
proc printto; run;
