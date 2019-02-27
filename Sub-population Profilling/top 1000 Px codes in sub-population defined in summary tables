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
/*Profilling TABLE - STD HISTORY*/
proc sql noprint outobs=1000;
proc sql noprint outobs=1000;
create table profilling_px_std as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file_std as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
/*Profilling TABLE - CHRONIC OPIOID USE HISTORY*/
proc sql noprint outobs=1000;
create table profilling_px_cou as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file_cou as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
/*Profilling TABLE -OVERDOSE HISTORY*/
proc sql noprint outobs=1000;
create table profilling_px_odh as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file_odh as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
/*Profilling TABLE -SUD HISTORY*/
proc sql noprint outobs=1000;
create table profilling_px_sud as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file_sud as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
/*Profilling TABLE -OUD+SUD, NOT AUD*/
proc sql noprint outobs=1000;
create table profilling_px_osud as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file_osud as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
/*Profilling TABLE - OUD */
proc sql noprint outobs=1000;
create table profilling_px_oud as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file_oud as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
/*Profilling TABLE - OPIOID EXPOSURE */
proc sql noprint outobs=1000;
create table profilling_px_oep as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file_oep as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
