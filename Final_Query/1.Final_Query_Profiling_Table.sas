LIBNAME old "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\AggregateData";
LIBNAME new "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\UpdatedAggregateData";
%LET oldpath=C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\AggregateData\;
%LET newpath=C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\UpdatedAggregateData\;


%MACRO import(filename,dataset);
PROC IMPORT OUT= OLD.&dataset
            DATAFILE= "&oldpath&filename" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
%MEND import;
%import (concept.csv,concept);
%MACRO join(filename,dataset);
PROC IMPORT OUT= OLD.&dataset
            DATAFILE= "&oldpath&filename" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
proc sql noprint;
create table new.&dataset as
select P.site, P.dx, P.freq, C.concept_name
from old.&dataset P,old.concept C
where P.dx=C.concept_code;
quit;
proc sort data=new.&dataset nodupkey;
by site dx concept_name;
run;
proc sort data=new.&dataset;
by site descending freq;
run;
PROC EXPORT DATA=new.&dataset
            OUTFILE= "&newpath&dataset..csv" 
            DBMS=CSV REPLACE;
RUN;

%MEND join;

%join(profilling_dx_all.csv,profiling_dx_all);
%join(profilling_dx_aud.csv,profiling_dx_aud);
%join(profilling_dx_cou.csv,profiling_dx_cou);
%join(profilling_dx_odh.csv,profiling_dx_odh);
%join(profilling_dx_oep.csv,profiling_dx_oep);
%join(profilling_dx_osud.csv,profiling_dx_osud);
%join(profilling_dx_oud.csv,profiling_dx_oud);
%join(profilling_dx_std.csv,profiling_dx_std);
%join(profilling_dx_sud.csv,profiling_dx_sud);

%join(profilling_mhexplordx_all.csv,profiling_mhexplordx_all);
%join(profilling_mhexplordx_aud.csv,profiling_mhexplordx_aud);
%join(profilling_mhexplordx_cou.csv,profiling_mhexplordx_cou);
%join(profilling_mhexplordx_odh.csv,profiling_mhexplordx_odh);
%join(profilling_mhexplordx_oep.csv,profiling_mhexplordx_oep);
%join(profilling_mhexplordx_osud.csv,profiling_mhexplordx_osud);
%join(profilling_mhexplordx_oud.csv,profiling_mhexplordx_oud);
%join(profilling_mhexplordx_std.csv,profiling_mhexplordx_std);
%join(profilling_mhexplordx_sud.csv,profiling_mhexplordx_sud);

%join(profilling_mhprimdx_all.csv,profiling_mhprimdx_all);
%join(profilling_mhprimdx_aud.csv,profiling_mhprimdx_aud);
%join(profilling_mhprimdx_cou.csv,profiling_mhprimdx_cou);
%join(profilling_mhprimdx_odh.csv,profiling_mhprimdx_odh);
%join(profilling_mhprimdx_oep.csv,profiling_mhprimdx_oep);
%join(profilling_mhprimdx_osud.csv,profiling_mhprimdx_osud);
%join(profilling_mhprimdx_oud.csv,profiling_mhprimdx_oud);
%join(profilling_mhprimdx_std.csv,profiling_mhprimdx_std);
%join(profilling_mhprimdx_sud.csv,profiling_mhprimdx_sud);

%join(profilling_nonmhdx_all.csv,profiling_nonmhdx_all);
%join(profilling_nonmhdx_aud.csv,profiling_nonmhdx_aud);
%join(profilling_nonmhdx_cou.csv,profiling_nonmhdx_cou);
%join(profilling_nonmhdx_odh.csv,profiling_nonmhdx_odh);
%join(profilling_nonmhdx_oep.csv,profiling_nonmhdx_oep);
%join(profilling_nonmhdx_osud.csv,profiling_nonmhdx_osud);
%join(profilling_nonmhdx_oud.csv,profiling_nonmhdx_oud);
%join(profilling_nonmhdx_std.csv,profiling_nonmhdx_std);
%join(profilling_nonmhdx_sud.csv,profiling_nonmhdx_sud);

%MACRO pxjoin(filename,dataset);
PROC IMPORT OUT= OLD.&dataset
            DATAFILE= "&oldpath&filename" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
proc sql noprint;
create table new.&dataset as
select P.site, P.px, P.freq, C.concept_name
from old.&dataset P,old.concept C
where P.px=C.concept_code;
quit;
proc sort data=new.&dataset nodupkey;
by site px concept_name;
run;
proc sort data=new.&dataset;
by site descending freq;
run;
PROC EXPORT DATA=new.&dataset
            OUTFILE= "&newpath&dataset..csv" 
            DBMS=CSV REPLACE;
RUN;

%MEND pxjoin;

%pxjoin(profilling_px_all.csv,profiling_px_all);
%pxjoin(profilling_px_aud.csv,profiling_px_aud);
%pxjoin(profilling_px_cou.csv,profiling_px_cou);
%pxjoin(profilling_px_odh.csv,profiling_px_odh);
%pxjoin(profilling_px_oep.csv,profiling_px_oep);
%pxjoin(profilling_px_osud.csv,profiling_px_osud);
%pxjoin(profilling_px_oud.csv,profiling_px_oud);
%pxjoin(profilling_px_std.csv,profiling_px_std);
%pxjoin(profilling_px_sud.csv,profiling_px_sud);
