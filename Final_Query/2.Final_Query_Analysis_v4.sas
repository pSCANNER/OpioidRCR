*2.Final_Query_Analysis, updated variable names;

LIBNAME old "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\Clean_Summary_Tables\AggregateSummaryTable-v2-no Ts";
LIBNAME new "C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\UpdatedAggregateData\Final_Query_v4\analysis_results";
%LET oldpath=C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\Clean_Summary_Tables\AggregateSummaryTable-v2-no Ts\;
%LET newpath=C:\Users\Qiaohong Hu\OneDrive - University of Southern California\Opioid RCR\UpdatedAggregateData\Final_Query_v4\analysis_results\;


%MACRO export(dataset);
PROC EXPORT DATA=new.&dataset
            OUTFILE= "&newpath&dataset..csv" 
            DBMS=CSV REPLACE;
RUN;
%MEND export;

/*Table indicating extend OUD population reflect co-morbid mental illness (primary list) recommendation to look at any year vs 1 year prior and 
what are the demographic characteristics of the dual diagnosis population (age, gender, race, ethnicity) */

PROC SQL noprint;
CREATE TABLE NEW.oud_mhpri_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, sum(n) as total_number,SUM(CT_MH_Dx_Pri_Any_Prior) as Number_of_comorbid_oud_mhpri, SUM(CT_MH_Dx_Pri_Any_Prior)/SUM(n) as Percent_of_comorbid_oud_mhpri
FROM old.sum_osudoud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_mhpri_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,sum(n) as total_number,SUM(CT_MH_Dx_Pri_Year_Prior) as Number_of_comorbid_oud_mhpri, SUM(CT_MH_Dx_Pri_Year_Prior)/SUM(n) as Percent_of_comorbid_oud_mhpri
FROM old.sum_osudoud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_mhpri_year_prior);
%export(oud_mhpri_any_prior);

/*Table indicating extend OUD population reflect co-morbid mental illness (exploratory list) recommendation to look at any year vs 1 year prior and 
what are the demographic characteristics of the dual diagnosis population (age, gender, race, ethnicity) */
PROC SQL noprint;
CREATE TABLE NEW.oud_mhexp_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, sum(n) as total_number,SUM(CT_MH_Dx_Exp_Any_Prior) as Number_of_comorbid_oud_mhexp, SUM(CT_MH_Dx_Exp_Any_Prior)/SUM(n) as Percent_of_comorbid_oud_mhexp
FROM old.sum_osudoud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_mhexp_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, sum(n) as total_number,SUM(CT_MH_Dx_Exp_Year_Prior) as Number_of_comorbid_oud_mhexp, SUM(CT_MH_Dx_Exp_Year_Prior)/SUM(n) as Percent_of_comorbid_oud_mhexp
FROM old.sum_osudoud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_mhexp_year_prior);
%export(oud_mhexp_any_prior);

/*Identify polysubstance abuse patterns in the OUD population (co-occurring alcohol use disorder, non-opioid/non-alcohol substance use disorder, cannabis use disorder, 
cocaine use disorder, other stimulant use disorder, inhalant use disorder, sedative/hypnotic/anxiolytic use disorder, hallucinogen use disorder) 
and what are the demographic (age, gender, race, ethnicity) and geographic characteristics) of the polysubstance abuse population?*/
PROC SQL noprint;
CREATE TABLE NEW.oud_aud_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,sum(n) as total_number, SUM(CT_Alcohol_Use_DO_Any_Prior) as  Number_of_cooccur_oud_aud, SUM(CT_Alcohol_Use_DO_Any_Prior)/SUM(n) as Percent_of_cooccur_oud_aud
FROM old.sum_osudoud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_aud_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, sum(n) as total_number,SUM(CT_Alcohol_Use_DO_Year_Prior) as Number_of_cooccur_oud_aud, SUM(CT_Alcohol_Use_DO_Year_Prior)/SUM(n) as Percent_of_cooccur_oud_aud
FROM old.sum_osudoud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_aud_year_prior);
%export(oud_aud_any_prior);

PROC SQL noprint;
CREATE TABLE NEW.oud_cannabis_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,sum(n) as total_number,SUM(CT_Cannabis_Use_DO_Any_Prior) as Number_of_cooccur_oud_cannabis, SUM(CT_Cannabis_Use_DO_Any_Prior)/SUM(n) as Percent_of_cooccur_oud_cannabis
FROM old.sum_osudoud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_cannabis_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,sum(n) as total_number, SUM(CT_Cannabis_Use_DO_Year_Prior) as Number_of_cooccur_oud_cannabis, SUM(CT_Cannabis_Use_DO_Year_Prior)/SUM(n) as Percent_of_cooccur_oud_cannabis
FROM old.sum_osudoud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_cannabis_year_prior);
%export(oud_cannabis_any_prior);

PROC SQL noprint;
CREATE TABLE NEW.oud_cocaine_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, sum(n) as total_number,SUM(CT_Cocaine_Use_DO_Any_Prior) as Number_of_cooccur_oud_cocaine, SUM(CT_Cocaine_Use_DO_Any_Prior)/SUM(n) as Percent_of_cooccur_oud_cocaine
FROM old.sum_osudoud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_cocaine_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,sum(n) as total_number,SUM(CT_Cocaine_Use_DO_Year_Prior) as Number_of_cooccur_oud_cocaine,SUM(CT_Cocaine_Use_DO_Year_Prior)/SUM(n) as Percent_of_cooccur_oud_cocaine
FROM old.sum_osudoud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_cocaine_year_prior);
%export(oud_cocaine_any_prior);

PROC SQL noprint;
CREATE TABLE NEW.oud_inhalent_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, sum(n) as total_number,SUM(CT_Inhalant_Use_DO_Any_Prior) as Number_of_cooccur_oud_inhalent, SUM(CT_Inhalant_Use_DO_Any_Prior)/SUM(n) as Percent_of_cooccur_oud_inhalent
FROM old.sum_osudoud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_inhalent_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,sum(n) as total_number,SUM(CT_Inhalant_Use_DO_Year_Prior) as Number_of_cooccur_oud_inhalent,SUM(CT_Inhalant_Use_DO_Year_Prior)/SUM(n) as Percent_of_cooccur_oud_inhalent
FROM old.sum_osudoud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_inhalent_year_prior);
%export(oud_inhalent_any_prior);

PROC SQL noprint;
CREATE TABLE NEW.oud_hallucinogen_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, sum(n) as total_number,SUM(CT_HallucinogenUseDOAnyPrior) as Number_of_cooccur_oud_hlcg, SUM(CT_HallucinogenUseDOAnyPrior)/SUM(n) as Percent_of_cooccur_oud_hlcg
FROM old.sum_osudoud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_hallucinogen_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,sum(n) as total_number,SUM(CT_HallucinogenUseDOYearPrior) as Number_of_cooccur_oud_hlcg, SUM(CT_HallucinogenUseDOYearPrior)/SUM(n) as Percent_of_cooccur_oud_hlcg 
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_hallucinogen_year_prior);
%export(oud_hallucinogen_any_prior);

/*Identify statistics on uptake of MAT in each subpopulation (focus on opioid exposed, chronic opioid use, OUD, and opioid overdose populations)? */
PROC SQL noprint;
CREATE TABLE NEW.mat_opioid_exposure AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,
SUM(n) as Total_Number,
SUM(CT_BUP_DISP_POST) as Number_of_bup_disp_post,
SUM(CT_BUP_DISP_POST)/SUM(n) as Percent_of_bup_disp_post,
SUM(CT_BUP_DISP_PRE) as Number_of_BUP_DISP_PRE, 
SUM(CT_BUP_DISP_PRE)/SUM(n) as Percent_of_BUP_DISP_PRE,
SUM(CT_BUP_PRESC_POST) as Number_of_BUP_PRESC_POST, 
SUM(CT_BUP_PRESC_POST)/SUM(n) as Percent_of_BUP_PRESC_POST,
SUM(CT_BUP_PRESC_PRE) as Number_of_BUP_PRESC_PRE, 
SUM(CT_BUP_PRESC_PRE)/SUM(n) as Percent_of_BUP_PRESC_PRE,
SUM(CT_METHADONE_DISP_POST) as Number_of_methadone_disp_post,
SUM(CT_METHADONE_DISP_POST)/SUM(n) as Percent_of_methadone_disp_post,
SUM(CT_METHADONE_DISP_PRE) as Number_of_methadone_DISP_PRE, 
SUM(CT_METHADONE_DISP_PRE)/SUM(n) as Percent_of_methadone_DISP_PRE,
SUM(CT_METHADONE_PRESC_POST) as Number_of_methadone_PRESC_POST, 
SUM(CT_METHADONE_PRESC_POST)/SUM(n) as Percent_of_methadone_PRESC_POST,
SUM(CT_METHADONE_PRESC_PRE) as Number_of_methadone_PRESC_PRE,
SUM(CT_METHADONE_PRESC_PRE)/SUM(n) as Percent_of_methadone_PRESC_PRE,
SUM(CT_NALTREX_DISP_POST) as Number_of_NALTREX_disp_post,
SUM(CT_NALTREX_DISP_POST)/SUM(n) as Percent_of_NALTREX_disp_post,
SUM(CT_NALTREX_DISP_PRE) as Number_of_NALTREX_DISP_PRE, 
SUM(CT_NALTREX_DISP_PRE)/SUM(n) as Percent_of_NALTREX_DISP_PRE,
SUM(CT_NALTREX_PRESC_POST) as Number_of_NALTREX_PRESC_POST, 
SUM(CT_NALTREX_PRESC_POST)/SUM(n) as Percent_of_NALTREX_PRESC_POST,
SUM(CT_NALTREX_PRESC_PRE) as Number_of_NALTREX_PRESC_PRE,
SUM(CT_NALTREX_PRESC_PRE)/SUM(n) as Percent_of_NALTREX_PRESC_PRE
FROM old.sum_opioid_exposure
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(mat_opioid_exposure);
PROC SQL noprint;
CREATE TABLE NEW.mat_chronic_opioid AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,
SUM(n) as Total_Number,
SUM(CT_BUP_DISP_POST) as Number_of_bup_disp_post,
SUM(CT_BUP_DISP_POST)/SUM(n) as Percent_of_bup_disp_post,
SUM(CT_BUP_DISP_PRE) as Number_of_BUP_DISP_PRE, 
SUM(CT_BUP_DISP_PRE)/SUM(n) as Percent_of_BUP_DISP_PRE,
SUM(CT_BUP_PRESC_POST) as Number_of_BUP_PRESC_POST, 
SUM(CT_BUP_PRESC_POST)/SUM(n) as Percent_of_BUP_PRESC_POST,
SUM(CT_BUP_PRESC_PRE) as Number_of_BUP_PRESC_PRE, 
SUM(CT_BUP_PRESC_PRE)/SUM(n) as Percent_of_BUP_PRESC_PRE,
SUM(CT_METHADONE_DISP_POST) as Number_of_methadone_disp_post,
SUM(CT_METHADONE_DISP_POST)/SUM(n) as Percent_of_methadone_disp_post,
SUM(CT_METHADONE_DISP_PRE) as Number_of_methadone_DISP_PRE, 
SUM(CT_METHADONE_DISP_PRE)/SUM(n) as Percent_of_methadone_DISP_PRE,
SUM(CT_METHADONE_PRESC_POST) as Number_of_methadone_PRESC_POST, 
SUM(CT_METHADONE_PRESC_POST)/SUM(n) as Percent_of_methadone_PRESC_POST,
SUM(CT_METHADONE_PRESC_PRE) as Number_of_methadone_PRESC_PRE,
SUM(CT_METHADONE_PRESC_PRE)/SUM(n) as Percent_of_methadone_PRESC_PRE,
SUM(CT_NALTREX_DISP_POST) as Number_of_NALTREX_disp_post,
SUM(CT_NALTREX_DISP_POST)/SUM(n) as Percent_of_NALTREX_disp_post,
SUM(CT_NALTREX_DISP_PRE) as Number_of_NALTREX_DISP_PRE, 
SUM(CT_NALTREX_DISP_PRE)/SUM(n) as Percent_of_NALTREX_DISP_PRE,
SUM(CT_NALTREX_PRESC_POST) as Number_of_NALTREX_PRESC_POST, 
SUM(CT_NALTREX_PRESC_POST)/SUM(n) as Percent_of_NALTREX_PRESC_POST,
SUM(CT_NALTREX_PRESC_PRE) as Number_of_NALTREX_PRESC_PRE,
SUM(CT_NALTREX_PRESC_PRE)/SUM(n) as Percent_of_NALTREX_PRESC_PRE
FROM old.sum_chronic_opioid
GROUP BY facility_location, race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(mat_chronic_opioid);
PROC SQL noprint;
CREATE TABLE NEW.mat_OUD AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,
SUM(n) as Total_Number,
SUM(CT_BUP_DISP_POST) as Number_of_bup_disp_post,
SUM(CT_BUP_DISP_POST)/SUM(n) as Percent_of_bup_disp_post,
SUM(CT_BUP_DISP_PRE) as Number_of_BUP_DISP_PRE, 
SUM(CT_BUP_DISP_PRE)/SUM(n) as Percent_of_BUP_DISP_PRE,
SUM(CT_BUP_PRESC_POST) as Number_of_BUP_PRESC_POST, 
SUM(CT_BUP_PRESC_POST)/SUM(n) as Percent_of_BUP_PRESC_POST,
SUM(CT_BUP_PRESC_PRE) as Number_of_BUP_PRESC_PRE, 
SUM(CT_BUP_PRESC_PRE)/SUM(n) as Percent_of_BUP_PRESC_PRE,
SUM(CT_METHADONE_DISP_POST) as Number_of_methadone_disp_post,
SUM(CT_METHADONE_DISP_POST)/SUM(n) as Percent_of_methadone_disp_post,
SUM(CT_METHADONE_DISP_PRE) as Number_of_methadone_DISP_PRE, 
SUM(CT_METHADONE_DISP_PRE)/SUM(n) as Percent_of_methadone_DISP_PRE,
SUM(CT_METHADONE_PRESC_POST) as Number_of_methadone_PRESC_POST, 
SUM(CT_METHADONE_PRESC_POST)/SUM(n) as Percent_of_methadone_PRESC_POST,
SUM(CT_METHADONE_PRESC_PRE) as Number_of_methadone_PRESC_PRE,
SUM(CT_METHADONE_PRESC_PRE)/SUM(n) as Percent_of_methadone_PRESC_PRE,
SUM(CT_NALTREX_DISP_POST) as Number_of_NALTREX_disp_post,
SUM(CT_NALTREX_DISP_POST)/SUM(n) as Percent_of_NALTREX_disp_post,
SUM(CT_NALTREX_DISP_PRE) as Number_of_NALTREX_DISP_PRE, 
SUM(CT_NALTREX_DISP_PRE)/SUM(n) as Percent_of_NALTREX_DISP_PRE,
SUM(CT_NALTREX_PRESC_POST) as Number_of_NALTREX_PRESC_POST, 
SUM(CT_NALTREX_PRESC_POST)/SUM(n) as Percent_of_NALTREX_PRESC_POST,
SUM(CT_NALTREX_PRESC_PRE) as Number_of_NALTREX_PRESC_PRE,
SUM(CT_NALTREX_PRESC_PRE)/SUM(n) as Percent_of_NALTREX_PRESC_PRE
FROM old.sum_OSUDOUD
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(mat_OUD);
PROC SQL noprint;
CREATE TABLE NEW.mat_overdose AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,
SUM(n) as Total_Number,
SUM(CT_BUP_DISP_POST) as Number_of_bup_disp_post,
SUM(CT_BUP_DISP_POST)/SUM(n) as Percent_of_bup_disp_post,
SUM(CT_BUP_DISP_PRE) as Number_of_BUP_DISP_PRE, 
SUM(CT_BUP_DISP_PRE)/SUM(n) as Percent_of_BUP_DISP_PRE,
SUM(CT_BUP_PRESC_POST) as Number_of_BUP_PRESC_POST, 
SUM(CT_BUP_PRESC_POST)/SUM(n) as Percent_of_BUP_PRESC_POST,
SUM(CT_BUP_PRESC_PRE) as Number_of_BUP_PRESC_PRE, 
SUM(CT_BUP_PRESC_PRE)/SUM(n) as Percent_of_BUP_PRESC_PRE,
SUM(CT_METHADONE_DISP_POST) as Number_of_methadone_disp_post,
SUM(CT_METHADONE_DISP_POST)/SUM(n) as Percent_of_methadone_disp_post,
SUM(CT_METHADONE_DISP_PRE) as Number_of_methadone_DISP_PRE, 
SUM(CT_METHADONE_DISP_PRE)/SUM(n) as Percent_of_methadone_DISP_PRE,
SUM(CT_METHADONE_PRESC_POST) as Number_of_methadone_PRESC_POST, 
SUM(CT_METHADONE_PRESC_POST)/SUM(n) as Percent_of_methadone_PRESC_POST,
SUM(CT_METHADONE_PRESC_PRE) as Number_of_methadone_PRESC_PRE,
SUM(CT_METHADONE_PRESC_PRE)/SUM(n) as Percent_of_methadone_PRESC_PRE,
SUM(CT_NALTREX_DISP_POST) as Number_of_NALTREX_disp_post,
SUM(CT_NALTREX_DISP_POST)/SUM(n) as Percent_of_NALTREX_disp_post,
SUM(CT_NALTREX_DISP_PRE) as Number_of_NALTREX_DISP_PRE, 
SUM(CT_NALTREX_DISP_PRE)/SUM(n) as Percent_of_NALTREX_DISP_PRE,
SUM(CT_NALTREX_PRESC_POST) as Number_of_NALTREX_PRESC_POST, 
SUM(CT_NALTREX_PRESC_POST)/SUM(n) as Percent_of_NALTREX_PRESC_POST,
SUM(CT_NALTREX_PRESC_PRE) as Number_of_NALTREX_PRESC_PRE,
SUM(CT_NALTREX_PRESC_PRE)/SUM(n) as Percent_of_NALTREX_PRESC_PRE
FROM old.sum_overdose
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(mat_overdose);

/*How often are clinicians co-prescribing naloxone with opioids?*/

PROC SQL noprint;
CREATE TABLE NEW.opioid_naloxone AS
SELECT eventyear,sum(n) as Total_Number,SUM(CT_NALOXONE_PRESCRIBE_RESCUE) as Number_of_copresc_opioid_nlx,SUM(CT_NALOXONE_PRESCRIBE_RESCUE)/SUM(n) as Percent_of_copresc_opioid_nlx
FROM old.sum_opioid_exposure
GROUP BY eventyear;
QUIT;
%export(opioid_naloxone);

/*Frequency of naloxone prescribing by year */
PROC SQL noprint;
CREATE TABLE NEW.naloxone_prescription AS
SELECT eventyear, sum(n) as Total_Number, SUM(CT_NALOXONE_PRESCRIBE_RESCUE) as Number_of_naloxone_presc,SUM(CT_NALOXONE_PRESCRIBE_RESCUE)/SUM(n) as Percent_of_naloxone_presc
FROM old.sum_binary
GROUP BY eventyear;
QUIT;
%export(naloxone_prescription);
