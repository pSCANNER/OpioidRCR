/*This is used for changing threshold to actual number 5 and merging OUD and OSUD summary tables.*/
libname final "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\Clean_Summary_Tables\AggregateSummaryTables";
libname update "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\Clean_Summary_Tables\AggregateSummaryTable-v2-no Ts";

%MACRO updatethreshold(ds);
                PROC CONTENTS DATA=final.&ds OUT=contents (KEEP=name) NOPRINT ;
                RUN;

                proc sql noprint;
                select name
                into: Varlist separated " "
                from  work.contents
                where name not in ("site","facility_location","race","sex","hispanic","AGEGRP1","eventyear") ;
				quit;


                DATA update.&ds;
                        SET final.&ds;
                RUN;
                %LET varlist=&Varlist;
                %LET k=1;
                %LET var=%SCAN(&varlist,&k);
                %Do %WHILE ("&var" NE "");
                        DATA update.&ds;
                        SET update.&ds;
                        IF &var= .t then &var=5;
                        RUN;
                        %LET k=%EVAL(&k+1);
                        %LET var=%SCAN(&varlist,&k);
                %END;

%MEND;

%updatethreshold(sum_all);
%updatethreshold(sum_all_exc_cancer);
%updatethreshold(sum_aud);
%updatethreshold(sum_chronic_opioid);
%updatethreshold(sum_opioid_exposure);
%updatethreshold(sum_osud);
%updatethreshold(sum_oud);
%updatethreshold(sum_overdose);
%updatethreshold(sum_std);
%updatethreshold(sum_sud);

%MACRO binaryupdatethreshold(ds);
                PROC CONTENTS DATA=final.&ds OUT=contents (KEEP=name) NOPRINT ;
                RUN;

                proc sql noprint;
                select name
                into: Varlist separated " "
                from  work.contents
                where name not in ("site","facility_location","binary_race","binary_sex","binary_hispanic","eventyear","mean_age") ;
				quit;


                DATA update.&ds;
                        SET final.&ds;
                RUN;
                %LET varlist=&Varlist;
                %LET k=1;
                %LET var=%SCAN(&varlist,&k);
                %Do %WHILE ("&var" NE "");
                        DATA update.&ds;
                        SET update.&ds;
                        IF &var= .t then &var=5;
                        RUN;
                        %LET k=%EVAL(&k+1);
                        %LET var=%SCAN(&varlist,&k);
                %END;

%MEND;
%binaryupdatethreshold(sum_binary);

%macro preclean(input,ds);
data org;
retain keyx;
set &input;
length keyx	 $ 400;
label keyx = 'Keys';
keyx = 	strip(site)|| '-' ||
		strip(Facility_Location)|| '-' ||
       strip(RACE)|| '-' ||
	   strip(SEX)|| '-' ||
	   strip(HISPANIC)|| '-' ||
	   strip(AGEGRP1) || '-' ||
	   strip(put(EventYear, z4.));
run;



data keys_&ds(keep = site keyx Facility_Location Race Sex Hispanic Agegrp1 EventYear)
     data_&ds(drop = site Facility_Location Race Sex Hispanic Agegrp1 EventYear);
set org;
run;


proc sort data=data_&ds;
by keyx;
run;

proc sort data=keys_&ds;
by keyx;
run;
%mend preclean;
%preclean(update.sum_oud,oud);
%preclean(update.sum_osud,osud);

data test;
set data_osud data_oud;
by keyx;
array sums{147} _temporary_;
array nums{*} _numeric_;
if first.keyx then do I=1 to dim(sums);
sums{I}=0;
end;
do I=1 to dim(sums);
sums{i}+nums{I};
nums{I}=sums{I};
end;
if last.keyx;
drop I;
run;


data update.sum_osudoud;
merge keys_osud keys_oud test ;
by keyx;
drop keyx;
run;
