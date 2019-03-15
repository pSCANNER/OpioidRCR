
/***************************************************************************************************/
/**!!!! For all regressions when the PATIENT is the unit of analysis you must pick only ONE year */
/*The logic here is choosing the first opioid exposure record, if one doesn't have opioid exposure record, then choose the most recent one.*/
/***************************************************************************************************/
proc sort data=dmlocal.opioid_flat_file;
by encounterid;
run;
proc sort data=indata.encounter;
by encounterid;
run;
data dmlocal.opioid_flat_file;
merge indata.encounter(keep=encounterid providerid) dmlocal.opioid_flat_file(in=a);
by encounterid;
if a;
run;
data dmlocal.opioid_flat_file_exc_cancer;
set dmlocal.opioid_flat_file;
where Cancer_Inpt_Dx_Year_Prior=0 and CANCER_PROC_FLAG=0;
run;
proc sort data=dmlocal.opioid_flat_file;
by patid eventyear;
run;

data opioid_flat_model;
set dmlocal.opioid_flat_file; 
by patid;
retain count 0;
if first.patid then count=0;
if opioid_flag=1 then count=1;
run;
data opioid_flat_model;
set opioid_flat_model;
retain opioid_any_prior;
by patid;
if first.patid then opioid_any_prior=0;
opioid_any_prior+count;
run;

proc sort data=opioid_flat_model out=dmlocal.opioid_flat_model;
by patid descending opioid_any_prior descending eventyear;
where opioid_any_prior in (0,1);
run;

data dmlocal.opioid_flat_model;
set dmlocal.opioid_flat_model;
by patid;
if first.patid;
drop count;
run;

data dmlocal.opioid_flat_model_exc_cancer;
set dmlocal.opioid_flat_model;
where Cancer_Inpt_Dx_Year_Prior=0 and CANCER_PROC_FLAG=0;
run;

/*Regression1: Adjusted effect of exposure on OUDs (cancer excluded)*/
proc logistic data=dmlocal.opioid_flat_model_exc_cancer;
	class race sex hispanic agegrp1 eventyear;
	model Post_Rx_Opioid_Use_DO_indicator =opioid_flag race sex hispanic agegrp1 eventyear;
	where DISPENSE_DATE ne .;
run;

/*Regression 2: Guideline adherence - mixed effects regression*/
proc glimmix data=dmlocal.opioid_flat_model_exc_cancer;
	class race sex hispanic agegrp1 eventyear PROVIDERID;
	model opioid_flag=MH_Dx_Pri_Any_Prior race sex hispanic agegrp1 eventyear Opioid_Use_DO_Any_Prior MH_Dx_Pri_Any_Prior /dist=bin link=logit;
	random intercept / subject=PROVIDERID;
	where Cancer_AnyEncount_Dx_Year_Prior=0; 
run;

/*Regression 3: Predictors of Any Opioid Exposure */
/* If you cannot easily create the necessary variables, conver this to a logit with the DV */
proc logistic data=opioid_flat_file_exc_cancer;
	class race sex hispanic agegrp1 eventyear;
	model opioid_flag = race sex hispanic agegrp1 eventyear Alcohol_Use_DO_Any_Prior 
	Substance_Use_DO_Any_Prior Opioid_Use_DO_Any_Prior Cannabis_Use_DO_Any_Prior Cocaine_Use_DO_Any_Prior 
	Hallucinogen_Use_DO_Any_Prior Inhalant_Use_DO_Any_Prior Other_Stim_Use_DO_Any_Prior SedHypAnx_Use_DO_Any_Prior 
	/ selection=stepwise;
run;

/*Regression 4: Predictors of Opioid Exposure Outcomes - Neonatal Abstinence Syndrome (current status 0.06% incidence)*/

/*Regression 5: Predictors of chronic opioid use*/
proc logistic data=opioid_flat_model_exc_cancer;
	class race sex hispanic agegrp1 eventyear;
	model chronic_opioid(1) = race sex hispanic agegrp1 eventyear / selection=stepwise;
run;

/*Regression 6: Effects of Opioid and other Sched drugs on deaths*/

/*Regression 7: Predictors of Co-Rx with Benzos*/

/*Regression 8: Adjusted risk of overdose*/
proc logistic data=opioid_flat_model_exc_cancer;
	class  race sex hispanic agegrp1 eventyear;
	model od_post=opioid_prescription  race sex hispanic agegrp1 eventyear;
run;

/*Regression 9: Adjusted risk of fatal overdose*/
proc logistic data=opioid_flat_model_exc_cancer;
	class  race sex hispanic agegrp1 eventyear;
	model fatal_overdose=opioid_prescription race sex hispanic agegrp1 eventyear;
run;

/*Regression 10: Adjusted odds of smoking*/
proc logistic data=opioid_flat_model_exc_cancer;
	class race sex hispanic agegrp1 eventyear;
	model smoking=opioid_flag race sex hispanic agegrp1 eventyear;
run;





