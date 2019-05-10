LIBNAME old "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\AggregateData";
LIBNAME new "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\UpdatedAggregateData";
LIBNAME den1 "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\UpdatedAggregateData\Snapshots\opioid_exposure";
LIBNAME den2 "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\UpdatedAggregateData\Snapshots\chronic_opioid_use";
LIBNAME den3 "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\UpdatedAggregateData\Snapshots\opioid_use_disorder";
LIBNAME den4 "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\UpdatedAggregateData\Snapshots\overdose_history";
%LET oldpath=C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\AggregateData\;
%LET newpath=C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\UpdatedAggregateData\;
%LET den1=C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\UpdatedAggregateData\Snapshots\opioid_exposure\;
%LET den2=C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\UpdatedAggregateData\Snapshots\chronic_opioid_use\;
%LET den3=C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\UpdatedAggregateData\Snapshots\opioid_use_disorder\;
%LET den4=C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\UpdatedAggregateData\Snapshots\overdose_history\;

%MACRO export(dataset);
PROC EXPORT DATA=&dataset
            OUTFILE= "&den1&dataset..csv" 
            DBMS=CSV REPLACE;
RUN;
%MEND export;
/*SNAPSHOT-Opioid_Exposed_Population*/
%MACRO export(dataset);
PROC EXPORT DATA=&dataset
            OUTFILE= "&den1&dataset..csv" 
            DBMS=CSV REPLACE;
RUN;
%MEND export;
proc sql noprint;
create table den1.opioid_exposed_snapshot1 as
select sum(n_70) as num_opiod_exposure, sum(n) as total_observation, sum(n_70)/sum(n) as percent_opioid_exposure
from old.sum_binary;
quit;
%export (den1.opioid_exposed_snapshot1);

proc sql noprint;
create table den1.opioid_exposed_snapshot2 as
select facility_location,binary_race, binary_sex, binary_hispanic,eventyear,mean_age,
sum(n_70) as num_opiod_exposure, sum(n) as total_observation, sum(n_70)/sum(n) as percent_opioid_exposure
from old.sum_binary
group by facility_location,binary_race, binary_sex, binary_hispanic,eventyear;
quit;
%export (den1.opioid_exposed_snapshot2);

%macro snapshot3(input,output);
proc sql noprint;
create table &output as
select (select sum(n) from &input where n_5=1 and n_6=1) as num_bdz, sum(n) as total_observation,
(select sum(n) from &input where n_5=1 and n_6=1)/sum(n) as percent_bdz
from &input;
quit;
%mend;
%snapshot3(old.sum_opioid_exposure,den1.opioid_exposed_snapshot3);
%export(den1.opioid_exposed_snapshot3);

%macro snapshot4(input,output);
proc sql noprint;
create table &output as
select sum(n_56) as num_mhpri,sum(n) as total_observation,sum(n_56)/sum(n) as percent_mhpri
from &input;
quit;
%mend;
%snapshot4(old.sum_opioid_exposure,den1.opioid_exposed_snapshot4);
%export(den1.opioid_exposed_snapshot4);

%macro snapshot5(input,output);
proc sql noprint;
create table &output as
select sum(n_54) as num_mhexp,sum(n) as total_observation,sum(n_54)/sum(n) as percent_mhexp
from &input;
quit;
%mend;
%snapshot5(old.sum_opioid_exposure,den1.opioid_exposed_snapshot5);
%export(den1.opioid_exposed_snapshot5);

%macro snapshot6(input,output);
proc sql noprint;
create table &output as
select sum(n_75) as num_OUD,sum(n) as total_observation,sum(n_75)/sum(n) as percent_OUD
from &input;
quit;
%mend;
%snapshot6(old.sum_opioid_exposure,den1.opioid_exposed_snapshot6);
%export(den1.opioid_exposed_snapshot6);

%macro snapshot7(input,output);
proc sql noprint;
create table &output as
select sum(n_86) as num_SUD,sum(n) as total_observation,sum(n_86)/sum(n) as percent_SUD
from &input;
quit;
%mend;
%snapshot7(old.sum_opioid_exposure,den1.opioid_exposed_snapshot7);
%export(den1.opioid_exposed_snapshot7);

%macro snapshot8(input,output);
proc sql noprint;
create table &output as
select sum(n_3) as num_AUD,sum(n) as total_observation,sum(n_3)/sum(n) as percent_AUD
from &input;
quit;
%mend;
%snapshot8(old.sum_opioid_exposure,den1.opioid_exposed_snapshot8);
%export(den1.opioid_exposed_snapshot8);

%macro snapshot9(input,output);
proc sql noprint;
create table &output as
select sum(n_27) as num_CocaineUD,sum(n) as total_observation,sum(n_27)/sum(n) as percent_CocaineUD
from &input;
quit;
%mend;
%snapshot9(old.sum_opioid_exposure,den1.opioid_exposed_snapshot9);
%export(den1.opioid_exposed_snapshot9);

%macro snapshot10(input,output);
proc sql noprint;
create table &output as
select sum(n_39) as num_HallucinogenUD,sum(n) as total_observation,sum(n_39)/sum(n) as percent_HallucinogenUD
from &input;
quit;
%mend;
%snapshot10(old.sum_opioid_exposure,den1.opioid_exposed_snapshot10);
%export(den1.opioid_exposed_snapshot10);

%macro snapshot11(input,output);
proc sql noprint;
create table &output as
select sum(n_77) as num_otherstimUD,sum(n) as total_observation,sum(n_77)/sum(n) as percent_otherstimUD
from &input;
quit;
%mend;
%snapshot11(old.sum_opioid_exposure,den1.opioid_exposed_snapshot11);
%export(den1.opioid_exposed_snapshot11);

%macro snapshot12(input,output);
proc sql noprint;
create table &output as
select sum(n_24) as num_CannabisUD,sum(n) as total_observation,sum(n_24)/sum(n) as percent_CannabisUD
from &input;
quit;
%mend;
%snapshot12(old.sum_opioid_exposure,den1.opioid_exposed_snapshot12);
%export(den1.opioid_exposed_snapshot12);

%macro snapshot13(input,output);
proc sql noprint;
create table &output as
select sum(n_46) as num_InhalantUD,sum(n) as total_observation,sum(n_46)/sum(n) as percent_InhalantUD
from &input;
quit;
%mend;
%snapshot13(old.sum_opioid_exposure,den1.opioid_exposed_snapshot13);
%export(den1.opioid_exposed_snapshot13);

%macro snapshot14(input,output);
proc sql noprint;
create table &output as
select sum(n_14) as num_Chronic_Opioid,sum(n) as total_observation,sum(n_14)/sum(n) as percent_Chronic_Opioid
from &input;
quit;
%mend;
%snapshot14(old.sum_opioid_exposure,den1.opioid_exposed_snapshot14);
%export(den1.opioid_exposed_snapshot14);

%macro snapshot15(input,output);
proc sql noprint;
create table &output as
select sum(n_34) as num_Chronic_ED_YR,sum(n) as total_observation,sum(n_34)/sum(n) as percent_ED_YR
from &input;
quit;
%mend;
%snapshot15(old.sum_opioid_exposure,den1.opioid_exposed_snapshot15);
%export(den1.opioid_exposed_snapshot15);

%macro snapshot16(input,output);
proc sql noprint;
create table &output as
select sum(n_29) as num_Chronic_IP_YR,sum(n) as total_observation,sum(n_29)/sum(n) as percent_IP_YR
from &input;
quit;
%mend;
%snapshot16(old.sum_opioid_exposure,den1.opioid_exposed_snapshot16);
%export(den1.opioid_exposed_snapshot16);

%macro snapshot17(input,output);
proc sql noprint;
create table &output as
select (select sum(n) from &input where n_7=1 and n_11=1) as num_bup,sum(n) as total_observation,
(select sum(n) from &input where n_7=1 and n_11=1)/sum(n) as percent_bup
from &input;
quit;
%mend;
%snapshot17(old.sum_opioid_exposure,den1.opioid_exposed_snapshot17);
%export(den1.opioid_exposed_snapshot17);

%macro snapshot18(input,output);
proc sql noprint;
create table &output as
select (select sum(n) from &input where n_62=1 and n_66=1) as num_naltrex,sum(n) as total_observation,
(select sum(n) from &input where n_62=1 and n_66=1)/sum(n) as percent_naltrex
from &input;
quit;
%mend;
%snapshot18(old.sum_opioid_exposure,den1.opioid_exposed_snapshot18);
%export(den1.opioid_exposed_snapshot18);

%macro snapshot19(input,output);
proc sql noprint;
create table &output as
select (select sum(n) from &input where n_47=1 and n_51=1) as num_methadone,sum(n) as total_observation,
(select sum(n) from &input where n_47=1 and n_51=1)/sum(n) as percent_methadone
from &input;
quit;
%mend;
%snapshot19(old.sum_opioid_exposure,den1.opioid_exposed_snapshot19);
%export(den1.opioid_exposed_snapshot19);

%macro snapshot20(input,output);
proc sql noprint;
create table &output as
select (select sum(n) from &input where n_16=1 and n_17=1 and n_18=1 and n_19=1 and n_20=1) as num_nlxrescue,sum(n) as total_observation,
(select sum(n) from &input where n_16=1 and n_17=1 and n_18=1 and n_19=1 and n_20=1)/sum(n) as percent_nlxrescue
from &input;
quit;
%mend;
%snapshot20(old.sum_opioid_exposure,den1.opioid_exposed_snapshot20);
%export(den1.opioid_exposed_snapshot20);

%macro snapshot21(input,output);
proc sql noprint;
create table &output as
select sum(n_61) as num_nlxambu,sum(n) as total_observation,sum(n_61)/sum(n) as percent_nlxambu
from &input;
quit;
%mend;
%snapshot21(old.sum_opioid_exposure,den1.opioid_exposed_snapshot21);
%export(den1.opioid_exposed_snapshot21);

%macro snapshot22(input,output);
proc sql noprint;
create table &output as
select sum(n_35) as num_fataloverdose,sum(n) as total_observation,sum(n_35)/sum(n) as percent_fataloverdose
from &input;
quit;
%mend;
%snapshot22(old.sum_opioid_exposure,den1.opioid_exposed_snapshot22);
%export(den1.opioid_exposed_snapshot22);

%macro snapshot23(input,output);
proc sql noprint;
create table &output as
select sum(n_69) as num_ODPRE,sum(n) as total_observation,sum(n_69)/sum(n) as percent_ODPRE
from &input;
quit;
%mend;
%snapshot23(old.sum_opioid_exposure,den1.opioid_exposed_snapshot23);
%export(den1.opioid_exposed_snapshot23);

%macro snapshot24(input,output);
proc sql noprint;
create table &output as
select sum(n_68) as num_ODPOST,sum(n) as total_observation,sum(n_68)/sum(n) as percent_ODPOST
from &input;
quit;
%mend;
%snapshot24(old.sum_opioid_exposure,den1.opioid_exposed_snapshot24);
%export(den1.opioid_exposed_snapshot24);

%macro snapshot25(input,output);
proc sql noprint;
create table &output as
select sum(n_32) as num_EDODPRE,sum(n) as total_observation,sum(n_32)/sum(n) as percent_EDODPRE
from &input;
quit;
%mend;
%snapshot25(old.sum_opioid_exposure,den1.opioid_exposed_snapshot25);
%export(den1.opioid_exposed_snapshot25);

%macro snapshot26(input,output);
proc sql noprint;
create table &output as
select sum(n_30) as num_EDODPOST,sum(n) as total_observation,sum(n_30)/sum(n) as percent_EDODPOST
from &input;
quit;
%mend;
%snapshot26(old.sum_opioid_exposure,den1.opioid_exposed_snapshot26);
%export(den1.opioid_exposed_snapshot26);

%macro snapshot27(input,output);
proc sql noprint;
create table &output as
select (select sum(n) from &input where n_81=1 and n_82=1) as num_methadone,sum(n) as total_observation,
(select sum(n) from &input where n_81=1 and n_82=1)/sum(n) as percent_methadone
from &input;
quit;
%mend;
%snapshot27(old.sum_opioid_exposure,den1.opioid_exposed_snapshot27);
%export(den1.opioid_exposed_snapshot27);

%macro snapshot28(input,output);
proc sql noprint;
create table &output as
select sum(n_80) as num_Smoking,sum(n) as total_observation,sum(n_80)/sum(n) as percent_Smoking
from &input;
quit;
%mend;
%snapshot28(old.sum_opioid_exposure,den1.opioid_exposed_snapshot28);
%export(den1.opioid_exposed_snapshot28);

%macro snapshot29(input,output);
proc sql noprint;
create table &output as
select sum(n_37) as num_HIV,sum(n) as total_observation,sum(n_37)/sum(n) as percent_HIV
from &input;
quit;
%mend;
%snapshot29(old.sum_opioid_exposure,den1.opioid_exposed_snapshot29);
%export(den1.opioid_exposed_snapshot29);

%macro snapshot30(input,output);
proc sql noprint;
create table &output as
select sum(n_41) as num_HBV,sum(n) as total_observation,sum(n_41)/sum(n) as percent_HBV
from &input;
quit;
%mend;
%snapshot30(old.sum_opioid_exposure,den1.opioid_exposed_snapshot30);
%export(den1.opioid_exposed_snapshot30);

%macro snapshot31(input,output);
proc sql noprint;
create table &output as
select sum(n_43) as num_HCV,sum(n) as total_observation,sum(n_43)/sum(n) as percent_HCV
from &input;
quit;
%mend;
%snapshot31(old.sum_opioid_exposure,den1.opioid_exposed_snapshot31);
%export(den1.opioid_exposed_snapshot31);

/*SNAPSHOT2- Chronic Opioid Use Population*/
%MACRO export(dataset);
PROC EXPORT DATA=&dataset
            OUTFILE= "&den3&dataset..csv" 
            DBMS=CSV REPLACE;
RUN;
%MEND export;
proc sql noprint;
create table den3.OUD_snapshot1 as
select sum(n_14) as num_chronic_opioid, sum(n) as total_observation, sum(n_14)/sum(n) as percent_chronic_opioid
from old.sum_binary;
quit;
%export (den2.chronic_opioid_snapshot1);

proc sql noprint;
create table den2.chronic_opioid_snapshot2 as
select facility_location,binary_race, binary_sex, binary_hispanic,eventyear,mean_age,
sum(n_14) as num_chronic_opioid, sum(n) as total_observation, sum(n_14)/sum(n) as percent_chronic_opioid
from old.sum_binary
group by facility_location,binary_race, binary_sex, binary_hispanic,eventyear;
quit;
%export (den2.chronic_opioid_snapshot2);

%snapshot3(old.sum_chronic_opioid,den2.chronic_opioid_snapshot3);
%snapshot4(old.sum_chronic_opioid,den2.chronic_opioid_snapshot4);
%snapshot5(old.sum_chronic_opioid,den2.chronic_opioid_snapshot5);
%snapshot6(old.sum_chronic_opioid,den2.chronic_opioid_snapshot6);
%snapshot7(old.sum_chronic_opioid,den2.chronic_opioid_snapshot7);
%snapshot8(old.sum_chronic_opioid,den2.chronic_opioid_snapshot8);
%snapshot9(old.sum_chronic_opioid,den2.chronic_opioid_snapshot9);
%snapshot10(old.sum_chronic_opioid,den2.chronic_opioid_snapshot10);
%snapshot11(old.sum_chronic_opioid,den2.chronic_opioid_snapshot11);
%snapshot12(old.sum_chronic_opioid,den2.chronic_opioid_snapshot12);
%snapshot13(old.sum_chronic_opioid,den2.chronic_opioid_snapshot13);
%snapshot14(old.sum_chronic_opioid,den2.chronic_opioid_snapshot14);
%snapshot15(old.sum_chronic_opioid,den2.chronic_opioid_snapshot15);
%snapshot16(old.sum_chronic_opioid,den2.chronic_opioid_snapshot16);
%snapshot17(old.sum_chronic_opioid,den2.chronic_opioid_snapshot17);
%snapshot18(old.sum_chronic_opioid,den2.chronic_opioid_snapshot18);
%snapshot19(old.sum_chronic_opioid,den2.chronic_opioid_snapshot19);
%snapshot20(old.sum_chronic_opioid,den2.chronic_opioid_snapshot20);
%snapshot21(old.sum_chronic_opioid,den2.chronic_opioid_snapshot21);
%snapshot22(old.sum_chronic_opioid,den2.chronic_opioid_snapshot22);
%snapshot23(old.sum_chronic_opioid,den2.chronic_opioid_snapshot23);
%snapshot24(old.sum_chronic_opioid,den2.chronic_opioid_snapshot24);
%snapshot25(old.sum_chronic_opioid,den2.chronic_opioid_snapshot25);
%snapshot26(old.sum_chronic_opioid,den2.chronic_opioid_snapshot26);
%snapshot27(old.sum_chronic_opioid,den2.chronic_opioid_snapshot27);
%snapshot28(old.sum_chronic_opioid,den2.chronic_opioid_snapshot28);
%snapshot29(old.sum_chronic_opioid,den2.chronic_opioid_snapshot29);
%snapshot30(old.sum_chronic_opioid,den2.chronic_opioid_snapshot30);
%snapshot31(old.sum_chronic_opioid,den2.chronic_opioid_snapshot31);
%export (den2.chronic_opioid_snapshot3);
%export (den2.chronic_opioid_snapshot4);
%export (den2.chronic_opioid_snapshot5);
%export (den2.chronic_opioid_snapshot6);
%export (den2.chronic_opioid_snapshot7);
%export (den2.chronic_opioid_snapshot8);
%export (den2.chronic_opioid_snapshot9);
%export (den2.chronic_opioid_snapshot10);
%export (den2.chronic_opioid_snapshot11);
%export (den2.chronic_opioid_snapshot12);
%export (den2.chronic_opioid_snapshot13);
%export (den2.chronic_opioid_snapshot14);
%export (den2.chronic_opioid_snapshot15);
%export (den2.chronic_opioid_snapshot16);
%export (den2.chronic_opioid_snapshot17);
%export (den2.chronic_opioid_snapshot18);
%export (den2.chronic_opioid_snapshot19);
%export (den2.chronic_opioid_snapshot20);
%export (den2.chronic_opioid_snapshot21);
%export (den2.chronic_opioid_snapshot22);
%export (den2.chronic_opioid_snapshot23);
%export (den2.chronic_opioid_snapshot24);
%export (den2.chronic_opioid_snapshot25);
%export (den2.chronic_opioid_snapshot26);
%export (den2.chronic_opioid_snapshot27);
%export (den2.chronic_opioid_snapshot28);
%export (den2.chronic_opioid_snapshot29);
%export (den2.chronic_opioid_snapshot30);
%export (den2.chronic_opioid_snapshot31);

/*SNAPSHOT3- Opioid Use Disorder Population*/
%MACRO export(dataset);
PROC EXPORT DATA=&dataset
            OUTFILE= "&den3&dataset..csv" 
            DBMS=CSV REPLACE;
RUN;
%MEND export;
proc sql noprint;
create table den3.oud_snapshot1 as
select sum(n_75) as num_oud, sum(n) as total_observation, sum(n_75)/sum(n) as percent_oud
from old.sum_binary;
quit;
%export (den3.oud_snapshot1);

proc sql noprint;
create table den3.oud_snapshot2 as
select facility_location,binary_race, binary_sex, binary_hispanic,eventyear,mean_age,
sum(n_75) as num_oud, sum(n) as total_observation, sum(n_75)/sum(n) as percent_oud
from old.sum_binary
group by facility_location,binary_race, binary_sex, binary_hispanic,eventyear;
quit;
%export (den3.oud_snapshot2);

%snapshot3(old.sum_oud,den3.oud_snapshot3);
%snapshot3(old.sum_oud,den3.oud_snapshot4);
%snapshot3(old.sum_oud,den3.oud_snapshot5);
%snapshot3(old.sum_oud,den3.oud_snapshot6);
%snapshot3(old.sum_oud,den3.oud_snapshot7);
%snapshot3(old.sum_oud,den3.oud_snapshot8);
%snapshot3(old.sum_oud,den3.oud_snapshot9);
%snapshot3(old.sum_oud,den3.oud_snapshot10);
%snapshot3(old.sum_oud,den3.oud_snapshot11);
%snapshot3(old.sum_oud,den3.oud_snapshot12);
%snapshot3(old.sum_oud,den3.oud_snapshot13);
%snapshot3(old.sum_oud,den3.oud_snapshot14);
%snapshot3(old.sum_oud,den3.oud_snapshot15);
%snapshot3(old.sum_oud,den3.oud_snapshot16);
%snapshot3(old.sum_oud,den3.oud_snapshot17);
%snapshot3(old.sum_oud,den3.oud_snapshot18);
%snapshot3(old.sum_oud,den3.oud_snapshot19);
%snapshot3(old.sum_oud,den3.oud_snapshot20);
%snapshot3(old.sum_oud,den3.oud_snapshot21);
%snapshot3(old.sum_oud,den3.oud_snapshot22);
%snapshot3(old.sum_oud,den3.oud_snapshot23);
%snapshot3(old.sum_oud,den3.oud_snapshot24);
%snapshot3(old.sum_oud,den3.oud_snapshot25);
%snapshot3(old.sum_oud,den3.oud_snapshot26);
%snapshot3(old.sum_oud,den3.oud_snapshot27);
%snapshot3(old.sum_oud,den3.oud_snapshot28);
%snapshot3(old.sum_oud,den3.oud_snapshot29);
%snapshot3(old.sum_oud,den3.oud_snapshot30);
%snapshot3(old.sum_oud,den3.oud_snapshot31);
%export (den3.oud_snapshot3);
%export (den3.oud_snapshot4);
%export (den3.oud_snapshot5);
%export (den3.oud_snapshot6);
%export (den3.oud_snapshot7);
%export (den3.oud_snapshot8);
%export (den3.oud_snapshot9);
%export (den3.oud_snapshot10);
%export (den3.oud_snapshot11);
%export (den3.oud_snapshot12);
%export (den3.oud_snapshot13);
%export (den3.oud_snapshot14);
%export (den3.oud_snapshot15);
%export (den3.oud_snapshot16);
%export (den3.oud_snapshot17);
%export (den3.oud_snapshot18);
%export (den3.oud_snapshot19);
%export (den3.oud_snapshot20);
%export (den3.oud_snapshot21);
%export (den3.oud_snapshot22);
%export (den3.oud_snapshot23);
%export (den3.oud_snapshot24);
%export (den3.oud_snapshot25);
%export (den3.oud_snapshot26);
%export (den3.oud_snapshot27);
%export (den3.oud_snapshot28);
%export (den3.oud_snapshot29);
%export (den3.oud_snapshot30);
%export (den3.oud_snapshot31);

/*SNAPSHOT4 - Overdose History*/
%MACRO export(dataset);
PROC EXPORT DATA=&dataset
            OUTFILE= "&den4&dataset..csv" 
            DBMS=CSV REPLACE;
RUN;
%MEND export;
proc sql noprint;
create table den4.odh_snapshot1 as
select sum(n_69) as num_odh, sum(n) as total_observation, sum(n_69)/sum(n) as percent_odh
from old.sum_binary;
quit;
%export (den4.odh_snapshot1);

proc sql noprint;
create table den4.odh_snapshot2 as
select facility_location,binary_race, binary_sex, binary_hispanic,eventyear,mean_age,
sum(n_69) as num_odh, sum(n) as total_observation, sum(n_69)/sum(n) as percent_odh
from old.sum_binary
group by facility_location,binary_race, binary_sex, binary_hispanic,eventyear;
quit;
%export (den4.odh_snapshot2);
%snapshot3(old.sum_overdose,den4.odh_snapshot3);
%snapshot3(old.sum_overdose,den4.odh_snapshot4);
%snapshot3(old.sum_overdose,den4.odh_snapshot5);
%snapshot3(old.sum_overdose,den4.odh_snapshot6);
%snapshot3(old.sum_overdose,den4.odh_snapshot7);
%snapshot3(old.sum_overdose,den4.odh_snapshot8);
%snapshot3(old.sum_overdose,den4.odh_snapshot9);
%snapshot3(old.sum_overdose,den4.odh_snapshot10);
%snapshot3(old.sum_overdose,den4.odh_snapshot11);
%snapshot3(old.sum_overdose,den4.odh_snapshot12);
%snapshot3(old.sum_overdose,den4.odh_snapshot13);
%snapshot3(old.sum_overdose,den4.odh_snapshot14);
%snapshot3(old.sum_overdose,den4.odh_snapshot15);
%snapshot3(old.sum_overdose,den4.odh_snapshot16);
%snapshot3(old.sum_overdose,den4.odh_snapshot17);
%snapshot3(old.sum_overdose,den4.odh_snapshot18);
%snapshot3(old.sum_overdose,den4.odh_snapshot19);
%snapshot3(old.sum_overdose,den4.odh_snapshot20);
%snapshot3(old.sum_overdose,den4.odh_snapshot21);
%snapshot3(old.sum_overdose,den4.odh_snapshot22);
%snapshot3(old.sum_overdose,den4.odh_snapshot23);
%snapshot3(old.sum_overdose,den4.odh_snapshot24);
%snapshot3(old.sum_overdose,den4.odh_snapshot25);
%snapshot3(old.sum_overdose,den4.odh_snapshot26);
%snapshot3(old.sum_overdose,den4.odh_snapshot27);
%snapshot3(old.sum_overdose,den4.odh_snapshot28);
%snapshot3(old.sum_overdose,den4.odh_snapshot29);
%snapshot3(old.sum_overdose,den4.odh_snapshot30);
%snapshot3(old.sum_overdose,den4.odh_snapshot31);
%export (den4.odh_snapshot3);
%export (den4.odh_snapshot4);
%export (den4.odh_snapshot5);
%export (den4.odh_snapshot6);
%export (den4.odh_snapshot7);
%export (den4.odh_snapshot8);
%export (den4.odh_snapshot9);
%export (den4.odh_snapshot10);
%export (den4.odh_snapshot11);
%export (den4.odh_snapshot12);
%export (den4.odh_snapshot13);
%export (den4.odh_snapshot14);
%export (den4.odh_snapshot15);
%export (den4.odh_snapshot16);
%export (den4.odh_snapshot17);
%export (den4.odh_snapshot18);
%export (den4.odh_snapshot19);
%export (den4.odh_snapshot20);
%export (den4.odh_snapshot21);
%export (den4.odh_snapshot22);
%export (den4.odh_snapshot23);
%export (den4.odh_snapshot24);
%export (den4.odh_snapshot25);
%export (den4.odh_snapshot26);
%export (den4.odh_snapshot27);
%export (den4.odh_snapshot28);
%export (den4.odh_snapshot29);
%export (den4.odh_snapshot30);
%export (den4.odh_snapshot31);
