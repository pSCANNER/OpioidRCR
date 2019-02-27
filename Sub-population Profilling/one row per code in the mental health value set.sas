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

/*Profilling TABLE - STD HISTORY*/
proc sql noprint outobs=1000;
create table profilling_mhprim_dx_std as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_std as O, mhprimary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
/*Profilling TABLE - CHRONIC OPIOID USE HISTORY*/
proc sql noprint outobs=1000;
create table profilling_mhprim_dx_cou as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_cou as O, mhprimary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
/*Profilling TABLE -OVERDOSE HISTORY*/
proc sql noprint outobs=1000;
create table profilling_mhprim_dx_odh as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_odh as O, mhprimary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
/*Profilling TABLE -SUD HISTORY*/
proc sql noprint outobs=1000;
create table profilling_mhprim_dx_sud as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_sud as O, mhprimary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
/*Profilling TABLE -OUD+SUD, NOT AUD*/
proc sql noprint outobs=1000;
create table profilling_mhprim_dx_osud as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_osud as O, mhprimary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
/*Profilling TABLE - OUD */
proc sql noprint outobs=1000;
create table profilling_mhprim_oud as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_oud as O, mhprimary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
/*Profilling TABLE - OPIOID EXPOSURE */
proc sql noprint outobs=1000;
create table profilling_mhprim_dx_oep as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_oep as O, mhprimary as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
