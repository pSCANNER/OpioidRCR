proc printto log="&DRNOC.Opioid_RCR.log"; run;

/*{top 1000 dx codes in sub-population defined in summary tables}*/
** Amy added DX_TYPE 9/15/19 **;
%macro dxprofiling(flatfile,proftable);
proc sql noprint outobs=1000;
  create table DRNOC.&proftable as
  select distinct dx, DX_TYPE, count(dx) as freq
  from dmlocal.&flatfile as O, indata.diagnosis as D
  where O.patid=D.patid
  group by dx
  order by freq desc;
quit;
data DRNOC.&proftable;
  set DRNOC.&proftable;
  if 0 < freq < &threshold then freq = .t;
run;
%mend;

/*Profiling TABLE - ALL*/
%dxprofiling(opioid_flat_file,profiling_dx_all);

/*Profiling TABLE - STD HISTORY*/
/*%dxprofiling(opioid_flat_file_std,profiling_dx_std); ** STD not defined **/

/*Profiling TABLE - CHRONIC OPIOID USE HISTORY*/
%dxprofiling(opioid_flat_file_cou,profiling_dx_cou);

/*Profiling TABLE -OVERDOSE HISTORY*/
%dxprofiling(opioid_flat_file_odh,profiling_dx_odh);

/*Profiling TABLE -SUD HISTORY*/
%dxprofiling(opioid_flat_file_sud,profiling_dx_sud);

/*Profiling TABLE -OUD+SUD, NOT AUD*/
%dxprofiling(opioid_flat_file_osud,profiling_dx_osud);

/*Profiling TABLE - OUD */
%dxprofiling(opioid_flat_file_oud,profiling_dx_oud);

/*profiling TABLE - AUD */
%dxprofiling(opioid_flat_file_aud,profiling_dx_aud);

/*Profiling TABLE - OPIOID EXPOSURE */
%dxprofiling(opioid_flat_file_oep,profiling_dx_oep);

/*{top 1000 non-mental-health dx codes in sub-population defined in summary tables}*/
** Amy's comment: Jason, this should be recoded as proc sql **;
proc sort data=indata.diagnosis out=diagnosis;
by dx;
run;
proc sort data=infolder.mentalhealth;
by code;
run;
** Amy added DX_TYPE 9/15/19 **;
** This step selects 84,403,984 rows;
data dmlocal.non_mh_pat;
  merge diagnosis infolder.mentalhealth(rename=(code=dx) in=a);
  by dx;
  if a then delete;
  keep patid dx DX_TYPE;
run;

** Does this step truly remove mental health dx from indata.diagnosis? **;
** This step selects 27,048,288 rows;
/*proc sql;
  create table dmlocal.non_mh_pat as
  select patid, dx, DX_TYPE
  from indata.diagnosis
  except
  select code as dx
  from infolder.mentalhealth
  order by dx;
quit;*/

** Amy added DX_TYPE 9/15/19 **;
%macro nonmhdxprofiling(nonmhflatfile,nonmhproftable);
proc sql noprint outobs=1000;
  create table drnoc.&nonmhproftable as
  select distinct dx, DX_TYPE, count(dx) as freq
  from dmlocal.&nonmhflatfile as O, dmlocal.non_mh_pat as D
  where O.patid=D.patid
  group by dx
  order by freq desc;
quit;
data drnoc.&nonmhproftable;
  set drnoc.&nonmhproftable;
  if 0 < freq < &threshold then freq = .t;
run;
%mend nonmhdxprofiling;

/*Profiling TABLE - ALL*/
%nonmhdxprofiling(opioid_flat_file,profiling_nonmhdx_all);

/*Profiling TABLE - STD HISTORY*/
/*%nonmhdxprofiling(opioid_flat_file_std,profiling_nonmhdx_std); ** STD not defined **/

/*Profiling TABLE - CHRONIC OPIOID USE HISTORY*/
%nonmhdxprofiling(opioid_flat_file_cou,profiling_nonmhdx_cou);

/*Profiling TABLE -OVERDOSE HISTORY*/
%nonmhdxprofiling(opioid_flat_file_odh,profiling_nonmhdx_odh);

/*Profiling TABLE -SUD HISTORY*/
%nonmhdxprofiling(opioid_flat_file_sud,profiling_nonmhdx_sud);

/*Profiling TABLE -OUD+SUD, NOT AUD*/
%nonmhdxprofiling(opioid_flat_file_osud,profiling_nonmhdx_osud);

/*Profiling TABLE - OUD */
%nonmhdxprofiling(opioid_flat_file_oud,profiling_nonmhdx_oud);

/*Profiling TABLE - AUD */
%nonmhdxprofiling(opioid_flat_file_aud,profiling_nonmhdx_aud);

/*Profiling TABLE - OPIOID EXPOSURE */
%nonmhdxprofiling(opioid_flat_file_oep,profiling_nonmhdx_oep);

/*{top 1000 mental health dx codes in sub-population defined in summary tables}*/
/*CODE SUBSET = PRIMARY*/
** Amy added DX_TYPE 9/15/19 **;
proc sql noprint;
  create table dmlocal.mh_primary_pat as
  select patid, dx, D.DX_TYPE
  from infolder.mentalhealth as M, indata.diagnosis as D
  where M.code=D.dx and M.code_subset="Primary";
quit;

** Amy added DX_TYPE 9/15/19 **;
%macro mhprimdxprofiling(mhprimflatfile,mhprimproftable);
proc sql noprint outobs=1000;
  create table drnoc.&mhprimproftable as
  select distinct dx, DX_TYPE, count(dx) as freq
  from dmlocal.&mhprimflatfile as O, dmlocal.mh_primary_pat as D
  where O.patid=D.patid
  group by dx
  order by freq desc;
quit;
data DRNOC.&mhprimproftable;
  set DRNOC.&mhprimproftable;
  if 0 < freq < &threshold then freq = .t;
run;
%mend mhprimdxprofiling;

/*Profiling TABLE - ALL*/
%mhprimdxprofiling(opioid_flat_file,profiling_mhprimdx_all);

/*profiling TABLE - STD HISTORY*/
/*%mhprimdxprofiling(opioid_flat_file_std,profiling_mhprimdx_std); ** STD not defined **/

/*profiling TABLE - CHRONIC OPIOID USE HISTORY*/
%mhprimdxprofiling(opioid_flat_file_cou,profiling_mhprimdx_cou);

/*profiling TABLE -OVERDOSE HISTORY*/
%mhprimdxprofiling(opioid_flat_file_odh,profiling_mhprimdx_odh);

/*profiling TABLE -SUD HISTORY*/
%mhprimdxprofiling(opioid_flat_file_sud,profiling_mhprimdx_sud);

/*profiling TABLE -OUD+SUD, NOT AUD*/
%mhprimdxprofiling(opioid_flat_file_osud,profiling_mhprimdx_osud);

/*profiling TABLE - OUD */
%mhprimdxprofiling(opioid_flat_file_oud,profiling_mhprimdx_oud);

/*profiling TABLE - AUD */
%mhprimdxprofiling(opioid_flat_file_aud,profiling_mhprimdx_aud);

/*profiling TABLE - OPIOID EXPOSURE */
%mhprimdxprofiling(opioid_flat_file_oep,profiling_mhprimdx_oep);

/*CODE SUBSET = EXPLORATORY*/
** Amy added DX_TYPE 9/15/19 **;
proc sql noprint;
  create table dmlocal.mh_exploratory_pat as
  select patid, dx, D.DX_TYPE
  from infolder.mentalhealth as M, indata.diagnosis as D
  where M.code=D.dx and M.code_subset="Exploratory";
quit;

** Amy added DX_TYPE 9/15/19 **;
%macro mhexplordxprofiling(mhexplorflatfile,mhexplorproftable);
proc sql noprint outobs=1000;
  create table drnoc.&mhexplorproftable as
  select distinct dx, DX_TYPE, count(dx) as freq
  from dmlocal.&mhexplorflatfile as O, dmlocal.mh_exploratory_pat as D
  where O.patid=D.patid
  group by dx
  order by freq desc;
quit;
data DRNOC.&mhexplorproftable;
  set DRNOC.&mhexplorproftable;
  if 0 < freq < &threshold then freq = .t;
run;
%mend mhexplordxprofiling;

/*profiling TABLE - ALL*/
%mhexplordxprofiling(opioid_flat_file,profiling_mhexplordx_all);

/*profiling TABLE - STD HISTORY*/
/*%mhexplordxprofiling(opioid_flat_file_std,profiling_mhexplordx_std); ** STD not defined **/

/*profiling TABLE - CHRONIC OPIOID USE HISTORY*/
%mhexplordxprofiling(opioid_flat_file_cou,profiling_mhexplordx_cou);

/*profiling TABLE -OVERDOSE HISTORY*/
%mhexplordxprofiling(opioid_flat_file_odh,profiling_mhexplordx_odh);

/*profiling TABLE -SUD HISTORY*/
%mhexplordxprofiling(opioid_flat_file_sud,profiling_mhexplordx_sud);

/*profiling TABLE -OUD+SUD, NOT AUD*/
%mhexplordxprofiling(opioid_flat_file_osud,profiling_mhexplordx_osud);

/*profiling TABLE - OUD */
%mhexplordxprofiling(opioid_flat_file_oud,profiling_mhexplordx_oud);

/*profiling TABLE - AUD */
%mhexplordxprofiling(opioid_flat_file_aud,profiling_mhexplordx_aud);

/*profiling TABLE - OPIOID EXPOSURE */
%mhexplordxprofiling(opioid_flat_file_oep,profiling_mhexplordx_oep);

/*{top 1000 Px codes in sub-population defined in summary tables}*/
/*profiling TABLE - ALL*/
** Amy added PX_TYPE 9/15/19 **;
%macro pxprofiling(pxflatfile,pxproftable);
proc sql noprint outobs=1000;
  create table DRNOC.&pxproftable as
  select distinct px, PX_TYPE, count(px) as freq
  from dmlocal.&pxflatfile as O, indata.procedures as D
  where O.patid=D.patid
  group by px
  order by freq desc;
quit;
data DRNOC.&pxproftable;
  set DRNOC.&pxproftable;
  if 0 < freq < &threshold then freq = .t;
run;
%mend;

/*profiling TABLE - ALL*/
%pxprofiling(opioid_flat_file,profiling_px_all);

/*profiling TABLE - STD HISTORY*/
/*%pxprofiling(opioid_flat_file_std,profiling_px_std); ** STD not defined **/

/*profiling TABLE - CHRONIC OPIOID USE HISTORY*/
%pxprofiling(opioid_flat_file_cou,profiling_px_cou);

/*profiling TABLE -OVERDOSE HISTORY*/
%pxprofiling(opioid_flat_file_odh,profiling_px_odh);

/*profiling TABLE -SUD HISTORY*/
%pxprofiling(opioid_flat_file_sud,profiling_px_sud);

/*profiling TABLE -OUD+SUD, NOT AUD*/
%pxprofiling(opioid_flat_file_osud,profiling_px_osud);

/*profiling TABLE - OUD */
%pxprofiling(opioid_flat_file_oud,profiling_px_oud);

/*profiling TABLE - AUD */
%pxprofiling(opioid_flat_file_aud,profiling_px_aud);

/*profiling TABLE - OPIOID EXPOSURE */
%pxprofiling(opioid_flat_file_oep,profiling_px_oep);
