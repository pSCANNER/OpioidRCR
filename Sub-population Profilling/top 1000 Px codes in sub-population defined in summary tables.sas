%let threshold=11;
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
data profilling_px_all;
set profilling_px_all;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE - STD HISTORY*/
proc sql noprint outobs=1000;
create table profilling_px_std as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file_std as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
data profilling_px_std;
set profilling_px_std;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE - CHRONIC OPIOID USE HISTORY*/
proc sql noprint outobs=1000;
create table profilling_px_cou as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file_cou as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
data profilling_px_cou;
set profilling_px_cou;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE -OVERDOSE HISTORY*/
proc sql noprint outobs=1000;
create table profilling_px_odh as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file_odh as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
data profilling_px_odh;
set profilling_px_odh;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE -SUD HISTORY*/
proc sql noprint outobs=1000;
create table profilling_px_sud as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file_sud as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
data profilling_px_sud;
set profilling_px_sud;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE -OUD+SUD, NOT AUD*/
proc sql noprint outobs=1000;
create table profilling_px_osud as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file_osud as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
data profilling_px_osud;
set profilling_px_osud;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE - OUD */
proc sql noprint outobs=1000;
create table profilling_px_oud as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file_oud as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
data profilling_px_oud;
set profilling_px_oud;
if 0<freq<&threshold then freq=.t;
run;
/*Profilling TABLE - AUD */
proc sql noprint outobs=1000;
create table profilling_px_aud as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file_aud as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
data profilling_px_aud;
set profilling_px_aud;
if 0<freq<&threshold then freq=.t;
run;

/*Profilling TABLE - OPIOID EXPOSURE */
proc sql noprint outobs=1000;
create table profilling_px_oep as
select distinct px, count(px) as freq
from dmlocal.opioid_flat_file_oep as O, indata.procedures as D
where O.patid=D.patid
group by px
order by freq desc;
quit;
data profilling_px_oep;
set profilling_px_oep;
if 0<freq<&threshold then freq=.t;
run;
