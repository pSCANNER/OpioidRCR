%let threshold=11;
/*CODE SUBSET = PRIMARY*/
proc sql noprint;
create table mh_primary as
select patid,dx
from infolder.mentalhealth as M,indata.diagnosis as D
where M.code=D.dx and M.code_subset="Primary";
quit;

/*{top 1000 mental health dx codes in sub-population defined in summary tables}*/
/*Profilling TABLE - ALL*/
proc sql noprint;
create table profilling_mhprim_dx_all as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file as O, mh_primary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhprim_dx_all;
set profilling_mhprim_dx_all;
if 0<freq<&threshold then freq=.t;
run;

/*Profilling TABLE - STD HISTORY*/
proc sql noprint;
create table profilling_mhprim_dx_std as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_std as O, mhprimary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhprim_dx_std;
set profilling_mhprim_dx_std;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE - CHRONIC OPIOID USE HISTORY*/
proc sql noprint;
create table profilling_mhprim_dx_cou as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_cou as O, mhprimary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhprim_dx_cou;
set profilling_mhprim_dx_cou;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE -OVERDOSE HISTORY*/
proc sql noprint;
create table profilling_mhprim_dx_odh as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_odh as O, mhprimary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhprim_dx_odh;
set profilling_mhprim_dx_odh;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE -SUD HISTORY*/
proc sql noprint;
create table profilling_mhprim_dx_sud as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_sud as O, mhprimary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhprim_dx_sud;
set profilling_mhprim_dx_sud;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE -OUD+SUD, NOT AUD*/
proc sql noprint;
create table profilling_mhprim_dx_osud as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_osud as O, mhprimary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhprim_dx_osud;
set profilling_mhprim_dx_osud;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE - OUD */
proc sql noprint;
create table profilling_mhprim_dx_oud as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_oud as O, mhprimary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhprim_dx_oud;
set profilling_mhprim_dx_oud;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE - AUD */
proc sql noprint;
create table profilling_mhprim_dx_aud as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_aud as O, mhprimary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhprim_dx_aud;
set profilling_mhprim_dx_aud;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE - OPIOID EXPOSURE */
proc sql noprint;
create table profilling_mhprim_dx_oep as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_oep as O, mhprimary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhprim_dx_oep;
set profilling_mhprim_dx_oep;
if 0<freq<&threshold then freq=.t;
run;
/*--------------------------------------------------------------------------------------
  CODE SUBSET = EXPLORATORY
  --------------------------------------------------------------------------------------*/
proc sql noprint;
create table mh_exploratory as
select patid,dx
from infolder.mentalhealth as M,indata.diagnosis as D
where M.code=D.dx and M.code_subset="Exploratory";
quit;

/*{top 1000 mental health dx codes in sub-population defined in summary tables}*/
/*Profilling TABLE - ALL*/
proc sql noprint;
create table profilling_mhexplor_dx_all as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file as O, mh_exploratory as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhexplor_dx_all;
set profilling_mhexplor_dx_all;
if 0<freq<&threshold then freq=.t;
run;

/*Profilling TABLE - STD HISTORY*/
proc sql noprint;
create table profilling_mhexplor_dx_std as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_std as O, mhexploratory as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhexplor_dx_std;
set profilling_mhexplor_dx_std;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE - CHRONIC OPIOID USE HISTORY*/
proc sql noprint;
create table profilling_mhexplor_dx_cou as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_cou as O, mhexploratory as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhexplor_dx_cou;
set profilling_mhexplor_dx_cou;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE -OVERDOSE HISTORY*/
proc sql noprint;
create table profilling_mhexplor_dx_odh as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_odh as O, mhexploratory as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhexplor_dx_odh;
set profilling_mhexplor_dx_odh;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE -SUD HISTORY*/
proc sql noprint;
create table profilling_mhexplor_dx_sud as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_sud as O, mhexploratory as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhexplor_dx_sud;
set profilling_mhexplor_dx_sud;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE -OUD+SUD, NOT AUD*/
proc sql noprint;
create table profilling_mhexplor_dx_osud as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_osud as O, mhexploratory as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhexplor_dx_osud;
set profilling_mhexplor_dx_osud;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE - OUD */
proc sql noprint;
create table profilling_mhexplor_dx_oud as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_oud as O, mhexploratory as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhexplor_dx_oud;
set profilling_mhexplor_dx_oud;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE - OPIOID EXPOSURE */
proc sql noprint;
create table profilling_mhexplor_dx_oep as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_oep as O, mhexploratory as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
data profilling_mhexplor_dx_oep;
set profilling_mhexplor_dx_oep;
if 0<freq<&threshold then freq=.t;
run;
