libname rcr "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\analytic specifications";

%macro SUMMARY_TABLE1(stratification);
%macro
 better_means(
 data = &syslast ,
 out = ,
 print = Y,
 sort = VARNUM,
 stts = _ALL_,
 varlst = _ALL_,
 clss = ,
 wghts = ,
 Vdef = , /* ADDED 11/29/07: Change default for VARDEF= option */
 testing= no , /* any other value will preserve the _better_: data sets */
/****************************************************************************************/
/* PROVIDE THE COMPLETE PROC MEANS STATISTIC LIST (FROM ONLINE-DOC) IF NONE STATED. */
/****************************************************************************************/
 _stts = N NMISS SUM MEAN mode STD VAR LCLM UCLM
 MIN P1 P5 P10 P25 P50 P75 P90 P95 P99 MAX QRANGE RANGE
 PROBT STDERR CV CSS SUMWGT KURT SKEW T USS ,
 default_fmt = best12. /* format for stats when no format on input data */
 ); %local
 BETTER_cntl /* holds name of cntlin DS for VARNUM informat */
 BETTER_cols /* holds name of contents DS for &data */
 BETTER_means_out /* holds name of results before sorting */
 bm2varnum /* holds varnum of first {var}_{stat} PROC MEANS */
 bm_cntl1 /* names cntlin for fmts of name label and format*/
 bm_conts1 /* holds name of contents DS for adapted &data */
 bm_conts2 /* holds name of contents DS for raw PROC MEANS */
 bm_data1 /* holds name of VIEW with VAR variables renamed */
 bm_stats_1 /* holds name of table OUTPUT from PROC MEANS */
 bmeansstart /* macro start time */
 bmeanstime /* finish time */
 drop_list /* COLLECT NAMES OF TEMPORARY TABLE TO BE DELETED*/
 drop_views /* COLLECT NAMES OF VIEWS TO BE DELETED */
 dum_varnum /* this dummy holder avoids warning from proc sql*/
 f_outs /* list of preformatted stat names */
 first_stat /* holds name first {var}_{stat} PROC MEANS */
 full /* INDICATOR IN OUTPUT LABEL WHEN ALL STATS USED.*/
 last_stat /* holds name last {var}_{stat} PROC MEANS */
 max_fmt_width /* maximun width for formatted values */
 n_numerics /* counter of analysis vars */
 n_stats /* counter of statistics output by PROC MEANS */
 name2num /* rename VAR variables to support /AUTONAME */
 nums_nm /* provides a list of the renamed vars for VAR */
 out_stats /* list statistic names output from PROC MEANS */
 _stat_ /* pointer into results statistic arrays */
 sttsE /* stats list with = after each statistic */
 ;
%let bmeansstart = %sysfunc(datetime()) ;
/****************************************************************************************/
/* PUT STATS AND VAR PARAMETER LIST INTO UPPER CASE. */
/****************************************************************************************/
 %let varlst = %upcase(&varlst);
 %let stts = %upcase(&stts);
/****************************************************************************************/
/* VERIFY INPUT DATA SET EXISTS. */
/****************************************************************************************/
 %let data = &data ; /* RESOLVE &syslast, WHEN DEFAULTED */
 /* provide default OUT= dataset */
 %if NOT %sysfunc( exist( &data )) %then %do ;
 %put MACRO.ER%str(ROR).&sysmacroName input data file &data does not exist ;
 %abort ;
 %end ;
/****************************************************************************************/
/* PREPARE OUTPUT DATA SET. */
/****************************************************************************************/
 %if %length(&out) < 1 %then %do;
 %let out = &data._means ;
 %end ;
 data &out ; stop ; run ;
 %if &syserr %then %do;
 %put &sysmacroName-ER%str(ROR): unable to write output data file &out ;
 %abort ;
 %end ;
 %if &sort eq VARNUM %then %do;
/****************************************************************************************/
/* GET THE NAMES/NUMBERS OF ALL VARIABLES INTO A LOOKUP FORMAT IF SORT ORDER = VARNUM. */
/****************************************************************************************/
/*Change character variables to binary variables with 0 as missing*/
proc contents data= &data out= contents noprint;
 run;
%let class=%upcase(&clss);
 data contents;
 set contents;
 if upcase(name)= "&class" then delete;
run;

proc sql noprint;
 select name 
into: Varlist separated by " "
 from  contents
 where type = 2  ;
 quit;
%LET varlist=&Varlist;
%LET k=1;
%LET var=%SCAN(&varlist,&k);
%Do %WHILE ("&var" NE "");
DATA &data;
SET &data;
IF &var NE "" THEN count=1;
ELSE count=0;
drop &var;
rename count=&var;
run;
proc print data=change;
run;
%LET k=%EVAL(&k+1);
%LET var=%SCAN(&varlist,&k);
%END;*/


proc contents data= &data out= _data_ noprint;
 run;
 %let BETTER_cols = &syslast ;
 %let drop_list = &drop_list %scan(&syslast,-1,.) ;
 data _data_ ;
 retain
 FMTNAME '_bm_VN'
 TYPE 'I'
 HLO 'U'
 ;
 set &BETTER_cols( keep= NAME VARNUM rename=( VARNUM=LABEL ));
 START = upcase( NAME) ;
 run;
 %let BETTER_cntl = &syslast ;
 %let drop_list = &drop_list %scan(&syslast,-1,.) ;
 proc format cntlin= &BETTER_cntl;
 run;
 %end;
/****************************************************************************************/
/* PROCESS STATISTICS CONDITIONS / COMBINATIONS */
 /****************************************************************************************/
 %if &stts = _ALL_ or %length(&stts) = 0 %then %do;
 %let stts = &_stts ;
 %let full = FULL STATS;
 %end;
 %if %length(&wghts) %then %do;
 %* remove KURT and Skew when weights are present;
 %let stts = %sysfunc( tranwrd( &stts, KURT, %str( ) ));
 %let stts = %sysfunc( tranwrd( &stts, SKEW, %str( ) ));
 %let full = STATS ;
 %end;
 %else %do;
 %* remove SUMWGT when no weights present ;
 %let stts = %sysfunc( tranwrd( &stts, SUMWGT, %str( ) ));
 %let full = STATS ;
 %end;
%**********************************************************************
* prepare stats list for OUTPUT statement (like SUM= MEAN= MAX= etc ) *
**********************************************************************;
%let sttsE = %sysfunc( tranwrd( %sysfunc(
 compbl( &stts )),%str( ), %str(= )
 ) )= ;
/****************************************************************************************/
/* TO RUN PROC MEANS ON ALL VARIABLES AND ALL STATS NEEDS /AUTONAME, SO NEED TO PREPARE */
/* WITH A GENERAL RENAME OF THE VAR VARIABLES. VARNUM PROVIDES UNIQUE IDENTITY FOR VARS */
/* LATER THEY WILL BE RENAMED BACK TO NORMAL */
/* NEED TO PREPARE RENAME= AND LOOK-UPS FROM VARNUM TO PROVIDE NAME, LABEL AND FORMAT */
/****************************************************************************************/
 *** first prepare model data set, in requested structure
 then VARNUM will be in any requested order ;
 data _data_ ;
 stop ;
 retain &clss &varlst ;
 keep &clss &varlst ;
 set &data ;
 run ;
 

 %let bm_conts0 = &syslast ;
 %let drop_list = &drop_list %scan(&syslast,-1,.) ;
 proc contents data= &bm_conts0( keep= &varlst drop= &clss ) noprint out= _data_ ;
 * just the VAR variables not in CLASS vars ;
 run ;
 %let bm_conts1 = &syslast ;
 %let drop_list = &drop_list %scan(&syslast,-1,.) ;
 
 proc sql noprint ;
 * prepare renames and name lists ;
 select cats( name, '= v', varnum )
 , cats( 'v', varnum )
 , varnum
 into : name2num separated by ' '
 , : nums_nm separated by ' '
 , : dum_varnum
 from &bm_conts1
 where type = 1 /* numeric vars only */
 order by varnum
 ;

 %let n_numerics = &sqlobs ;
***********************************************************************
* later will be formatting stats together, so need max default width *
**********************************************************************;
 select max( max( a.defw, b.formatl ))
 into : max_fmt_width separated by ' '
 from dictionary.formats a
 join &bm_conts1 b
 on a.fmtname = b.format
 ;
 *** not forgetting to get length of default formatting width ;
 %let def_fmt_width = %sysfunc( compress( &default_fmt, 0123456789, k ) ) ;
 *** and just in case default is the only format/width ;
 %let max_fmt_width = %sysfunc( max( &max_fmt_width, &def_fmt_width )) ;
 quit ;
***********************************************************************
* pointless to proceed if there are no numeric vars to analyse *
**********************************************************************;
%if &n_numerics < 1 %then %do ;
 %put &sysmacroname-ER%STR(ROR): NO numeric variables selected for analysis from &data ;
  %abort ;
%end ;
***********************************************************************
* always build look-up formats from Varnum-based var names, back to original
* and to variable label, and to variable format
**********************************************************************;
data _data_ ;
 set &bm_conts1(drop=type) end=eof ;
 retain fmtn1 'num2nam' fmtn2 'num2lab' fmtn3 'num2fmt'
 type 'c' start '12345678' hlo ' ' ;
 start = cats( 'v', varnum ) ;
 *** when format length is not specified, avoid using the zero from proc contents ! ;
 if formatl then fmtl = cats( format, formatl, '.', formatd ) ;
 else fmtl = format ;
 output ;
 if eof then do ;
 fmtl = "&default_fmt" ;
 label= ' ' ;
 hlo = 'o' ;
 output ;
 end ;
 run ;
 %let bm_cntl1 = &syslast ;
 %let drop_list = &drop_list %scan(&syslast,-1,.) ;
 proc format cntlin= &bm_cntl1( rename=( fmtn1=fmtname name= label) drop= label );
 proc format cntlin= &bm_cntl1( rename=( fmtn2=fmtname )
 where=( label ne ' ' or hlo ne ' ') ) ;
 proc format cntlin= &bm_cntl1( rename=( fmtn3=fmtname fmtl= label) drop= label
 where=( label ne '0.0' and label ne ' ' or hlo='o') )
 %if &testing NE no %then %do ;
 fmtlib
 %end ;
 ;
 run ;
***********************************************************************
* feature _DATA_ doesnt work with data step views
 so just using it to make a name available
**********************************************************************;
 data _data_; stop; run ;
 %let bm_data1 = &syslast ;
 %let drop_list = &drop_list %scan(&syslast,-1,.) ;
 %let bm_data1 = &bm_data1.v ;
 %let drop_views = &drop_views %scan(&bm_data1,-1,.) ;
***********************************************************************
* now build a view with VAR variables renamed v{varnum}
**********************************************************************;
data &bm_data1 /view= &bm_data1 ;
 set &data ;
 rename &name2num ;
 run ;
***********************************************************************
* now collect all stats for all vars using /autoname for control *
**********************************************************************;
proc means data=&bm_data1 noprint missing &vdef;
 var &nums_nm ;
 %if %length(&clss) %then %do;
 class &clss;
 %end;
 %if %length(&wghts) %then %do;
 weight &wghts;
 %end;
 output &sttsE out= _data_ /AUTONAME ;
run;
 %let bm_stats_1 = &syslast ;
 %let drop_list = &drop_list %scan(&syslast,-1,.) ;
***********************************************************************
* now split up each row into stats for variables *
**********************************************************************;
* first, to identify first and last of the var_stat variables output ;
* collect variable names ;
proc contents data= &bm_stats_1( drop= &clss _type_ _freq_ ) noprint
 out=_data_ ;
run ;
 %let bm_conts2 = &syslast ;
  %let drop_list = &drop_list %scan(&syslast,-1,.) ;
***********************************************************************
* and select min and max VARNUM vars *
 these provide the range of variable names in the results
**********************************************************************;
proc sql noprint ;
 select name into :first_stat separated by ' '
 from &bm_conts2
 having varnum = min(varnum )
 ;
 select name into :last_stat separated by ' '
 from &bm_conts2
 having varnum = max(varnum )
 ;
 * now get list of the statistics created by PROC MEANS ;
 select scan( name,-1,'_') , varnum
 into :out_stats separated by ' ' , :dum_varnum
 from &bm_conts2
 where scan(name,1,'_') eq "%scan(&last_stat,1,_)"
 order by varnum
 ; ****** using &last, but any one stat would do! ;
 %put NOTE: &sqlobs statistics found ;
quit ;
%let n_stats = &sqlobs ;
%let f_outs /* formmatted output stats */
 = f_%sysfunc( tranwrd( &out_stats, %str( ), %str( f_))) ;
data _data_ ;
 retain _type_ &clss name label ;
 length vname name $32 label $256 ; drop vname ;
 format _type_ 3. ;
 %if %sysfunc( indexw( &out_stats, N )) %then %do ;
 format n comma9. nmiss best7. pct_pop percent7.1 ;
 %end ;
 if 0 then set &bm_stats_1 ;
 array mean_set(&n_stats, &n_numerics ) &first_stat--&last_stat ;
 set &bm_stats_1 ;
 %if &testing ne no %then %do ;
 put mean_set(1,1)= mean_set(2,2)= mean_set(2,1)= ;
 %end ;
 array stats( &n_stats ) &out_stats ;
 array fstat( &n_stats ) $&max_fmt_width /*&bm_max_f_len*/ &f_outs ;
 do _n_ = 1 to &n_numerics ;
 vname = vname( mean_set( 1, _n_ )) ;
 * vname name layout is "v{varnum}_{statisticName}" ;
 vnamev= scan( vname, 1, '_' ) ;
 label = put( vnamev, $num2lab. ) ;
 name = put( vnamev, $num2nam. ) ;
 format= put( vnamev, $num2fmt. ) ;
 varnum= input( substr( vnamev, 2 ), best8. );
 do _stat_ = 1 to &n_stats ;
 stats( _stat_ ) = mean_set( _stat_, _n_ ) ;
 fstat( _stat_ ) = putn( stats( _stat_ ), format ) ;
 end ;
 %if %sysfunc( indexw( &out_stats, N )) %then %do ;
 pct_pop = n / _freq_ ;
 %end ;
 _error_ = 0 ;
 output ;
 end ;
 drop &first_stat--&last_stat _stat_ ;
 keep _type_ &clss name label &out_stats pct_pop varnum format f_: ;
run ;
 %let better_means_out = &syslast ;
 %let drop_list = &drop_list %scan(&syslast,-1,.) ;
 %macro now( fmt= datetime21.2 ) / des= "Timestamp";
 %sysfunc( datetime(), &fmt )
 %mend now;
/****************************************************************************************/
/* CREATE FINAL DATASET WITH ALL STATISTICS, SORTED AS REQUESTED ON INVOCATION. */
 /****************************************************************************************/
 %if &sort = MEANS %then %do ; *sort=MEANS indicates no sort requested ;
 data &out( label= "&FULL FOR &data %sysfunc(datetime(), datetime21.3)"
 drop= vnameV
 %if %length(&clss) = 0 %then %do;
 _TYPE_
 %end; ) ;
 set &better_means_out ;
 run ;
 %end ;
 %else %do ;
 proc sort data= &better_means_out
 SORTSEQ=LINGUISTIC /* in SAS9.2 + this provides mixed-case sorting for NAME */
 out= &out( label= "&FULL FOR &data %NOW"
 drop=
 %if %length(&clss) = 0 %then %do;
 _TYPE_
 %end;
 ) ;
 by _TYPE_ &clss &sort ;
 run;
 %end ;
/****************************************************************************************/
/* IF PRINTED OUTPUT IS REQUESTED, DO SO HERE. */
/****************************************************************************************/
 %if &print = Y %then %do;
 proc print data= &out ;
 title3 "MEANS FOR &data";
 footnote2 .h=1 .j=l "&sysmacroname by &sysuserid at %now(fmt=twmdy) " ;
 %if %length(&clss) > 0 %then %do;
 by _TYPE_;
 %end;
 run;
 title3 ;
 footnote2 ;
 %end;
 %if &testing = no %then %do;
/****************************************************************************************/
/* CLEAN UP REMAINING TEMPORARY DATASETS. */
/****************************************************************************************/
 proc datasets lib= work nolist;
 delete &drop_list ;
 delete &drop_views / mt=view ;
 run; quit;
 %end;
 %else %do ;
 proc sql number flow= 20 70 ;
 title3 'current macro vars ' ;
 proc sql number ;
 select name, scope, offset, value
 from sashelp.vmacro
 order by scope descending, name, offset ;
 quit ;
 title3 ;
 quit ;
 %end ;
 %let bmeanstime = %sysevalf ( %sysfunc(datetime()) - &bmeansstart ) ;
 %put Total BetterMeans Macro Time: %sysfunc(putn(&bmeanstime,time9.)) ;
%mend BETTER_MEANS ;
%BETTER_MEANS(data=rcr.opioid_flat_file,out=sumtableall_&stratification.,print=N,stts=n nmiss,clss=&stratification);
DATA rcr.sumtableall_&stratification.;
set sumtableall_&stratification.;
keep &stratification name n nmiss;
run;
%mend SUMMARY_TABLE1;
%SUMMARY_TABLE1(facility_location);
%SUMMARY_TABLE1(race);
%SUMMARY_TABLE1(sex);
%SUMMARY_TABLE1(hispanic);
%SUMMARY_TABLE1(AgeAsOfJuly1);
%SUMMARY_TABLE1(AGEGRP);
%SUMMARY_TABLE1(EventYear);

/*STD history sub-population*/
PROC SQL inobs=max;
  CREATE TABLE rcr.opioid_flat_file_std AS
  SELECT *
  FROM rcr.opioid_flat_file(where=(ADMIT_DATE IS NOT NULL))
  WHERE HIV_Dx_Any_Prior =1 OR HepB_Dx_Any_Prior=1 OR HepC_Dx_Any_Prior =1
  ;
QUIT;
%macro SUMMARY_TABLE2(stratification);
%BETTER_MEANS(data=rcr.opioid_flat_file_std,out=sumtablestd_&stratification.,print=N,stts=n nmiss,clss=&stratification);
DATA rcr.sumtablestd_&stratification.;
set sumtablestd_&stratification.;
keep &stratification name n nmiss;
run;
%mend SUMMARY_TABLE2;
%SUMMARY_TABLE2(facility_location);
%SUMMARY_TABLE2(facility_location);
%SUMMARY_TABLE2(race);
%SUMMARY_TABLE2(sex);
%SUMMARY_TABLE2(hispanic);
%SUMMARY_TABLE2(AgeAsOfJuly1);
%SUMMARY_TABLE2(AGEGRP);
%SUMMARY_TABLE2(EventYear);

/*Chronic Opioid Use history sub-population*/
PROC SQL inobs=max;
  CREATE TABLE rcr.opioid_flat_file_cou AS
  SELECT *
  FROM rcr.opioid_flat_file(where=(ADMIT_DATE IS NOT NULL))
  WHERE CHRONIC_OPIOID = 1
  ;
QUIT;
%macro SUMMARY_TABLE3(stratification);
%BETTER_MEANS(data=rcr.opioid_flat_file_cou,out=sumtablecou_&stratification.,print=N,stts=n nmiss,clss=&stratification);
DATA rcr.sumtablecou_&stratification.;
set sumtablecou_&stratification.;
keep &stratification name n nmiss;
run;
%mend SUMMARY_TABLE3;
%SUMMARY_TABLE3(facility_location);
%SUMMARY_TABLE3(facility_location);
%SUMMARY_TABLE3(race);
%SUMMARY_TABLE3(sex);
%SUMMARY_TABLE3(hispanic);
%SUMMARY_TABLE3(AgeAsOfJuly1);
%SUMMARY_TABLE3(AGEGRP);
%SUMMARY_TABLE3(EventYear);


/*Chronic Opioid Use history sub-population*/
PROC SQL inobs=max;
  CREATE TABLE rcr.opioid_flat_file_cou AS
  SELECT *
  FROM rcr.opioid_flat_file(where=(ADMIT_DATE IS NOT NULL))
  WHERE CHRONIC_OPIOID = 1
  ;
QUIT;
%macro SUMMARY_TABLE4(stratification);
%BETTER_MEANS(data=rcr.opioid_flat_file_cou,out=sumtablecou_&stratification.,print=N,stts=n nmiss,clss=&stratification);
DATA rcr.sumtablecou_&stratification.;
set sumtablecou_&stratification.;
keep &stratification name n nmiss;
run;
%mend SUMMARY_TABLE4;
%SUMMARY_TABLE4(facility_location);
%SUMMARY_TABLE4(race);
%SUMMARY_TABLE4(sex);
%SUMMARY_TABLE4(hispanic);
%SUMMARY_TABLE4(AgeAsOfJuly1);
%SUMMARY_TABLE4(AGEGRP);
%SUMMARY_TABLE4(EventYear);

/*SUD Use history sub-population*/
PROC SQL inobs=max;
  CREATE TABLE rcr.opioid_flat_file_sud AS
  SELECT *
  FROM rcr.opioid_flat_file(where=(ADMIT_DATE IS NOT NULL))
  WHERE SedHypAnx_Use_DO_Any_Prior = 1 AND OUD ne 1 AND Alcohol_Use_DO_Any_Prior ne 1
  ;
QUIT;
%macro SUMMARY_TABLE5(stratification);
%BETTER_MEANS(data=rcr.opioid_flat_file_sud,out=sumtablesud_&stratification.,print=N,stts=n nmiss,clss=&stratification);
DATA rcr.sumtablesud_&stratification.;
set sumtablesud_&stratification.;
keep &stratification name n nmiss;
run;
%mend SUMMARY_TABLE5;
%SUMMARY_TABLE5(facility_location);
%SUMMARY_TABLE5(race);
%SUMMARY_TABLE5(sex);
%SUMMARY_TABLE5(hispanic);
%SUMMARY_TABLE5(AgeAsOfJuly1);
%SUMMARY_TABLE5(AGEGRP);
%SUMMARY_TABLE5(EventYear);

/*SUD and OUD Use history sub-population*/
PROC SQL inobs=max;
  CREATE TABLE rcr.opioid_flat_file_soud AS
  SELECT *
  FROM rcr.opioid_flat_file(where=(ADMIT_DATE IS NOT NULL))
  WHERE SedHypAnx_Use_DO_Any_Prior = 1 AND OUD = 1 AND Alcohol_Use_DO_Any_Prior ne 1
  ;
QUIT;
%macro SUMMARY_TABLE6(stratification);
%BETTER_MEANS(data=rcr.opioid_flat_file_soud,out=sumtablesoud_&stratification.,print=N,stts=n nmiss,clss=&stratification);
DATA rcr.sumtablesoud_&stratification.;
set sumtablesoud_&stratification.;
keep &stratification name n nmiss;
run;
%mend SUMMARY_TABLE6;
%SUMMARY_TABLE6(facility_location);
%SUMMARY_TABLE6(race);
%SUMMARY_TABLE6(sex);
%SUMMARY_TABLE6(hispanic);
%SUMMARY_TABLE6(AgeAsOfJuly1);
%SUMMARY_TABLE6(AGEGRP);
%SUMMARY_TABLE6(EventYear);

/*OUD Use history sub-population*/
PROC SQL inobs=max;
  CREATE TABLE rcr.opioid_flat_file_oud AS
  SELECT *
  FROM rcr.opioid_flat_file(where=(ADMIT_DATE IS NOT NULL))
  WHERE OUD = 1
  ;
QUIT;
%macro SUMMARY_TABLE7(stratification);
%BETTER_MEANS(data=rcr.opioid_flat_file_oud,out=sumtableoud_&stratification.,print=N,stts=n nmiss,clss=&stratification);
DATA rcr.sumtableoud_&stratification.;
set sumtableoud_&stratification.;
keep &stratification name n nmiss;
run;
%mend SUMMARY_TABLE7;
%SUMMARY_TABLE7(facility_location);
%SUMMARY_TABLE7(race);
%SUMMARY_TABLE7(sex);
%SUMMARY_TABLE7(hispanic);
%SUMMARY_TABLE7(AgeAsOfJuly1);
%SUMMARY_TABLE7(AGEGRP);
%SUMMARY_TABLE7(EventYear);

/*OUD Use history sub-population*/
PROC SQL inobs=max;
  CREATE TABLE rcr.opioid_flat_file_oud AS
  SELECT *
  FROM rcr.opioid_flat_file(where=(ADMIT_DATE IS NOT NULL))
  WHERE OUD = 1
  ;
QUIT;
%macro SUMMARY_TABLE7(stratification);
%BETTER_MEANS(data=rcr.opioid_flat_file_oud,out=sumtableoud_&stratification.,print=N,stts=n nmiss,clss=&stratification);
DATA rcr.sumtableoud_&stratification.;
set sumtableoud_&stratification.;
keep &stratification name n nmiss;
run;
%mend SUMMARY_TABLE7;
%SUMMARY_TABLE7(facility_location);
%SUMMARY_TABLE7(race);
%SUMMARY_TABLE7(sex);
%SUMMARY_TABLE7(hispanic);
%SUMMARY_TABLE7(AgeAsOfJuly1);
%SUMMARY_TABLE7(AGEGRP);
%SUMMARY_TABLE7(EventYear);

/*Opioid Exposure sub-population*/
PROC SQL inobs=max;
  CREATE TABLE rcr.opioid_flat_file_oep AS
  SELECT *
  FROM rcr.opioid_flat_file(where=(ADMIT_DATE IS NOT NULL))
  WHERE OPIOID_FLAG = 1
  ;
QUIT;
%macro SUMMARY_TABLE9(stratification);
%BETTER_MEANS(data=rcr.opioid_flat_file_oep,out=sumtableoep_&stratification.,print=N,stts=n nmiss,clss=&stratification);
DATA rcr.sumtableoep_&stratification.;
set sumtableoep_&stratification.;
keep &stratification name n nmiss;
run;
%mend SUMMARY_TABLE8;
%SUMMARY_TABLE8(facility_location);
%SUMMARY_TABLE8(race);
%SUMMARY_TABLE8(sex);
%SUMMARY_TABLE8(hispanic);
%SUMMARY_TABLE8(AgeAsOfJuly1);
%SUMMARY_TABLE8(AGEGRP);
%SUMMARY_TABLE8(EventYear);





