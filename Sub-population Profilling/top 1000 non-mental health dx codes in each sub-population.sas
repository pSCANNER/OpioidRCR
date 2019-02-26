proc sort data=indata.diagnosis;
by dx;
run;
proc sort data=infolder.mentalhealth;
by code;
run;
data non_mh;
merge indata.diagnosis infolder.mentalhealth(rename=(code=dx) in=a);
by dx;
if a then delte;
run;

/*{top 1000 non-mental-health dx codes in sub-population defined in summary tables}*/
/*Profilling TABLE - ALL*/
proc sql noprint outobs=1000;
create table profilling_nomh_dx_all as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file as O, non_mh as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
/*Profilling TABLE - STD HISTORY*/
proc sql noprint outobs=1000;
create table profilling_non_mh_dx_std as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_std as O, non_mh as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
/*Profilling TABLE - CHRONIC OPIOID USE HISTORY*/
proc sql noprint outobs=1000;
create table profilling_non_mh_dx_cou as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_cou as O, non_mh as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
/*Profilling TABLE -OVERDOSE HISTORY*/
proc sql noprint outobs=1000;
create table profilling_non_mh_dx_odh as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_odh as O, non_mh as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
/*Profilling TABLE -SUD HISTORY*/
proc sql noprint outobs=1000;
create table profilling_non_mh_dx_sud as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_sud as O, non_mh as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
/*Profilling TABLE -OUD+SUD, NOT AUD*/
proc sql noprint outobs=1000;
create table profilling_non_mh_dx_osud as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_osud as O, non_mh as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
/*Profilling TABLE - OUD */
proc sql noprint outobs=1000;
create table profilling_non_mh_dx_oud as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_oud as O, non_mh as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
/*Profilling TABLE - OPIOID EXPOSURE */
proc sql noprint outobs=1000;
create table profilling_non_mh_dx_oep as
select distinct dx, count(dx) as freq
from dmlocal.opioid_flat_file_oep as O, non_mh as D
where O.patid=D.patid
group by dx
order by freq desc;
quit;
