%let threshold=11;

/*{top 1000 dx codes in sub-population defined in summary tables}*/
%macro dxprofilling(flatfile,proftable);
proc sql noprint outobs=1000;
create table DRNOC.&proftable as
select distinct dx, count(dx) as freq
from dmlocal.&flatfile as O, indata.diagnosis as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data DRNOC.proftable;
set DRNOC.proftable;
if 0<freq<&threshold then freq=.t;
run;
%mend;
/*Profilling TABLE - ALL*/
%dxprofilling(opioid_flat_file,profilling_dx_all);

/*Profilling TABLE - STD HISTORY*/
%dxprofilling(opioid_flat_file_std,profilling_dx_std);

/*Profilling TABLE - CHRONIC OPIOID USE HISTORY*/
%dxprofilling(opioid_flat_file_cou,profilling_dx_cou);

/*Profilling TABLE -OVERDOSE HISTORY*/
%dxprofilling(opioid_flat_file_odh,profilling_dx_odh);

/*Profilling TABLE -SUD HISTORY*/
%dxprofilling(opioid_flat_file_sud,profilling_dx_sud);

/*Profilling TABLE -OUD+SUD, NOT AUD*/
%dxprofilling(opioid_flat_file_osud,profilling_dx_osud);

/*Profilling TABLE - OUD */
%dxprofilling(opioid_flat_file_oud,profilling_dx_oud);

/*Profilling TABLE - AUD */
%dxprofilling(opioid_flat_file_aud,profilling_dx_aud);

/*Profilling TABLE - OPIOID EXPOSURE */
%dxprofilling(opioid_flat_file_oep,profilling_dx_oep);

/*{top 1000 non-mental-health dx codes in sub-population defined in summary tables}*/

proc sort data=indata.diagnosis out=diagnosis;
by dx;
run;
proc sort data=infolder.mentalhealth;
by code;
run;
data dmlocal.non_mh_pat;
merge diagnosis infolder.mentalhealth(rename=(code=dx) in=a);
by dx;
if a then delete;
keep patid dx;
run;

%macro nonmhdxprofilling(nonmhflatfile,nonmhproftable);
proc sql noprint outobs=1000;
create table drnoc.&nonmhproftable as
select distinct dx, count(dx) as freq
from dmlocal.&nonmhflatfile as O, dmlocal.non_mh_pat as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data drnoc.&nonmhproftable;
set drnoc.&nonmhproftable;
if 0<freq<&threshold then freq=.t;
run;
%mend nonmhdxprofilling;
/*Profilling TABLE - ALL*/
%nonmhdxprofilling(opioid_flat_file,profilling_nonmhdx_all);

/*Profilling TABLE - STD HISTORY*/
%nonmhdxprofilling(opioid_flat_file_std,profilling_nonmhdx_std);

/*Profilling TABLE - CHRONIC OPIOID USE HISTORY*/
%nonmhdxprofilling(opioid_flat_file_cou,profilling_nonmhdx_cou);

/*Profilling TABLE -OVERDOSE HISTORY*/
%nonmhdxprofilling(opioid_flat_file_odh,profilling_nonmhdx_odh);

/*Profilling TABLE -SUD HISTORY*/
%nonmhdxprofilling(opioid_flat_file_sud,profilling_nonmhdx_sud);

/*Profilling TABLE -OUD+SUD, NOT AUD*/
%nonmhdxprofilling(opioid_flat_file_osud,profilling_nonmhdx_osud);

/*Profilling TABLE - OUD */
%nonmhdxprofilling(opioid_flat_file_oud,profilling_nonmhdx_oud);

/*Profilling TABLE - AUD */
%nonmhdxprofilling(opioid_flat_file_aud,profilling_nonmhdx_aud);

/*Profilling TABLE - OPIOID EXPOSURE */
%nonmhdxprofilling(opioid_flat_file_oep,profilling_nonmhdx_oep);

/*{top 1000 mental health dx codes in sub-population defined in summary tables}*/
/*CODE SUBSET = PRIMARY*/
proc sql noprint;
create table dmlocal.mh_primary_pat as
select patid,dx
from infolder.mentalhealth as M,indata.diagnosis as D
where M.code=D.dx and M.code_subset="Primary";
quit;

%macro mhprimdxprofilling(mhprimflatfile,mhprimproftable);
proc sql noprint outobs=1000;
create table drnoc.&mhprimproftable as
select distinct dx, count(dx) as freq
from dmlocal.&mhprimflatfile as O, dmlocal.mh_primary_pat as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data DRNOC.&mhprimproftable;
set DRNOC.&mhprimproftable;
if 0<freq<&threshold then freq=.t;
run;
%mend mhprimdxprofilling;

/*Profilling TABLE - ALL*/
%mhprimdxprofilling(opioid_flat_file,profilling_mhprimdx_all);

/*Profilling TABLE - STD HISTORY*/
%mhprimdxprofilling(opioid_flat_file_std,profilling_mhprimdx_std);

/*Profilling TABLE - CHRONIC OPIOID USE HISTORY*/
%mhprimdxprofilling(opioid_flat_file_cou,profilling_mhprimdx_cou);

/*Profilling TABLE -OVERDOSE HISTORY*/
%mhprimdxprofilling(opioid_flat_file_odh,profilling_mhprimdx_odh);

/*Profilling TABLE -SUD HISTORY*/
%mhprimdxprofilling(opioid_flat_file_sud,profilling_mhprimdx_sud);

/*Profilling TABLE -OUD+SUD, NOT AUD*/
%mhprimdxprofilling(opioid_flat_file_osud,profilling_mhprimdx_osud);

/*Profilling TABLE - OUD */
%mhprimdxprofilling(opioid_flat_file_oud,profilling_mhprimdx_oud);

/*Profilling TABLE - AUD */
%mhprimdxprofilling(opioid_flat_file_aud,profilling_mhprimdx_aud);

/*Profilling TABLE - OPIOID EXPOSURE */
%mhprimdxprofilling(opioid_flat_file_oep,profilling_mhprimdx_oep);

/*CODE SUBSET = EXPLORATORY*/
proc sql noprint;
create table dmlocal.mh_exploratory_pat as
select patid,dx
from infolder.mentalhealth as M,indata.diagnosis as D
where M.code=D.dx and M.code_subset="Exploratory";
quit;

%macro mhexplordxprofilling(mhexplorflatfile,mhexplorproftable);
proc sql noprint outobs=1000;
create table drnoc.&mhexplorproftable as
select distinct dx, count(dx) as freq
from dmlocal.&mhexplorflatfile as O, dmlocal.mh_exploratory_pat as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data DRNOC.&mhexplorproftable;
set DRNOC.&mhexplorproftable;
if 0<freq<&threshold then freq=.t;
run;
%mend mhexplordxprofilling;

/*Profilling TABLE - ALL*/
%mhexplordxprofilling(opioid_flat_file,profilling_mhexplordx_all);

/*Profilling TABLE - STD HISTORY*/
%mhexplordxprofilling(opioid_flat_file_std,profilling_mhexplordx_std);

/*Profilling TABLE - CHRONIC OPIOID USE HISTORY*/
%mhexplordxprofilling(opioid_flat_file_cou,profilling_mhexplordx_cou);

/*Profilling TABLE -OVERDOSE HISTORY*/
%mhexplordxprofilling(opioid_flat_file_odh,profilling_mhexplordx_odh);

/*Profilling TABLE -SUD HISTORY*/
%mhexplordxprofilling(opioid_flat_file_sud,profilling_mhexplordx_sud);

/*Profilling TABLE -OUD+SUD, NOT AUD*/
%mhexplordxprofilling(opioid_flat_file_osud,profilling_mhexplordx_osud);

/*Profilling TABLE - OUD */
%mhexplordxprofilling(opioid_flat_file_oud,profilling_mhexplordx_oud);

/*Profilling TABLE - AUD */
%mhexplordxprofilling(opioid_flat_file_aud,profilling_mhexplordx_aud);

/*Profilling TABLE - OPIOID EXPOSURE */
%mhexplordxprofilling(opioid_flat_file_oep,profilling_mhexplordx_oep);

/*{top 1000 Px codes in sub-population defined in summary tables}*/
/*Profilling TABLE - ALL*/
proc sql noprint outobs=1000;
create table profilling_px_all as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
data drnoc.&profilling_px_all;
set drnoc.&profilling_px_all;
if 0<freq<&threshold then freq=.t;
run;
%macro pxprofilling(pxflatfile,pxproftable);
proc sql noprint outobs=1000;
create table DRNOC.&pxproftable as
select distinct px, count(px) as freq
from dmlocal.&pxflatfile as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
data DRNOC.pxproftable;
set DRNOC.pxproftable;
if 0<freq<&threshold then freq=.t;
run;
%mend;
/*Profilling TABLE - ALL*/
%pxprofilling(opioid_flat_file,profilling_px_all);

/*Profilling TABLE - STD HISTORY*/
%pxprofilling(opioid_flat_file_std,profilling_px_std);

/*Profilling TABLE - CHRONIC OPIOID USE HISTORY*/
%pxprofilling(opioid_flat_file_cou,profilling_px_cou);

/*Profilling TABLE -OVERDOSE HISTORY*/
%pxprofilling(opioid_flat_file_odh,profilling_px_odh);

/*Profilling TABLE -SUD HISTORY*/
%pxprofilling(opioid_flat_file_sud,profilling_px_sud);

/*Profilling TABLE -OUD+SUD, NOT AUD*/
%pxprofilling(opioid_flat_file_osud,profilling_px_osud);

/*Profilling TABLE - OUD */
%pxprofilling(opioid_flat_file_oud,profilling_px_oud);

/*Profilling TABLE - AUD */
%pxprofilling(opioid_flat_file_aud,profilling_px_aud);

/*Profilling TABLE - OPIOID EXPOSURE */
%pxprofilling(opioid_flat_file_oep,profilling_px_oep);
