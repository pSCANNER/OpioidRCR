*2.Final_Query_Analysis, piggyback off of Qiaohong's code with some minor tweaks;

LIBNAME old "C:\Users\caronpar\OneDrive - University of Southern California\OPIOID\Clean_Summary_Tables\AggregateSummaryTables";
LIBNAME new "C:\Users\caronpar\OneDrive - University of Southern California\OPIOID\UpdatedAggregateData";
%LET oldpath=C:\Users\caronpar\OneDrive - University of Southern California\OPIOID\Clean_Summary_Tables\AggregateSummaryTables\;
%LET newpath=C:\Users\caronpar\OneDrive - University of Southern California\OPIOID\UpdatedAggregateData\;


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
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, SUM(n_43) as Number_of_comorbid_oud_mhpri, SUM(n_43)/SUM(n) as Percent_of_comorbid_oud_mhpri
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_mhpri_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,SUM(n_44) as Number_of_comorbid_oud_mhpri, SUM(n_44)/SUM(n) as Percent_of_comorbid_oud_mhpri
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_mhpri_year_prior);
%export(oud_mhpri_any_prior);

/*Table indicating extend OUD population reflect co-morbid mental illness (exploratory list) recommendation to look at any year vs 1 year prior and 
what are the demographic characteristics of the dual diagnosis population (age, gender, race, ethnicity) */
PROC SQL noprint;
CREATE TABLE NEW.oud_mhexp_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, SUM(n_41) as Number_of_comorbid_oud_mhexp, SUM(n_41)/SUM(n) as Percent_of_comorbid_oud_mhexp
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_mhexp_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, SUM(n_42) as Number_of_comorbid_oud_mhexp, SUM(n_42)/SUM(n) as Percent_of_comorbid_oud_mhexp
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_mhexp_year_prior);
%export(oud_mhexp_any_prior);

/*Identify polysubstance abuse patterns in the OUD population (co-occurring alcohol use disorder, non-opioid/non-alcohol substance use disorder, cannabis use disorder, 
cocaine use disorder, other stimulant use disorder, inhalant use disorder, sedative/hypnotic/anxiolytic use disorder, hallucinogen use disorder) 
and what are the demographic (age, gender, race, ethnicity) and geographic characteristics) of the polysubstance abuse population?*/
PROC SQL noprint;
CREATE TABLE NEW.oud_aud_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, SUM(n_2) as  Number_of_cooccur_oud_aud, SUM(n_2)/SUM(n) as Percent_of_cooccur_oud_aud
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_aud_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, SUM(n_3) as Number_of_cooccur_oud_aud, SUM(n_3)/SUM(n) as Percent_of_cooccur_oud_aud
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_aud_year_prior);
%export(oud_aud_any_prior);

PROC SQL noprint;
CREATE TABLE NEW.oud_cannabis_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,SUM(n_16) as Number_of_cooccur_oud_cannabis, SUM(n_16)/SUM(n) as Percent_of_cooccur_oud_cannabis
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_cannabis_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, SUM(n_17) as Number_of_cooccur_oud_cannabis, SUM(N_17)/SUM(n) as Percent_of_cooccur_oud_cannabis
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_cannabis_year_prior);
%export(oud_cannabis_any_prior);

PROC SQL noprint;
CREATE TABLE NEW.oud_cocaine_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, SUM(n_19) as Number_of_cooccur_oud_cocaine, SUM(n_19)/SUM(n) as Percent_of_cooccur_oud_cocaine
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_cocaine_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,SUM(n_20) as Number_of_cooccur_oud_cocaine,SUM(n_20)/SUM(n) as Percent_of_cooccur_oud_cocaine
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_cocaine_year_prior);
%export(oud_cocaine_any_prior);

PROC SQL noprint;
CREATE TABLE NEW.oud_inhalent_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, SUM(n_35) as Number_of_cooccur_oud_inhalent, SUM(n_35)/SUM(n) as Percent_of_cooccur_oud_inhalent
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_inhalent_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,SUM(n_36) as Number_of_cooccur_oud_inhalent,SUM(n_36)/SUM(n) as Percent_of_cooccur_oud_inhalent
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_inhalent_year_prior);
%export(oud_inhalent_any_prior);

PROC SQL noprint;
CREATE TABLE NEW.oud_hallucinogen_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, SUM(n_28) as Number_of_cooccur_oud_hlcg, SUM(n_28)/SUM(n) as Percent_of_cooccur_oud_hlcg
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_hallucinogen_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,SUM(n_29) as Number_of_cooccur_oud_hlcg, SUM(n_29)/SUM(n) as Percent_of_cooccur_oud_hlcg 
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_hallucinogen_year_prior);
%export(oud_hallucinogen_any_prior);

/*Identify statistics on uptake of MAT in each subpopulation (focus on opioid exposed, chronic opioid use, OUD, and opioid overdose populations)? */
PROC SQL noprint;
CREATE TABLE NEW.mat_opioid_exposure AS
SELECT race, sex, hispanic, agegrp1,
SUM(n_7) as Number_of_bup_disp_post,
SUM(n_7)/SUM(n) as Percent_of_bup_disp_post,
SUM(n_8) as Number_of_BUP_DISP_PRE, 
SUM(n_8)/SUM(n) as Percent_of_BUP_DISP_PRE,
SUM(n_9) as Number_of_BUP_PRESC_POST, 
SUM(n_9)/SUM(n) as Percent_of_BUP_PRESC_POST,
SUM(n_10) as Number_of_BUP_PRESC_PRE, 
SUM(n_10)/SUM(n) as Percent_of_BUP_PRESC_PRE,
SUM(n_37) as Number_of_methadone_disp_post,
SUM(n_37)/SUM(n) as Percent_of_methadone_disp_post,
SUM(n_38) as Number_of_methadone_DISP_PRE, 
SUM(n_38)/SUM(n) as Percent_of_methadone_DISP_PRE,
SUM(n_39) as Number_of_methadone_PRESC_POST, 
SUM(n_39)/SUM(n) as Percent_of_methadone_PRESC_POST,
SUM(n_40) as Number_of_methadone_PRESC_PRE,
SUM(n_40)/SUM(n) as Percent_of_methadone_PRESC_PRE,
SUM(n_50) as Number_of_NALTREX_disp_post,
SUM(n_50)/SUM(n) as Percent_of_NALTREX_disp_post,
SUM(n_51) as Number_of_NALTREX_DISP_PRE, 
SUM(n_51)/SUM(n) as Percent_of_NALTREX_DISP_PRE,
SUM(n_52) as Number_of_NALTREX_PRESC_POST, 
SUM(n_52)/SUM(n) as Percent_of_NALTREX_PRESC_POST,
SUM(n_53) as Number_of_NALTREX_PRESC_PRE,
SUM(n_53)/SUM(n) as Percent_of_NALTREX_PRESC_PRE
FROM old.sum_opioid_exposure
GROUP BY race, sex, hispanic, agegrp1;
QUIT;
%export(mat_opioid_exposure);
PROC SQL noprint;
CREATE TABLE NEW.mat_chronic_opioid AS
SELECT race, sex, hispanic, agegrp1,
SUM(n_7) as Number_of_bup_disp_post,
SUM(n_7)/SUM(n) as Percent_of_bup_disp_post,
SUM(n_8) as Number_of_BUP_DISP_PRE, 
SUM(n_8)/SUM(n) as Percent_of_BUP_DISP_PRE,
SUM(n_9) as Number_of_BUP_PRESC_POST, 
SUM(n_9)/SUM(n) as Percent_of_BUP_PRESC_POST,
SUM(n_10) as Number_of_BUP_PRESC_PRE, 
SUM(n_10)/SUM(n) as Percent_of_BUP_PRESC_PRE,
SUM(n_37) as Number_of_methadone_disp_post,
SUM(n_37)/SUM(n) as Percent_of_methadone_disp_post,
SUM(n_38) as Number_of_methadone_DISP_PRE, 
SUM(n_38)/SUM(n) as Percent_of_methadone_DISP_PRE,
SUM(n_39) as Number_of_methadone_PRESC_POST, 
SUM(n_39)/SUM(n) as Percent_of_methadone_PRESC_POST,
SUM(n_40) as Number_of_methadone_PRESC_PRE,
SUM(n_40)/SUM(n) as Percent_of_methadone_PRESC_PRE,
SUM(n_50) as Number_of_NALTREX_disp_post,
SUM(n_50)/SUM(n) as Percent_of_NALTREX_disp_post,
SUM(n_51) as Number_of_NALTREX_DISP_PRE, 
SUM(n_51)/SUM(n) as Percent_of_NALTREX_DISP_PRE,
SUM(n_52) as Number_of_NALTREX_PRESC_POST, 
SUM(n_52)/SUM(n) as Percent_of_NALTREX_PRESC_POST,
SUM(n_53) as Number_of_NALTREX_PRESC_PRE,
SUM(n_53)/SUM(n) as Percent_of_NALTREX_PRESC_PRE
FROM old.sum_chronic_opioid
GROUP BY race, sex, hispanic, agegrp1;
QUIT;
%export(mat_chronic_opioid);
PROC SQL noprint;
CREATE TABLE NEW.mat_OUD AS
SELECT race, sex, hispanic, agegrp1,
SUM(n_7) as Number_of_bup_disp_post,
SUM(n_8) as Number_of_BUP_DISP_PRE, 
SUM(n_9) as Number_of_BUP_PRESC_POST, 
SUM(n_10) as Number_of_BUP_PRESC_PRE, 
SUM(n_37) as Number_of_methadone_disp_post,
SUM(n_38) as Number_of_methadone_DISP_PRE, 
SUM(n_39) as Number_of_methadone_PRESC_POST, 
SUM(n_40) as Number_of_methadone_PRESC_PRE,
SUM(n_50) as Number_of_NALTREX_disp_post,
SUM(n_51) as Number_of_NALTREX_DISP_PRE, 
SUM(n_52) as Number_of_NALTREX_PRESC_POST, 
SUM(n_53) as Number_of_NALTREX_PRESC_PRE
FROM old.sum_OUD
GROUP BY race, sex, hispanic, agegrp1;
QUIT;
%export(mat_OUD);
PROC SQL noprint;
CREATE TABLE NEW.mat_overdose AS
SELECT race, sex, hispanic, agegrp1,
SUM(n_7) as Number_of_bup_disp_post,
SUM(n_7)/SUM(n) as Percent_of_bup_disp_post,
SUM(n_8) as Number_of_BUP_DISP_PRE, 
SUM(n_8)/SUM(n) as Percent_of_BUP_DISP_PRE,
SUM(n_9) as Number_of_BUP_PRESC_POST, 
SUM(n_9)/SUM(n) as Percent_of_BUP_PRESC_POST,
SUM(n_10) as Number_of_BUP_PRESC_PRE, 
SUM(n_10)/SUM(n) as Percent_of_BUP_PRESC_PRE,
SUM(n_37) as Number_of_methadone_disp_post,
SUM(n_37)/SUM(n) as Percent_of_methadone_disp_post,
SUM(n_38) as Number_of_methadone_DISP_PRE, 
SUM(n_38)/SUM(n) as Percent_of_methadone_DISP_PRE,
SUM(n_39) as Number_of_methadone_PRESC_POST, 
SUM(n_39)/SUM(n) as Percent_of_methadone_PRESC_POST,
SUM(n_40) as Number_of_methadone_PRESC_PRE,
SUM(n_40)/SUM(n) as Percent_of_methadone_PRESC_POST,
SUM(n_50) as Number_of_NALTREX_disp_post,
SUM(n_50)/SUM(n) as Percent_of_NALTREX_disp_post,
SUM(n_51) as Number_of_NALTREX_DISP_PRE, 
SUM(n_51)/SUM(n) as Percent_of_NALTREX_DISP_PRE,
SUM(n_52) as Number_of_NALTREX_PRESC_POST, 
SUM(n_52)/SUM(n) as Percent_of_NALTREX_PRESC_POST,
SUM(n_53) as Number_of_NALTREX_PRESC_PRE,
SUM(n_53)/SUM(n) as Percent_of_NALTREX_PRESC_PRE
FROM old.sum_overdose
GROUP BY race, sex, hispanic, agegrp1;
QUIT;
%export(mat_overdose);

/*How often are clinicians co-prescribing naloxone with opioids?*/

PROC SQL noprint;
CREATE TABLE NEW.opioid_naloxone AS
SELECT eventyear,SUM(n_48) as Number_of_copresc_opioid_nlx,SUM(n_48)/SUM(n) as Percent_of_copresc_opioid_nlx
FROM old.sum_opioid_exposure
GROUP BY eventyear;
QUIT;
%export(opioid_naloxone);

/*Frequency of naloxone prescribing by year */
PROC SQL noprint;
CREATE TABLE NEW.naloxone_prescription AS
SELECT eventyear, SUM(n_48) as Number_of_naloxone_presc,SUM(n_48)/SUM(n) as Percent_of_naloxone_presc, sum(n) as sumn
FROM old.sum_binary
GROUP BY eventyear;
QUIT;
%export(naloxone_prescription);
