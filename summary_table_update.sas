/* TODO
0 -- Review updates and checks requested on flat file and in google doc https://docs.google.com/spreadsheets/d/1Ts0mcbM1Pln7xcS6E6XGn53YAloMVgGBpzllkZFR6vI/edit#gid=1068010411&range=A1
1 -- DO NOT STRATIFY BY FACILITY LOCATION AND STATE IN THE SAME TABLE. ONLY INCLUDE FACILITY LOCATION IN ALL X ALL AND USE STATE IN ALL OTHERS. 
2 -- REPLACE "Facility_location x Eventyear x State" WITH A "YEAR ONLY" TABLE WITH NO OTHER STRATA (TO HELP DEBUG)
3 -- USING THE ENROLLMENT ROUTINE IN THE FLAT FILE, ADD AN INDICATOR FOR "ENROLLED" AND USE THAT TO GENERATE THE N WHERE CURRENTLY USING COUNT(*)
4 -- ADD A RT_&var (RATE) THAT IS COUNT/COUNT-NON-MISSING SO THAT THIS DOES NOT NEED TO BE CREATED POST-HOC 

08/19/19: Caron
0-Counts should be correct, please specify which summary table is having this issue
1-Updates made to the code
2-Updates made to the code
3-Will be added to the flat files once Daniella responds to email
4-Added to the code

Will re-run summary tables on full data once I am able to make updates to the flat file
*/
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

/* COUNT(*) SHOULD BE THENUMBER OF ENROLLED PATIENTS IN THE YEAR.
IT IS NOT CHANGING NOW - ADD "ENROLLED" VARIABLE TO FLAT FILE TO ENSURE IT IS ACCURATE? */
proc sql noprint;
create table sum_&k as
select "ALL x ALL" as Type length=50, facility_location, race, sex, hispanic, AGEGRP1, eventyear,state,
count(*) as n "total number of the observations",
nmiss(&var) as nm_&var "number of the missing values in &var",
sum(&var) as n_&var "total number of positive values in &var",
sum(&var)/(count(*)-nmiss(&var)) as r_&var "Rate of &var"
from DMLocal.&tablenm
group by facility_location, race, sex, hispanic, AGEGRP1, eventyear
order by facility_location, race, sex, hispanic, AGEGRP1, eventyear;

create table sum2_&k as
select "Eventyear x State" as Type, state, eventyear,
count(*) as n "total number of the observations",
nmiss(&var) as nm_&var "number of the missing values in &var",
sum(&var) as n_&var "total number of positive values in &var",
sum(&var)/(count(*)-nmiss(&var)) as r_&var "Rate of &var"
from DMLocal.&tablenm
group by eventyear, state
order by eventyear, state;

create table sum3_&k as
select "Eventyear x Race" as Type, race, eventyear,
count(*) as n "total number of the observations",
nmiss(&var) as nm_&var "number of the missing values in &var",
sum(&var) as n_&var "total number of positive values in &var",
sum(&var)/(count(*)-nmiss(&var)) as r_&var "Rate of &var"
from DMLocal.&tablenm
group by eventyear, race
order by eventyear, race;

create table sum4_&k as
select "Eventyear x Sex" as Type, sex, eventyear,
count(*) as n "total number of the observations",
nmiss(&var) as nm_&var "number of the missing values in &var",
sum(&var) as n_&var "total number of positive values in &var",
sum(&var)/(count(*)-nmiss(&var)) as r_&var "Rate of &var"
from DMLocal.&tablenm
group by eventyear, sex
order by eventyear, sex;

create table sum5_&k as
select "Eventyear x Hispanic" as Type, hispanic, eventyear,
count(*) as n "total number of the observations",
nmiss(&var) as nm_&var "number of the missing values in &var",
sum(&var) as n_&var "total number of positive values in &var",
sum(&var)/(count(*)-nmiss(&var)) as r_&var "Rate of &var"
from DMLocal.&tablenm
group by eventyear, hispanic
order by eventyear, hispanic;

create table sum6_&k as
select "Eventyear x Agegrp1" as Type, agegrp1, eventyear, 
count(*) as n "total number of the observations",
nmiss(&var) as nm_&var "number of the missing values in &var",
sum(&var) as n_&var "total number of positive values in &var",
sum(&var)/(count(*)-nmiss(&var)) as r_&var "Rate of &var"
from DMLocal.&tablenm
group by eventyear, AGEGRP1
order by eventyear, AGEGRP1;

create table sum7_&k as
select "Eventyear" as Type, eventyear,
count(*) as n "total number of the observations",
nmiss(&var) as nm_&var "number of the missing values in &var",
sum(&var) as n_&var "total number of positive values in &var",
sum(&var)/(count(*)-nmiss(&var)) as r_&var "Rate of &var"
from DMLocal.&tablenm
group by eventyear
order by eventyear;
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
/*SUMMARY TABLE - OPIOID EXPOSURE */
%tab(opioid_flat_file_oep, OPIOID_EXP_IND)
%summary(opioid_flat_file_oep,sum_opioid_exposure)
/*SUMMARY TABLE - CHRONIC OPIOID USE*/
%tab(opioid_flat_file_cou, CHRONIC_OPIOID_IND) 
%summary(opioid_flat_file_cou,sum_chronic_opioid)
/*SUMMARY TABLE - OUD current*/
%tab(opioid_flat_file_oud, oud_ind)   
%summary(opioid_flat_file_oud,sum_oud)
/*SUMMARY TABLE -OVERDOSE current*/
%tab(opioid_flat_file_odh, overdose_ind)
%summary(opioid_flat_file_odh,sum_overdose)
/*SUMMARY TABLE -OUD or SUD current*/
%tab(opioid_flat_file_osud, oud_sud_ind)
%summary(opioid_flat_file_osud,sum_osud)
/*SUMMARY TABLE -SUD current*/
%tab(opioid_flat_file_sud, substance_ind)
%summary(opioid_flat_file_sud,sum_sud)
/*SUMMARY TABLE -AUD current*/
%tab(opioid_flat_file_aud, alcohol_ind)
%summary(opioid_flat_file_aud,sum_aud)

