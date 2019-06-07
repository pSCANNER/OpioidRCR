/*OPIOID_FLAG*/
%MACRO export(dataset);
PROC EXPORT DATA=&dataset
            OUTFILE= "&den1&dataset..csv" 
            DBMS=CSV REPLACE;
RUN;
%MEND export;
proc sql noprint;
create table den1.opioid_exposed_snapshot1 as
select sum(CT_OPIOID_FLAG) as num_opiod_exposure, sum(n) as total_observation, sum(CT_OPIOID_FLAG)/sum(n) as percent_opioid_exposure
from old.sum_all_exc_cancer;
quit;
%export (den1.opioid_exposed_snapshot1);
/*OPIOID_FLAG*/
proc sql noprint;
create table den1.opioid_exposed_snapshot2 as
select facility_location,race, sex, hispanic,agegrp1,eventyear,
sum(CT_OPIOID_FLAG) as num_opiod_exposure, sum(n) as total_observation, sum(CT_OPIOID_FLAG)/sum(n) as percent_opioid_exposure
from old.sum_all_exc_cancer
group by facility_location,race, sex, hispanic,agegrp1,eventyear;
quit;
%export (den1.opioid_exposed_snapshot2);
%macro snapshot_oep(input,output);
proc sql noprint;
create table &output as
select sum(n) as total_observation,(select sum(n) from &input where CT_BDZ_Disp_3mo>0 and CT_BDZ_Presc_3mo>0) as num_bdz, 
(select sum(n) from &input where CT_BDZ_Disp_3mo>0 and CT_BDZ_Presc_3mo>0)/sum(n) as percent_bdz,
sum(CT_MH_Dx_Pri_Year_Prior) as num_mhpri,sum(CT_MH_Dx_Pri_Year_Prior)/sum(n) as percent_mhpri,
sum(CT_MH_Dx_Exp_Year_Prior) as num_mhexp ,sum(CT_MH_Dx_Exp_Year_Prior)/sum(n) as percent_mhexp,
sum(CT_Opioid_Use_DO_Year_Prior) as num_OUD ,sum(CT_Opioid_Use_DO_Year_Prior)/sum(n) as percent_OUD,
sum(CT_Substance_Use_DO_Year_Prior) as num_SUD ,sum(CT_Substance_Use_DO_Year_Prior)/sum(n) as percent_SUD,
sum(CT_Alcohol_Use_DO_Year_Prior) as num_AUD ,sum(CT_Alcohol_Use_DO_Year_Prior)/sum(n) as percent_AUD,
sum(CT_Cocaine_Use_DO_Year_Prior) as num_CocaineUD ,sum(CT_Cocaine_Use_DO_Year_Prior)/sum(n) as percent_CocaineUD,
sum(CT_HallucinogenUseDOYearPrior) as num_HallucinogenUD ,sum(CT_HallucinogenUseDOYearPrior)/sum(n) as percent_HallucinogenUD ,
sum(CT_Other_Stim_Use_DO_Year_Prior) as num_otherstimUD ,sum(CT_Other_Stim_Use_DO_Year_Prior)/sum(n) as percent_otherstimUD,
sum(CT_SedHypAnx_Use_DO_Year_Prior) as num_SedHypAnx ,sum(CT_SedHypAnx_Use_DO_Year_Prior)/sum(n) as percent_SedHypAnx,
sum(CT_Cannabis_Use_DO_Year_Prior) as num_CannabisUD ,sum(CT_Cannabis_Use_DO_Year_Prior)/sum(n) as percent_CannabisUD,
sum(CT_Inhalant_Use_DO_Year_Prior) as num_InhalantUD ,sum(CT_Inhalant_Use_DO_Year_Prior)/sum(n) as percent_InhalantUD,
sum(CT_CHRONIC_OPIOID_CURRENT_PRIOR) as num_Chronic_Opioid ,sum(CT_CHRONIC_OPIOID_current_prior)/sum(n) as percent_Chronic_Opioid,
sum(CT_ED_YR) as num_ED_YR ,sum(CT_ED_YR)/sum(n) as percent_ED_YR,
sum(CT_ED_IP_YR) as num_IP_YR ,sum(CT_ED_IP_YR)/sum(n) as percent_IP_YR,
(select sum(n) from &input where CT_BUP_DISP_POST>0 and CT_BUP_PRESC_POST>0) as num_bup ,
(select sum(n) from &input where CT_BUP_DISP_POST>0 and CT_BUP_PRESC_POST>0)/sum(n) as percent_bup,
(select sum(n) from &input where CT_NALTREX_DISP_POST>0 and CT_NALTREX_PRESC_POST>0) as num_naltrex ,
(select sum(n) from &input where CT_NALTREX_DISP_POST>0 and CT_NALTREX_PRESC_POST>0)/sum(n) as percent_naltrex,
(select sum(n) from &input where CT_METHADONE_DISP_POST>0 and CT_METHADONE_PRESC_POST>0) as num_methadone ,
(select sum(n) from &input where CT_METHADONE_DISP_POST>0 and CT_METHADONE_PRESC_POST>0)/sum(n) as percent_methadone,
(select sum(n) from &input where (CT_NALOXONE_INFERRED_RESCUE>0)  and (CT_NALOXONE_PRESCRIBE_RESCUE>0)and(CT_NALOXONE_DISPENSE_RESCUE>0) and  (CT_NALOXONE_ADMIN_RESCUE>0) ) as num_nlxrescue ,
(select sum(n) from &input where (CT_NALOXONE_INFERRED_RESCUE>0)  and (CT_NALOXONE_PRESCRIBE_RESCUE>0)and(CT_NALOXONE_DISPENSE_RESCUE>0) and  (CT_NALOXONE_ADMIN_RESCUE>0))/sum(n) as percent_nlxrescue,
sum(CT_NALOX_AMBULATORY) as num_nlxambu ,sum(CT_NALOX_AMBULATORY)/sum(n) as percent_nlxambu,
sum(CT_FATAL_OVERDOSE) as num_fataloverdose ,sum(CT_FATAL_OVERDOSE)/sum(n) as percent_fataloverdose,
sum(CT_OD_PRE) as num_ODPRE ,sum(CT_OD_PRE)/sum(n) as percent_ODPRE,
sum(CT_OD_POST) as num_ODPOST ,sum(CT_OD_POST)/sum(n) as percent_ODPOST,
sum(CT_ED_OD_PRE) as num_EDODPRE ,sum(CT_ED_OD_PRE)/sum(n) as percent_EDODPRE,
sum(CT_ED_OD_POST) as num_EDODPOST ,sum(CT_ED_OD_POST)/sum(n) as percent_EDODPOST,
(select sum(n) from &input where CT_SUICIDE_POST>0 and CT_SUICIDE_PRE>0) as num_suicide ,
(select sum(n) from &input where CT_SUICIDE_POST>0 and CT_SUICIDE_PRE>0)/sum(n) as percent_suicide,
sum(CT_SMOKING) as num_Smoking ,sum(CT_SMOKING)/sum(n) as percent_Smoking,
sum(CT_HIV_Dx_Year_Prior) as num_HIV ,sum(CT_HIV_Dx_Year_Prior)/sum(n) as percent_HIV,
sum(CT_HepB_Dx_Year_Prior) as num_HBV ,sum(CT_HepB_Dx_Year_Prior)/sum(n) as percent_HBV,
sum(CT_HepC_Dx_Year_Prior) as num_HCV ,sum(CT_HepC_Dx_Year_Prior)/sum(n) as percent_HCV
from &input;
quit;
%mend;
%snapshot_oep(old.sum_opioid_exposure,den1.opioid_exposure_snapshot);
%export(den1.opioid_exposure_snapshot);

/*CHRONIC OPIOID*/
%MACRO export(dataset);
PROC EXPORT DATA=&dataset
            OUTFILE= "&den2&dataset..csv" 
            DBMS=CSV REPLACE;
RUN;
%MEND export;
proc sql noprint; /*CHRONIC_OPIOID*/
create table den2.chronic_opioid_snapshot1 as
select sum(CT_chronic_opioid_current_prior) as num_chronic_opioid, sum(n) as total_observation, sum(CT_chronic_opioid_current_prior)/sum(n) as percent_chronic_opioid
from old.sum_all_exc_cancer;
quit;
%export (den2.chronic_opioid_snapshot1);
proc sql noprint;/*CHRONIC_OPIOID*/
create table den2.chronic_opioid_snapshot2 as
select facility_location,race, sex, hispanic,AGEGRP1,eventyear,
sum(CT_chronic_opioid_current_prior) as num_chronic_opioid, sum(n) as total_observation, sum(CT_chronic_opioid_current_prior)/sum(n) as percent_chronic_opioid
from old.sum_all_exc_cancer
group by facility_location,race, sex, hispanic,AGEGRP1,eventyear;
quit;
%export (den2.chronic_opioid_snapshot2);
%macro snapshot_co(input,output);
proc sql noprint;
create table &output as
select sum(n) as total_observation,(select sum(n) from &input where CT_BDZ_Disp_3mo>0 and CT_BDZ_Presc_3mo>0) as num_bdz, 
(select sum(n) from &input where CT_BDZ_Disp_3mo>0 and CT_BDZ_Presc_3mo>0)/sum(n) as percent_bdz,
sum(CT_MH_Dx_Pri_Year_Prior) as num_mhpri,sum(CT_MH_Dx_Pri_Year_Prior)/sum(n) as percent_mhpri,
sum(CT_MH_Dx_Exp_Year_Prior) as num_mhexp ,sum(CT_MH_Dx_Exp_Year_Prior)/sum(n) as percent_mhexp,
sum(CT_Opioid_Use_DO_Year_Prior) as num_OUD ,sum(CT_Opioid_Use_DO_Year_Prior)/sum(n) as percent_OUD,
sum(CT_Substance_Use_DO_Year_Prior) as num_SUD ,sum(CT_Substance_Use_DO_Year_Prior)/sum(n) as percent_SUD,
sum(CT_Alcohol_Use_DO_Year_Prior) as num_AUD ,sum(CT_Alcohol_Use_DO_Year_Prior)/sum(n) as percent_AUD,
sum(CT_Cocaine_Use_DO_Year_Prior) as num_CocaineUD ,sum(CT_Cocaine_Use_DO_Year_Prior)/sum(n) as percent_CocaineUD,
sum(CT_HallucinogenUseDOYearPrior) as num_HallucinogenUD ,sum(CT_HallucinogenUseDOYearPrior)/sum(n) as percent_HallucinogenUD ,
sum(CT_Other_Stim_Use_DO_Year_Prior) as num_otherstimUD ,sum(CT_Other_Stim_Use_DO_Year_Prior)/sum(n) as percent_otherstimUD,
sum(CT_SedHypAnx_Use_DO_Year_Prior) as num_SedHypAnx ,sum(CT_SedHypAnx_Use_DO_Year_Prior)/sum(n) as percent_SedHypAnx,
sum(CT_Cannabis_Use_DO_Year_Prior) as num_CannabisUD ,sum(CT_Cannabis_Use_DO_Year_Prior)/sum(n) as percent_CannabisUD,
sum(CT_Inhalant_Use_DO_Year_Prior) as num_InhalantUD ,sum(CT_Inhalant_Use_DO_Year_Prior)/sum(n) as percent_InhalantUD,
sum(CT_OPIOID_FLAG) as num_opioid_exposure,sum(CT_OPIOID_FLAG)/sum(n) as percent_opioid_exposure,
sum(CT_ED_YR) as num_ED_YR ,sum(CT_ED_YR)/sum(n) as percent_ED_YR,
sum(CT_ED_IP_YR) as num_IP_YR ,sum(CT_ED_IP_YR)/sum(n) as percent_IP_YR,
(select sum(n) from &input where CT_BUP_DISP_POST>0 and CT_BUP_PRESC_POST>0) as num_bup ,
(select sum(n) from &input where CT_BUP_DISP_POST>0 and CT_BUP_PRESC_POST>0)/sum(n) as percent_bup,
(select sum(n) from &input where CT_NALTREX_DISP_POST>0 and CT_NALTREX_PRESC_POST>0) as num_naltrex ,
(select sum(n) from &input where CT_NALTREX_DISP_POST>0 and CT_NALTREX_PRESC_POST>0)/sum(n) as percent_naltrex,
(select sum(n) from &input where CT_METHADONE_DISP_POST>0 and CT_METHADONE_PRESC_POST>0) as num_methadone ,
(select sum(n) from &input where CT_METHADONE_DISP_POST>0 and CT_METHADONE_PRESC_POST>0)/sum(n) as percent_methadone,
(select sum(n) from &input where (CT_NALOXONE_INFERRED_RESCUE>0)  and (CT_NALOXONE_PRESCRIBE_RESCUE>0)and(CT_NALOXONE_DISPENSE_RESCUE>0) and  (CT_NALOXONE_ADMIN_RESCUE>0) ) as num_nlxrescue ,
(select sum(n) from &input where (CT_NALOXONE_INFERRED_RESCUE>0)  and (CT_NALOXONE_PRESCRIBE_RESCUE>0)and(CT_NALOXONE_DISPENSE_RESCUE>0) and  (CT_NALOXONE_ADMIN_RESCUE>0))/sum(n) as percent_nlxrescue,
sum(CT_NALOX_AMBULATORY) as num_nlxambu ,sum(CT_NALOX_AMBULATORY)/sum(n) as percent_nlxambu,
sum(CT_FATAL_OVERDOSE) as num_fataloverdose ,sum(CT_FATAL_OVERDOSE)/sum(n) as percent_fataloverdose,
sum(CT_OD_PRE) as num_ODPRE ,sum(CT_OD_PRE)/sum(n) as percent_ODPRE,
sum(CT_OD_POST) as num_ODPOST ,sum(CT_OD_POST)/sum(n) as percent_ODPOST,
sum(CT_ED_OD_PRE) as num_EDODPRE ,sum(CT_ED_OD_PRE)/sum(n) as percent_EDODPRE,
sum(CT_ED_OD_POST) as num_EDODPOST ,sum(CT_ED_OD_POST)/sum(n) as percent_EDODPOST,
(select sum(n) from &input where CT_SUICIDE_POST>0 and CT_SUICIDE_PRE>0) as num_suicide ,
(select sum(n) from &input where CT_SUICIDE_POST>0 and CT_SUICIDE_PRE>0)/sum(n) as percent_suicide,
sum(CT_SMOKING) as num_Smoking ,sum(CT_SMOKING)/sum(n) as percent_Smoking,
sum(CT_HIV_Dx_Year_Prior) as num_HIV ,sum(CT_HIV_Dx_Year_Prior)/sum(n) as percent_HIV,
sum(CT_HepB_Dx_Year_Prior) as num_HBV ,sum(CT_HepB_Dx_Year_Prior)/sum(n) as percent_HBV,
sum(CT_HepC_Dx_Year_Prior) as num_HCV ,sum(CT_HepC_Dx_Year_Prior)/sum(n) as percent_HCV
from &input;
quit;
%mend;
%snapshot_co(old.sum_chronic_opioid,den2.chronic_opioid_snapshot);
%export(den2.chronic_opioid_snapshot);

/*SNAPSHOT3- Opioid Use Disorder Population*/
%MACRO export(dataset);
PROC EXPORT DATA=&dataset
            OUTFILE= "&den3&dataset..csv" 
            DBMS=CSV REPLACE;
RUN;
%MEND export;
proc sql noprint;/*Opioid_Use_DO_Any_Prior*/
create table den3.oud_snapshot1 as
select sum(CT_Opioid_Use_DO_Any_Prior) as num_oud, sum(n) as total_observation, sum(CT_Opioid_Use_DO_Any_Prior)/sum(n) as percent_oud
from old.sum_all_exc_cancer;
quit;
%export (den3.oud_snapshot1);

proc sql noprint;/*Opioid_Use_DO_Any_Prior*/
create table den3.oud_snapshot2 as
select facility_location,race, sex, hispanic,AGEGRP1,eventyear,
sum(CT_Opioid_Use_DO_Any_Prior) as num_oud, sum(n) as total_observation, sum(CT_Opioid_Use_DO_Any_Prior)/sum(n) as percent_oud
from old.sum_all_exc_cancer
group by facility_location,race, sex, hispanic,AGEGRP1,eventyear;
quit;
%export (den3.oud_snapshot2);

%macro snapshot_oud(input,output);
proc sql noprint;
create table &output as
select sum(n) as total_observation,(select sum(n) from &input where CT_BDZ_Disp_3mo>0 and CT_BDZ_Presc_3mo>0) as num_bdz, 
(select sum(n) from &input where CT_BDZ_Disp_3mo>0 and CT_BDZ_Presc_3mo>0)/sum(n) as percent_bdz,
sum(CT_MH_Dx_Pri_Year_Prior) as num_mhpri,sum(CT_MH_Dx_Pri_Year_Prior)/sum(n) as percent_mhpri,
sum(CT_MH_Dx_Exp_Year_Prior) as num_mhexp ,sum(CT_MH_Dx_Exp_Year_Prior)/sum(n) as percent_mhexp,
sum(CT_Substance_Use_DO_Year_Prior) as num_SUD ,sum(CT_Substance_Use_DO_Year_Prior)/sum(n) as percent_SUD,
sum(CT_Alcohol_Use_DO_Year_Prior) as num_AUD ,sum(CT_Alcohol_Use_DO_Year_Prior)/sum(n) as percent_AUD,
sum(CT_Cocaine_Use_DO_Year_Prior) as num_CocaineUD ,sum(CT_Cocaine_Use_DO_Year_Prior)/sum(n) as percent_CocaineUD,
sum(CT_HallucinogenUseDOYearPrior) as num_HallucinogenUD ,sum(CT_HallucinogenUseDOYearPrior)/sum(n) as percent_HallucinogenUD ,
sum(CT_Other_Stim_Use_DO_Year_Prior) as num_otherstimUD ,sum(CT_Other_Stim_Use_DO_Year_Prior)/sum(n) as percent_otherstimUD,
sum(CT_SedHypAnx_Use_DO_Year_Prior) as num_SedHypAnx ,sum(CT_SedHypAnx_Use_DO_Year_Prior)/sum(n) as percent_SedHypAnx,
sum(CT_Cannabis_Use_DO_Year_Prior) as num_CannabisUD ,sum(CT_Cannabis_Use_DO_Year_Prior)/sum(n) as percent_CannabisUD,
sum(CT_Inhalant_Use_DO_Year_Prior) as num_InhalantUD ,sum(CT_Inhalant_Use_DO_Year_Prior)/sum(n) as percent_InhalantUD,
sum(CT_OPIOID_FLAG) as num_opioid_exposure,sum(CT_OPIOID_FLAG)/sum(n) as percent_opioid_exposure,
sum(CT_CHRONIC_OPIOID_CURRENT_PRIOR) as num_Chronic_Opioid ,sum(CT_CHRONIC_OPIOID_current_prior)/sum(n) as percent_Chronic_Opioid,
sum(CT_ED_YR) as num_ED_YR ,sum(CT_ED_YR)/sum(n) as percent_ED_YR,
sum(CT_ED_IP_YR) as num_IP_YR ,sum(CT_ED_IP_YR)/sum(n) as percent_IP_YR,
(select sum(n) from &input where CT_BUP_DISP_POST>0 and CT_BUP_PRESC_POST>0) as num_bup ,
(select sum(n) from &input where CT_BUP_DISP_POST>0 and CT_BUP_PRESC_POST>0)/sum(n) as percent_bup,
(select sum(n) from &input where CT_NALTREX_DISP_POST>0 and CT_NALTREX_PRESC_POST>0) as num_naltrex ,
(select sum(n) from &input where CT_NALTREX_DISP_POST>0 and CT_NALTREX_PRESC_POST>0)/sum(n) as percent_naltrex,
(select sum(n) from &input where CT_METHADONE_DISP_POST>0 and CT_METHADONE_PRESC_POST>0) as num_methadone ,
(select sum(n) from &input where CT_METHADONE_DISP_POST>0 and CT_METHADONE_PRESC_POST>0)/sum(n) as percent_methadone,
(select sum(n) from &input where (CT_NALOXONE_INFERRED_RESCUE>0)  and (CT_NALOXONE_PRESCRIBE_RESCUE>0)and(CT_NALOXONE_DISPENSE_RESCUE>0) and  (CT_NALOXONE_ADMIN_RESCUE>0) ) as num_nlxrescue ,
(select sum(n) from &input where (CT_NALOXONE_INFERRED_RESCUE>0)  and (CT_NALOXONE_PRESCRIBE_RESCUE>0)and(CT_NALOXONE_DISPENSE_RESCUE>0) and  (CT_NALOXONE_ADMIN_RESCUE>0))/sum(n) as percent_nlxrescue,
sum(CT_NALOX_AMBULATORY) as num_nlxambu ,sum(CT_NALOX_AMBULATORY)/sum(n) as percent_nlxambu,
sum(CT_FATAL_OVERDOSE) as num_fataloverdose ,sum(CT_FATAL_OVERDOSE)/sum(n) as percent_fataloverdose,
sum(CT_OD_PRE) as num_ODPRE ,sum(CT_OD_PRE)/sum(n) as percent_ODPRE,
sum(CT_OD_POST) as num_ODPOST ,sum(CT_OD_POST)/sum(n) as percent_ODPOST,
sum(CT_ED_OD_PRE) as num_EDODPRE ,sum(CT_ED_OD_PRE)/sum(n) as percent_EDODPRE,
sum(CT_ED_OD_POST) as num_EDODPOST ,sum(CT_ED_OD_POST)/sum(n) as percent_EDODPOST,
(select sum(n) from &input where CT_SUICIDE_POST>0 and CT_SUICIDE_PRE>0) as num_suicide ,
(select sum(n) from &input where CT_SUICIDE_POST>0 and CT_SUICIDE_PRE>0)/sum(n) as percent_suicide,
sum(CT_SMOKING) as num_Smoking ,sum(CT_SMOKING)/sum(n) as percent_Smoking,
sum(CT_HIV_Dx_Year_Prior) as num_HIV ,sum(CT_HIV_Dx_Year_Prior)/sum(n) as percent_HIV,
sum(CT_HepB_Dx_Year_Prior) as num_HBV ,sum(CT_HepB_Dx_Year_Prior)/sum(n) as percent_HBV,
sum(CT_HepC_Dx_Year_Prior) as num_HCV ,sum(CT_HepC_Dx_Year_Prior)/sum(n) as percent_HCV
from &input;
quit;
%mend;
%snapshot_oud(old.sum_osudoud,den3.oud_snapshot);
%export(den3.oud_snapshot);

/*SNAPSHOT4 - Overdose History*/
%MACRO export(dataset);
PROC EXPORT DATA=&dataset
            OUTFILE= "&den4&dataset..csv" 
            DBMS=CSV REPLACE;
RUN;
%MEND export;
proc sql noprint;/*OD_PRE*/
create table den4.odh_snapshot1 as
select sum(CT_OD_PRE) as num_odh, sum(n) as total_observation, sum(CT_OD_PRE)/sum(n) as percent_odh
from old.sum_all_exc_cancer;
quit;
%export (den4.odh_snapshot1);

proc sql noprint;/*OD_PRE*/
create table den4.odh_snapshot2 as
select facility_location,race, sex, hispanic,AGEGRP1,eventyear,
sum(CT_OD_PRE) as num_odh, sum(n) as total_observation, sum(CT_OD_PRE)/sum(n) as percent_odh
from old.sum_all_exc_cancer
group by facility_location,race, sex, hispanic,AGEGRP1,eventyear;
quit;
%export (den4.odh_snapshot2);

%macro snapshot_odh(input,output);
proc sql noprint;
create table &output as
select sum(n) as total_observation,(select sum(n) from &input where CT_BDZ_Disp_3mo>0 and CT_BDZ_Presc_3mo>0) as num_bdz, 
(select sum(n) from &input where CT_BDZ_Disp_3mo>0 and CT_BDZ_Presc_3mo>0)/sum(n) as percent_bdz,
sum(CT_MH_Dx_Pri_Year_Prior) as num_mhpri,sum(CT_MH_Dx_Pri_Year_Prior)/sum(n) as percent_mhpri,
sum(CT_MH_Dx_Exp_Year_Prior) as num_mhexp ,sum(CT_MH_Dx_Exp_Year_Prior)/sum(n) as percent_mhexp,
sum(CT_Substance_Use_DO_Year_Prior) as num_SUD ,sum(CT_Substance_Use_DO_Year_Prior)/sum(n) as percent_SUD,
sum(CT_Alcohol_Use_DO_Year_Prior) as num_AUD ,sum(CT_Alcohol_Use_DO_Year_Prior)/sum(n) as percent_AUD,
sum(CT_Cocaine_Use_DO_Year_Prior) as num_CocaineUD ,sum(CT_Cocaine_Use_DO_Year_Prior)/sum(n) as percent_CocaineUD,
sum(CT_HallucinogenUseDOYearPrior) as num_HallucinogenUD ,sum(CT_HallucinogenUseDOYearPrior)/sum(n) as percent_HallucinogenUD ,
sum(CT_Other_Stim_Use_DO_Year_Prior) as num_otherstimUD ,sum(CT_Other_Stim_Use_DO_Year_Prior)/sum(n) as percent_otherstimUD,
sum(CT_SedHypAnx_Use_DO_Year_Prior) as num_SedHypAnx ,sum(CT_SedHypAnx_Use_DO_Year_Prior)/sum(n) as percent_SedHypAnx,
sum(CT_Cannabis_Use_DO_Year_Prior) as num_CannabisUD ,sum(CT_Cannabis_Use_DO_Year_Prior)/sum(n) as percent_CannabisUD,
sum(CT_Inhalant_Use_DO_Year_Prior) as num_InhalantUD ,sum(CT_Inhalant_Use_DO_Year_Prior)/sum(n) as percent_InhalantUD,
sum(CT_OPIOID_FLAG) as num_opioid_exposure,sum(CT_OPIOID_FLAG)/sum(n) as percent_opioid_exposure,
sum(CT_CHRONIC_OPIOID_CURRENT_PRIOR) as num_Chronic_Opioid ,sum(CT_CHRONIC_OPIOID_current_prior)/sum(n) as percent_Chronic_Opioid,
sum(CT_ED_YR) as num_ED_YR ,sum(CT_ED_YR)/sum(n) as percent_ED_YR,
sum(CT_ED_IP_YR) as num_IP_YR ,sum(CT_ED_IP_YR)/sum(n) as percent_IP_YR,
(select sum(n) from &input where CT_BUP_DISP_POST>0 and CT_BUP_PRESC_POST>0) as num_bup ,
(select sum(n) from &input where CT_BUP_DISP_POST>0 and CT_BUP_PRESC_POST>0)/sum(n) as percent_bup,
(select sum(n) from &input where CT_NALTREX_DISP_POST>0 and CT_NALTREX_PRESC_POST>0) as num_naltrex ,
(select sum(n) from &input where CT_NALTREX_DISP_POST>0 and CT_NALTREX_PRESC_POST>0)/sum(n) as percent_naltrex,
(select sum(n) from &input where CT_METHADONE_DISP_POST>0 and CT_METHADONE_PRESC_POST>0) as num_methadone ,
(select sum(n) from &input where CT_METHADONE_DISP_POST>0 and CT_METHADONE_PRESC_POST>0)/sum(n) as percent_methadone,
(select sum(n) from &input where (CT_NALOXONE_INFERRED_RESCUE>0)  and (CT_NALOXONE_PRESCRIBE_RESCUE>0)and(CT_NALOXONE_DISPENSE_RESCUE>0) and  (CT_NALOXONE_ADMIN_RESCUE>0) ) as num_nlxrescue ,
(select sum(n) from &input where (CT_NALOXONE_INFERRED_RESCUE>0)  and (CT_NALOXONE_PRESCRIBE_RESCUE>0)and(CT_NALOXONE_DISPENSE_RESCUE>0) and  (CT_NALOXONE_ADMIN_RESCUE>0))/sum(n) as percent_nlxrescue,
sum(CT_NALOX_AMBULATORY) as num_nlxambu ,sum(CT_NALOX_AMBULATORY)/sum(n) as percent_nlxambu,
sum(CT_FATAL_OVERDOSE) as num_fataloverdose ,sum(CT_FATAL_OVERDOSE)/sum(n) as percent_fataloverdose,
sum(CT_Opioid_Use_DO_Year_Prior) as num_OUD ,sum(CT_Opioid_Use_DO_Year_Prior)/sum(n) as percent_OUD,
sum(CT_OD_POST) as num_ODPOST ,sum(CT_OD_POST)/sum(n) as percent_ODPOST,
sum(CT_ED_OD_PRE) as num_EDODPRE ,sum(CT_ED_OD_PRE)/sum(n) as percent_EDODPRE,
sum(CT_ED_OD_POST) as num_EDODPOST ,sum(CT_ED_OD_POST)/sum(n) as percent_EDODPOST,
(select sum(n) from &input where CT_SUICIDE_POST>0 and CT_SUICIDE_PRE>0) as num_suicide ,
(select sum(n) from &input where CT_SUICIDE_POST>0 and CT_SUICIDE_PRE>0)/sum(n) as percent_suicide,
sum(CT_SMOKING) as num_Smoking ,sum(CT_SMOKING)/sum(n) as percent_Smoking,
sum(CT_HIV_Dx_Year_Prior) as num_HIV ,sum(CT_HIV_Dx_Year_Prior)/sum(n) as percent_HIV,
sum(CT_HepB_Dx_Year_Prior) as num_HBV ,sum(CT_HepB_Dx_Year_Prior)/sum(n) as percent_HBV,
sum(CT_HepC_Dx_Year_Prior) as num_HCV ,sum(CT_HepC_Dx_Year_Prior)/sum(n) as percent_HCV
from &input;
quit;
%mend;
%snapshot_odh(old.sum_overdose,den4.odh_snapshot);
%export(den4.odh_snapshot);
