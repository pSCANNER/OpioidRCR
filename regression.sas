/*Regression 1a: Adjusted risk of OUD(Y) in patients with opioid exposure(X)--Cancer Excluded*/
proc logistic data=opioid_flat_file_exc_cancer;
	class race sex hispanic agegrp1 eventyear;
	model Opioid_Use_DO_Post_date=opioid_flag race sex hispanic agegrp1 eventyear;
	where Opioid_Use_DO_Any_Prior=0 and DISPENSE_DATE ne .;
run;

/*Regression 1b: Adjusted risk of OUD(Y) in patients with opioid exposure(X)--Cancer Only*/
proc logistic data=opioid_flat_file;
	class race sex hispanic agegrp1 eventyear;
	model Opioid_Use_DO_Post_date=opioid_flag race sex hispanic agegrp1 eventyear;
	where Cancer_Inpt_Dx_Year_Prior=1 OR CANCER_PROC_FLAG=1;
run;

/*Regression 2: Guideline adherence - mixed effects regression*/
proc glimmix data=opioid_flat_file;
	class race sex hispanic agegrp1 eventyear;
	model opioid_flag=MH_Dx_Pri_Any_Prior race sex hispanic agegrp1 eventyear oud MH_Dx_Pri_Any_Prior;
	random intercept / subject=Cancer_AnyEncount_Dx_Year_Prior;
run;

/*Regression 3: Predictors of Opioid Exposure Outcomes*/
proc phreg data=opioid_flat_file_exc_cancer;
	class race sex hispanic agegrp1 eventyear;
	model lookback_before_index_opioid*opioid_flag(0) = race sex hispanic agegrp1 eventyear Alcohol_Use_DO_Any_Prior 
	Substance_Use_DO_Any_Prior Opioid_Use_DO_Any_Prior Cannabis_Use_DO_Any_Prior Cocaine_Use_DO_Any_Prior 
	Hallucinogen_Use_DO_Any_Prior Inhalant_Use_DO_Any_Prior Other_Stim_Use_DO_Any_Prior SedHypAnx_Use_DO_Any_Prior / selection=stepwise;
run;

/*Regression 4: Predictors of Opioid Exposure Outcomes - Neonatal Abstinence Syndrome (current status 0.06% incidence)*/

/*Regression 5: Predictors of chronic opioid use*/
proc phreg data=opioid_flat_file_exc_cancer;
class race sex hispanic agegrp1 eventyear;
model CHRONIC_OPIOID_DATE*chronic_opioid(0) = race sex hispanic agegrp1 eventyear / selection=stepwise;
run;

/*Regression 6: Effects of Opioid and other Sched drugs on deaths*/

/*Regression 7: Predictors of Co-Rx with Benzos*/

/*Regression 8: Adjusted risk of overdose*/
proc logistic data=opioid_flat_file_exc_cancer;
class  race sex hispanic agegrp1 eventyear;
model od_pre=opioid_prescription  race sex hispanic agegrp1 eventyear;
run;

/*Regression 9: Adjusted risk of fatal overdose*/
proc logistic data=opioid_flat_file_exc_cancer;
class  race sex hispanic agegrp1 eventyear;
model fatal_overdose=opioid_prescription race sex hispanic agegrp1 eventyear;
run;

/*Regression 10: Adjusted odds of smoking*/
proc logistic data=opioid_flat_file_exc_cancer;
	class race sex hispanic agegrp1 eventyear;
	model smoking=opioid_flag race sex hispanic agegrp1 eventyear;
run;





