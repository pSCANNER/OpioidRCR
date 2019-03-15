
/***************************************************************************************************/
/**!!!! For all regressions when the PATIENT is the unit of analysis you must pick only ONE year */
/*The logic here is choosing the most recent opioid exposure record, if one doesn't have opioid exposure record, then choose the most recent one.*/
/***************************************************************************************************/
proc sort data=dmlocal.opioid_flat_file out=dmlocal.opioid_flat_model;
by patid descending opioid_flag descending indexdate;
run;
data dmlocal.opioid_flat_model;
set dmlocal.opioid_flat_model;
by patid;
if first.patid;
run;

proc sort data=dmlocal.opioid_flat_file_exc_cancer out=dmlocal.opioid_flat_model_exc_cancer;
by patid descending opioid_flag descending indexdate;
run;
data dmlocal.opioid_flat_model_exc_cancer;
set dmlocal.opioid_flat_model_exc_cancer;
by patid;
if first.patid;
run;


/*Regression1a: Adjusted effect of exposure on OUDs (cancer excluded)*/
proc logistic data=dmlocal.opioid_flat_model_exc_cancer;
	class race sex hispanic agegrp1 eventyear;
	model Opioid_Use_DO_Any_Prior =opioid_flag race sex hispanic agegrp1 eventyear;
	where DISPENSE_DATE ne .;
run;

/*Regression1b: Adjusted effect of exposure on OUDs (cancer only)*/
proc logistic data=dmlocal.opioid_flat_model;
	class race sex hispanic agegrp1 eventyear;
	model Opioid_Use_DO_Any_Prior =opioid_flag race sex hispanic agegrp1 eventyear;
	where Cancer_Inpt_Dx_Year_Prior=1 OR CANCER_PROC_FLAG=1;
run;

/*Regression 2: Guideline adherence - mixed effects regression*/
proc glimmix data=dmlocal.opioid_flat_model_exc_cancer;
	class race sex hispanic agegrp1 eventyear RX_PROVIDERID;
	model opioid_flag=MH_Dx_Pri_Any_Prior race sex hispanic agegrp1 eventyear Opioid_Use_DO_Any_Prior MH_Dx_Pri_Any_Prior /dist=bin link=logit;
	random intercept / subject=RX_PROVIDERID;
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





