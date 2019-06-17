/*This program is used for pre-processing summary tables and fixing errors of mis-matching.*/

options obs=max macrogen symbolgen mprint noxsync noxwait 
        source2 nofmterr ls=256 ps=68 ;

libname usc "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C3 - University of Southern California- Partner Clinics DataMart NEW\RCROPI_ahr_wp001_nsd1_v03_2019\RCROPI_ahr_wp001_nsd1_v03_2019";
libname ucd "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C3- University of California Davis DataMart NEW\drnoc";
libname ucla "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C3- University of California Los Angeles DataMart NEW\RCROPI_ahr_wp001_nsd1_v03_2019";
libname cs "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C3 - Cedars Sinai Medical Center DataMart NEW\RCROPI_ahr_wp001_nsd1_v03_2019";
libname sm "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C3 - San Mateo DataMart NEW\drnoc\drnoc";
libname uci "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C3 - University of California Irvine DataMart NEW\C3UCI_RCROPI_ahr_wp001_nsd1_v03_2019";
libname ucsd "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C3 - University of California San Diego DataMart NEW\drnoc\drnoc";
libname vav "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C3 - VA Informatics and Computing Infrastructure DataMart NEW\RCROPI_ahr_wp001_nsd1_v03_2019\drnoc";
libname uu "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C4 - University of Utah DataMart NEW\RCROPI_ahr_wp001_nsd1_v03_2019\drnoc";
libname bay "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C6 - Baylor Scott White North DataMart NEW\RCROPI_ahr_wp001_nsd1_v03_2019\drnoc";
libname lsu "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C6 - LSU DataMart\RCROPI_ahr_wp001_nsd1_v03_2019\drnoc";
libname nyc "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C8 - New York Genome Center DataMart NEW\nyc_cdrn_RCROPI_ahr_wp001_nsd1_v03_2019\drnoc";
libname advance "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C10 - ADVANCE DataMart NEW\rcropi_ahr_wp001_nsd1_v03_2019\drnoc";
libname jhu "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C11 - Johns Hopkins DataMart NEW\C11JHU_RCROPI_ahr_wp001_nsd1_v03_2019\drnoc";
libname psh "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C11 - Penn State Hershey Medical Center DataMart NEW\RCROPI_ahr_wp001_nsd1_v03_2019";
libname tu "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C11 - Temple University DataMart NEW\RCROPI_ahr_wp001_nsd1_v03_2019\drnoc";
libname upmc "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C11 - University of Pittsburgh Medical Center DataMart NEW\RCROPI_ahr_wp001_nsd1_v03_2019";
libname upmc2 "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\C11 - UPMC Claims DataMart NEW\RCROPI_ahr_wp001_nsd1_v03_2019";
libname final "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\Clean_Summary_Tables";
%macro drp(ds);
data data1;
 set &ds;
run;

%let opends = %sysfunc(open(data1));
%let varCnt = %sysfunc(attrn(&opends, nvars));
%let closds = %sysfunc(close(&opends));

proc sql noprint;
create table meta1 as
select varnum    as varorder
      ,name      as varname
	  ,type      as vartype
	  ,length    as varlength
	  ,label     as varlabel
  from dictionary.columns
 where libname = 'WORK'
   and memname = 'DATA1'
 order by varorder;

select varname, varlabel
  into :var1 - :var&varCnt,
       :lab1 - :lab&varCnt
  from meta1;
quit;

data data2;
 set data1;
%do i = 1 %to &varCnt;
   %let chk1 = %index(%upcase(&&lab&i), _DATE); 
   %let chk2 = %index(%upcase(&&lab&i), CT_NALOXONE);
   %let chk3 = %index(%upcase(&&lab&i), DAYSTODEATH);
   %if (&chk1 > 0 or &chk2 > 0 or &chk3>0)
   	  %then %do; 
            drop &&var&i;
			%end;
%end;
run;

proc sql noprint;
drop table data1, meta1;
quit;

/*
%do i = 1 %to &varCnt;
%symdel &var&i;
%symdel &lab&i;
%end;
%symdel varCnt;
*/
proc sql noprint;
create table meta2 as
select varnum    as varorder
      ,name      as varname
	  ,type      as vartype
	  ,length    as varlength
	  ,label     as varlabel
  from dictionary.columns
 where libname = 'WORK'
   and memname = 'DATA2'
 order by varorder;

%let opends = %sysfunc(open(data2));
%let varCnt = %sysfunc(attrn(&opends, nvars));
%let closds = %sysfunc(close(&opends));

proc sql noprint;
select varname
  into :var1 - :var&varCnt
  from meta2
  order by varorder;
quit;

data data3;
 set data2;
%do n = 2 %to &varCnt;
    %let i = %eval(&n - 1);
    rename &&var&n = nn_&i;
%end;
run;

proc sql noprint;
drop table data2, meta2;
quit;

data &ds.0;
 set data3;
%do n = 1 %to &varCnt-1;
    %if %upcase("&ds") = "DATA_N"
		%then %do;
              rename nn_&n = n_&n;
			  %end;
		%else %do;
			  rename nn_&n = nm_&n;
			  %end;
%end;
run;

proc sql noprint;
create table meta_&ds as
select varnum    as varorder
      ,name      as varname
	  ,type      as vartype
	  ,length    as varlength
	  ,label     as varlabel
  from dictionary.columns
 where libname = 'WORK'
   and memname = upcase("&ds.0")
order by varorder;

drop table data3;
quit;

proc sort data = &ds.0;
     by keyx;
run;
%mend drp;

%macro clean(input,output,site);
data org;
retain keyx;
set &input;
length keyx	 $ 400;
label keyx = 'Keys';
keyx = strip(Facility_Location)|| '-' ||
       strip(RACE)|| '-' ||
	   strip(SEX)|| '-' ||
	   strip(HISPANIC)|| '-' ||
	   strip(AGEGRP1) || '-' ||
	   strip(put(EventYear, z4.));
run;

proc sql noprint;
create table mt as
select varnum    as varorder
      ,name      as varname
	  ,type      as vartype
	  ,length    as varlength
	  ,label     as varlabel
  from dictionary.columns
 where libname = 'WORK'
   and memname = 'ORG';
quit;

data keys(keep = keyx Facility_Location Race Sex Hispanic Agegrp1 EventYear n)
     data_n(keep = keyx n_1 - n_110)
     data_nm(keep = keyx nm_1 - nm_110);
set org;
run;


%drp(data_n);
%drp(data_nm);

proc sort data = keys;
     by keyx;
run;

data final(drop=keyx);
merge keys(in=a)
      data_n0(in=b)
	  data_nm0(in=c);
   by keyx;
   if a;
run;
proc sql noprint;
create table final.&output as
select "&site" as site,*
from final;
quit;
proc sql noprint;
create table check_&output as
select varnum    as varorder  
      ,name      as varname_&site label="variable_name_&site"
	  ,label     as varlabel_&site label="label_name_&site"
  from dictionary.columns
 where libname = 'FINAL'
   and memname = upcase("&output")
order by varorder;
quit;
%mend clean;

/*SUMMARY_ALL*/
%macro report(sumtable);
%clean(usc.&sumtable,usc_&sumtable,C3USC);
%clean(ucd.&sumtable,ucd_&sumtable,C3UCD);
%clean(ucla.&sumtable,ucla_&sumtable,C3UCLA);
%clean(cs.&sumtable,cs_&sumtable,C3CS);
%clean(sm.&sumtable,sm_&sumtable,C3SM);
%clean(uci.&sumtable,uci_&sumtable,C3UCI);
%clean(ucsd.&sumtable,ucsd_&sumtable,C3UCSD);
%clean(vav.&sumtable,vav_&sumtable,C3VAV);
%clean(uu.&sumtable,uu_&sumtable,C4UU);
%clean(bay.&sumtable,bay_&sumtable,C6BAY);
%clean(lsu.&sumtable,lsu_&sumtable,C6LSU);
%clean(nyc.&sumtable,nyc_&sumtable,C8NYC);
%clean(advance.&sumtable,adv_&sumtable,C10ADVANCE);
%clean(jhu.&sumtable,jhu_&sumtable,C11JHU);
%clean(psh.&sumtable,psh_&sumtable,C11PSH);
%clean(tu.&sumtable,tu_&sumtable,C11TU);
%clean(upmc.&sumtable,upmc_&sumtable,C11UPMC);
%clean(upmc2.&sumtable,upmc2_&sumtable,C11UPMC2); 

data final.check_&sumtable;
merge check_usc_&sumtable check_ucd_&sumtable check_ucla_&sumtable check_cs_&sumtable check_sm_&sumtable check_uci_&sumtable check_ucsd_&sumtable check_vav_&sumtable
check_uu_&sumtable check_bay_&sumtable check_lsu_&sumtable check_nyc_&sumtable check_adv_&sumtable check_jhu_&sumtable check_psh_&sumtable check_tu_&sumtable
check_upmc_&sumtable check_upmc2_&sumtable;
by varorder;
run;

data final.&sumtable;
set final.adv_&sumtable final.usc_&sumtable final.ucd_&sumtable final.ucla_&sumtable final.cs_&sumtable final.sm_&sumtable final.uci_&sumtable final.ucsd_&sumtable 
final.vav_&sumtable final.uu_&sumtable final.bay_&sumtable final.lsu_&sumtable final.nyc_&sumtable  final.jhu_&sumtable final.psh_&sumtable final.tu_&sumtable 
final.upmc_&sumtable final.upmc2_&sumtable;
run;
%mend report;
%report(sum_all);
%report(sum_all_exc_cancer);
%report(sum_binary);
%report(sum_chronic_opioid);
%report(sum_aud);	 
%report(sum_opioid_exposure);
%report(sum_osud);
%report(sum_oud);
%report(sum_overdose);
%report(sum_std);
%report(sum_sud);

%macro provider(input,output,site);
proc sql noprint;
create table final.&output as
select "&site" as site,*
from &input;
quit;

proc sql noprint;
create table check_&output as
select varnum    as varorder  
      ,name      as varname_&site label="variable_name_&site"
	  ,label     as varlabel_&site label="label_name_&site"
  from dictionary.columns
 where libname = 'FINAL'
   and memname = upcase("&output")
order by varorder;
quit;
%mend provider;
%provider(usc.sum_provider,usc_sum_provider,C3USC);
%provider(ucd.sum_provider,ucd_sum_provider,C3UCD);
%provider(ucla.sum_provider,ucla_sum_provider,C3UCLA);
%provider(cs.sum_provider,cs_sum_provider,C3CS);
%provider(sm.sum_provider,sm_sum_provider,C3SM);
%provider(uci.sum_provider,uci_sum_provider,C3UCI);
%provider(ucsd.sum_provider,ucsd_sum_provider,C3UCSD);
%provider(vav.sum_provider,vav_sum_provider,C3VAV);
%provider(uu.sum_provider,uu_sum_provider,C4UU);
%provider(bay.sum_provider,bay_sum_provider,C6BAY);
%provider(lsu.sum_provider,lsu_sum_provider,C6LSU);
%provider(nyc.sum_provider,nyc_sum_provider,C8NYC);
%provider(advance.sum_provider,adv_sum_provider,C10ADVANCE);
%provider(jhu.sum_provider,jhu_sum_provider,C11JHU);
%provider(psh.sum_provider,psh_sum_provider,C11PSH);
%provider(tu.sum_provider,tu_sum_provider,C11TU);
%provider(upmc.sum_provider,upmc_sum_provider,C11UPMC);
%provider(upmc2.sum_provider,upmc2_sum_provider,C11UPMC2); 

data final.check_sum_provider;
merge check_usc_sum_provider check_ucd_sum_provider check_ucla_sum_provider check_cs_sum_provider check_sm_sum_provider check_uci_sum_provider check_ucsd_sum_provider 
check_vav_sum_provider check_uu_sum_provider check_bay_sum_provider check_lsu_sum_provider check_nyc_sum_provider check_adv_sum_provider check_jhu_sum_provider 
check_psh_sum_provider check_tu_sum_provider check_upmc_sum_provider check_upmc2_sum_provider;
by varorder;
run;

data final.sum_provider;
set final.adv_sum_provider final.usc_sum_provider /*final.ucd_sum_provider*/ final.ucla_sum_provider final.cs_sum_provider final.sm_sum_provider final.uci_sum_provider 
final.ucsd_sum_provider final.vav_sum_provider final.uu_sum_provider final.bay_sum_provider final.lsu_sum_provider final.nyc_sum_provider  final.jhu_sum_provider 
final.psh_sum_provider final.tu_sum_provider final.upmc_sum_provider final.upmc2_sum_provider;
run;





/*SUM_BINARY*/
%macro clean(input,output,site);
data org;
retain keyx;
set &input;
length keyx	 $ 400;
label keyx = 'Keys';
keyx = strip(Facility_Location)|| '-' ||
       strip(BINARY_RACE)|| '-' ||
	   strip(BINARY_SEX)|| '-' ||
	   strip(BINARY_HISPANIC)|| '-' ||
	   strip(put(EventYear, z4.));
run;

proc sql noprint;
create table mt as
select varnum    as varorder
      ,name      as varname
	  ,type      as vartype
	  ,length    as varlength
	  ,label     as varlabel
  from dictionary.columns
 where libname = 'WORK'
   and memname = 'ORG';
quit;

data keys(keep = keyx Facility_Location Binary_Race Binary_Sex Binary_Hispanic EventYear mean_age n)
     data_n(keep = keyx n_1 - n_110)
     data_nm(keep = keyx nm_1 - nm_110);
set org;
run;


%drp(data_n);
%drp(data_nm);

proc sort data = keys;
     by keyx;
run;

data final(drop=keyx);
merge keys(in=a)
      data_n0(in=b)
	  data_nm0(in=c);
   by keyx;
   if a;
run;
proc sql noprint;
create table final.&output as
select "&site" as site,*
from final;
quit;
proc sql noprint;
create table check_&output as
select varnum    as varorder  
      ,name      as varname_&site label="variable_name_&site"
	  ,label     as varlabel_&site label="label_name_&site"
  from dictionary.columns
 where libname = 'FINAL'
   and memname = upcase("&output")
order by varorder;
quit;
%mend clean;
%macro report(sumtable);
%clean(usc.&sumtable,usc_&sumtable,C3USC);
%clean(ucd.&sumtable,ucd_&sumtable,C3UCD);
%clean(ucla.&sumtable,ucla_&sumtable,C3UCLA);
%clean(cs.&sumtable,cs_&sumtable,C3CS);
%clean(sm.&sumtable,sm_&sumtable,C3SM);
%clean(uci.&sumtable,uci_&sumtable,C3UCI);
%clean(ucsd.&sumtable,ucsd_&sumtable,C3UCSD);
%clean(vav.&sumtable,vav_&sumtable,C3VAV);
%clean(uu.&sumtable,uu_&sumtable,C4UU);
%clean(bay.&sumtable,bay_&sumtable,C6BAY);
%clean(lsu.&sumtable,lsu_&sumtable,C6LSU);
%clean(nyc.&sumtable,nyc_&sumtable,C8NYC);
%clean(advance.&sumtable,adv_&sumtable,C10ADVANCE);
%clean(jhu.&sumtable,jhu_&sumtable,C11JHU);
%clean(psh.&sumtable,psh_&sumtable,C11PSH);
%clean(tu.&sumtable,tu_&sumtable,C11TU);
%clean(upmc.&sumtable,upmc_&sumtable,C11UPMC);
%clean(upmc2.&sumtable,upmc2_&sumtable,C11UPMC2); 

data final.check_&sumtable;
merge check_usc_&sumtable check_ucd_&sumtable check_ucla_&sumtable check_cs_&sumtable check_sm_&sumtable check_uci_&sumtable check_ucsd_&sumtable check_vav_&sumtable
check_uu_&sumtable check_bay_&sumtable check_lsu_&sumtable check_nyc_&sumtable check_adv_&sumtable check_jhu_&sumtable check_psh_&sumtable check_tu_&sumtable
check_upmc_&sumtable check_upmc2_&sumtable;
by varorder;
run;

data final.&sumtable;
set final.adv_&sumtable final.usc_&sumtable final.ucd_&sumtable final.ucla_&sumtable final.cs_&sumtable final.sm_&sumtable final.uci_&sumtable final.ucsd_&sumtable 
final.vav_&sumtable final.uu_&sumtable final.bay_&sumtable final.lsu_&sumtable final.nyc_&sumtable  final.jhu_&sumtable final.psh_&sumtable final.tu_&sumtable 
final.upmc_&sumtable final.upmc2_&sumtable;
run;
%mend report;
%report(sum_binary);
