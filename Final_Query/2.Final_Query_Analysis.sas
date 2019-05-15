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
proc contents data=OLD.&dataset out=vars(keep=name type) noprint;
run; 
data vars;                                                
   set vars;                                                 
    if type=2 and name not in ("SITE","FACILITY_LOCATION","RACE","SEX","HISPANIC","AGEGRP1","EVENTYEAR") ;     
   newname=trim(left(name))||"_n"; 
run;                                                                              
proc sql noprint;                                         
   select trim(left(name)), trim(left(newname)),             
          trim(left(newname))||'='||trim(left(name))         
          into :c_list separated by ' ', :n_list separated by ' ',  
          :renam_list separated by ' '                         
          from vars;                                                
quit;                                                                                                               
 data OLD.&dataset;                                               
   set OLD.&dataset;                                                 
   array ch(*) $ &c_list;                                    
   array nu(*) &n_list;                                      
   do i = 1 to dim(ch);                                      
      nu(i)=input(ch(i),8.);                                  
   end;                                                      
   drop i &c_list;                                           
   rename &renam_list;                                                                                      
run;                                                                                                                       
 
%MEND import;
%MACRO export(dataset);
PROC EXPORT DATA=new.&dataset
            OUTFILE= "&newpath&dataset..csv" 
            DBMS=CSV REPLACE;
RUN;
%MEND export;
%import (sum_binary.csv,sum_binary);
%import (sum_oud.csv,sum_oud);
%import (sum_opioid_exposure.csv,sum_opioid_exposure);
%import (sum_chronic_opioid.csv,sum_chronic_opioid);
%import (sum_overdose.csv,sum_overdose);

/*Table indicating extend OUD population reflect co-morbid mental illness (primary list) recommendation to look at any year vs 1 year prior and 
what are the demographic characteristics of the dual diagnosis population (age, gender, race, ethnicity) */

PROC SQL noprint;
CREATE TABLE NEW.oud_mhpri_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, SUM(n_57) as Number_of_comorbid_oud_mhpri, SUM(n_57)/SUM(n) as Percent_of_comorbid_oud_mhpri
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_mhpri_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,SUM(n_58) as Number_of_comorbid_oud_mhpri, SUM(n_58)/SUM(n) as Percent_of_comorbid_oud_mhpri
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_mhpri_year_prior);
%export(oud_mhpri_any_prior);

/*Table indicating extend OUD population reflect co-morbid mental illness (exploratory list) recommendation to look at any year vs 1 year prior and 
what are the demographic characteristics of the dual diagnosis population (age, gender, race, ethnicity) */
PROC SQL noprint;
CREATE TABLE NEW.oud_mhexp_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, SUM(n_55) as Number_of_comorbid_oud_mhexp, SUM(n_55)/SUM(n) as Percent_of_comorbid_oud_mhexp
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_mhexp_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, SUM(n_56) as Number_of_comorbid_oud_mhexp, SUM(n_56)/SUM(n) as Percent_of_comorbid_oud_mhexp
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
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,SUM(n_23) as Number_of_cooccur_oud_cannabis, SUM(n_23)/SUM(n) as Percent_of_cooccur_oud_cannabis
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_cannabis_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, SUM(n_24) as Number_of_cooccur_oud_cannabis, SUM(N_24)/SUM(n) as Percent_of_cooccur_oud_cannabis
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_cannabis_year_prior);
%export(oud_cannabis_any_prior);

PROC SQL noprint;
CREATE TABLE NEW.oud_inhalent_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, SUM(n_46) as Number_of_cooccur_oud_inhalent, SUM(n_46)/SUM(n) as Percent_of_cooccur_oud_inhalent
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_inhalent_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,SUM(n_48) as Number_of_cooccur_oud_inhalent,SUM(n_48)/SUM(n) as Percent_of_cooccur_oud_inhalent
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
%export(oud_inhalent_year_prior);
%export(oud_inhalent_any_prior);

PROC SQL noprint;
CREATE TABLE NEW.oud_hallucinogen_any_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear, SUM(n_38) as Number_of_cooccur_oud_hlcg, SUM(n_38)/SUM(n) as Percent_of_cooccur_oud_hlcg
FROM old.sum_oud
GROUP BY facility_location,race, sex, hispanic, agegrp1,eventyear;
QUIT;
PROC SQL noprint;
CREATE TABLE NEW.oud_hallucinogen_year_prior AS
SELECT facility_location,race, sex, hispanic, agegrp1,eventyear,SUM(n_40) as Number_of_cooccur_oud_hlcg, SUM(n_40)/SUM(n) as Percent_of_cooccur_oud_hlcg 
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
SUM(n_9) as Number_of_BUP_DISP_PRE, 
SUM(n_9)/SUM(n) as Percent_of_BUP_DISP_PRE,
SUM(n_11) as Number_of_BUP_PRESC_POST, 
SUM(n_11)/SUM(n) as Percent_of_BUP_PRESC_POST,
SUM(n_12) as Number_of_BUP_PRESC_PRE, 
SUM(n_12)/SUM(n) as Percent_of_BUP_PRESC_PRE,
SUM(n_47) as Number_of_methadone_disp_post,
SUM(n_47)/SUM(n) as Percent_of_methadone_disp_post,
SUM(n_49) as Number_of_methadone_DISP_PRE, 
SUM(n_49)/SUM(n) as Percent_of_methadone_DISP_PRE,
SUM(n_51) as Number_of_methadone_PRESC_POST, 
SUM(n_51)/SUM(n) as Percent_of_methadone_PRESC_POST,
SUM(n_52) as Number_of_methadone_PRESC_PRE,
SUM(n_52)/SUM(n) as Percent_of_methadone_PRESC_PRE,
SUM(n_62) as Number_of_NALTREX_disp_post,
SUM(n_62)/SUM(n) as Percent_of_NALTREX_disp_post,
SUM(n_64) as Number_of_NALTREX_DISP_PRE, 
SUM(n_62)/SUM(n) as Percent_of_NALTREX_DISP_PRE,
SUM(n_66) as Number_of_NALTREX_PRESC_POST, 
SUM(n_66)/SUM(n) as Percent_of_NALTREX_PRESC_POST,
SUM(n_67) as Number_of_NALTREX_PRESC_PRE,
SUM(n_67)/SUM(n) as Percent_of_NALTREX_PRESC_PRE
FROM old.sum_opioid_exposure
GROUP BY race, sex, hispanic, agegrp1;
QUIT;

PROC SQL noprint;
CREATE TABLE NEW.mat_chronic_opioid AS
SELECT race, sex, hispanic, agegrp1,
SUM(n_7) as Number_of_bup_disp_post,
SUM(n_7)/SUM(n) as Percent_of_bup_disp_post,
SUM(n_9) as Number_of_BUP_DISP_PRE, 
SUM(n_9)/SUM(n) as Percent_of_BUP_DISP_PRE,
SUM(n_11) as Number_of_BUP_PRESC_POST, 
SUM(n_11)/SUM(n) as Percent_of_BUP_PRESC_POST,
SUM(n_12) as Number_of_BUP_PRESC_PRE, 
SUM(n_12)/SUM(n) as Percent_of_BUP_PRESC_PRE,
SUM(n_47) as Number_of_methadone_disp_post,
SUM(n_47)/SUM(n) as Percent_of_methadone_disp_post,
SUM(n_49) as Number_of_methadone_DISP_PRE, 
SUM(n_49)/SUM(n) as Percent_of_methadone_DISP_PRE,
SUM(n_51) as Number_of_methadone_PRESC_POST, 
SUM(n_51)/SUM(n) as Percent_of_methadone_PRESC_POST,
SUM(n_52) as Number_of_methadone_PRESC_PRE,
SUM(n_52)/SUM(n) as Percent_of_methadone_PRESC_PRE,
SUM(n_62) as Number_of_NALTREX_disp_post,
SUM(n_62)/SUM(n) as Percent_of_NALTREX_disp_post,
SUM(n_64) as Number_of_NALTREX_DISP_PRE, 
SUM(n_64)/SUM(n) as Percent_of_NALTREX_DISP_PRE,
SUM(n_66) as Number_of_NALTREX_PRESC_POST, 
SUM(n_66)/SUM(n) as Percent_of_NALTREX_PRESC_POST,
SUM(n_67) as Number_of_NALTREX_PRESC_PRE,
SUM(n_67)/SUM(n) as Percent_of_NALTREX_PRESC_PRE,
FROM old.sum_chronic_opioid
GROUP BY race, sex, hispanic, agegrp1;
QUIT;
%export(mat_chronic_opioid);
PROC SQL noprint;
CREATE TABLE NEW.mat_OUD AS
SELECT race, sex, hispanic, agegrp1,
SUM(n_7) as Number_of_bup_disp_post,
SUM(n_9) as Number_of_BUP_DISP_PRE, 
SUM(n_11) as Number_of_BUP_PRESC_POST, 
SUM(n_12) as Number_of_BUP_PRESC_PRE, 
SUM(n_47) as Number_of_methadone_disp_post,
SUM(n_49) as Number_of_methadone_DISP_PRE, 
SUM(n_51) as Number_of_methadone_PRESC_POST, 
SUM(n_52) as Number_of_methadone_PRESC_PRE,
SUM(n_62) as Number_of_NALTREX_disp_post,
SUM(n_64) as Number_of_NALTREX_DISP_PRE, 
SUM(n_66) as Number_of_NALTREX_PRESC_POST, 
SUM(n_67) as Number_of_NALTREX_PRESC_PRE
FROM old.sum_OUD
GROUP BY race, sex, hispanic, agegrp1;
QUIT;
%export(mat_OUD);
PROC SQL noprint;
CREATE TABLE NEW.mat_overdose AS
SELECT race, sex, hispanic, agegrp1,
SUM(n_7) as Number_of_bup_disp_post,
SUM(n_7)/SUM(n) as Percent_of_bup_disp_post,
SUM(n_9) as Number_of_BUP_DISP_PRE, 
SUM(n_9)/SUM(n) as Percent_of_BUP_DISP_PRE,
SUM(n_11) as Number_of_BUP_PRESC_POST, 
SUM(n_11)/SUM(n) as Percent_of_BUP_PRESC_POST,
SUM(n_12) as Number_of_BUP_PRESC_PRE, 
SUM(n_12)/SUM(n) as Percent_of_BUP_PRESC_PRE,
SUM(n_47) as Number_of_methadone_disp_post,
SUM(n_47)/SUM(n) as Percent_of_methadone_disp_post,
SUM(n_49) as Number_of_methadone_DISP_PRE, 
SUM(n_49)/SUM(n) as Percent_of_methadone_DISP_PRE,
SUM(n_51) as Number_of_methadone_PRESC_POST, 
SUM(n_51)/SUM(n) as Percent_of_methadone_PRESC_POST,
SUM(n_52) as Number_of_methadone_PRESC_PRE,
SUM(n_52)/SUM(n) as Percent_of_methadone_PRESC_POST,
SUM(n_62) as Number_of_NALTREX_disp_post,
SUM(n_62)/SUM(n) as Percent_of_NALTREX_disp_post,
SUM(n_64) as Number_of_NALTREX_DISP_PRE, 
SUM(n_64)/SUM(n) as Percent_of_NALTREX_DISP_PRE,
SUM(n_66) as Number_of_NALTREX_PRESC_POST, 
SUM(n_66)/SUM(n) as Percent_of_NALTREX_PRESC_POST,
SUM(n_67) as Number_of_NALTREX_PRESC_PRE
SUM(n_67)/SUM(n) as Percent_of_NALTREX_PRESC_PRE
FROM old.sum_overdose
GROUP BY race, sex, hispanic, agegrp1;
QUIT;
%export(mat_overdose);

/*How often are clinicians co-prescribing naloxone with opioids?*/

PROC SQL noprint;
CREATE TABLE NEW.opioid_naloxone AS
SELECT eventyear,SUM(n_19) as Number_of_coprescribe_opioid_nlx,SUM(n_19)/SUM(n) as Percent_of_coprescribe_opioid_nlx
FROM old.sum_opioid_exposure
GROUP BY eventyear;
QUIT;
%export(opioid_naloxone);

/*Frequency of naloxone prescribing by year */
PROC SQL noprint;
CREATE TABLE NEW.naloxone_prescription AS
SELECT eventyear, SUM(n_19) as Number_of_naloxone_prescription,SUM(n_19)/SUM(n) as Percent_of_naloxone_prescription
FROM old.sum_binary
GROUP BY eventyear;
QUIT;
%export(opioid_naloxone);
