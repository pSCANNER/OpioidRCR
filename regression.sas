/*Regression 1: Adjusted risk of OUD(Y) in patients with opioid exposure(X)*/
proc logistic data=opioid_flat_file;
	class facility_location race sex hispanic agegrp1 eventyear;
	model oud=opioid_flag facility_location race sex hispanic agegrp1 eventyear;
run;

/*Regression 2: Guideline adherence - mixed effects regression*/
proc glimmix data=opioid_flat_file;
	class race sex hispanic agegrp1 eventyear;
	model opioid_flag=MH_Dx_Pri_Any_Prior race sex hispanic agegrp1 eventyear;
	random intercept / subject=Cancer_AnyEncount_Dx_Year_Prior;
run;

/*Regression 3: Predictors of Opioid Exposure Outcomes*/

/*Regression 4: Predictors of Opioid Exposure Outcomes - Neonatal Abstinence Syndrome (current status 0.06% incidence)*/

/*Regression 5: Predictors of chronic opioid use*/
proc logistic data=opioid_flat_file;
class facility_location race sex hispanic agegrp1 eventyear;
model CHRONIC_OPIOID=opioid_flag facility_location race sex hispanic agegrp1 eventyear;
run;

/*Regression 6: Effects of Opioid and other Sched drugs on deaths*/

/*Regression 7: Predictors of Co-Rx with Benzos*/

/*Regression 8: Adjusted risk of overdose*/
proc logistic data=opioid_flat_file;
class facility_location race sex hispanic agegrp1 eventyear;
model od_pre=opioid_prescription facility_location race sex hispanic agegrp1 eventyear;
run;

/*Regression 9: Adjusted risk of fatal overdose*/
proc logistic data=opioid_flat_file;
class facility_location race sex hispanic agegrp1 eventyear;
model fatal_overdose=opioid_prescription facility_location race sex hispanic agegrp1 eventyear;
run;

/*Regression 10: Adjusted odds of smoking*/
/*What IV should be included in this model?*/

/*Regression 11: Adjusted odds of suicide*/

/*Regression 12: Opioid exposure for women of child-bearing age along with rate of NAS (county vs. individual level regression).*/
/*county level*/
proc logistic data=opioid_flat_file;
class facility_location race hispanic agegrp1 eventyear;
model nas=opioid_flag facility_location race sex hispanic agegrp1 eventyear;
where sex="F";
run;
/*individual level*/
proc logistic data=opioid_flat_file;
class race hispanic agegrp1 eventyear;
model nas=opioid_flag facility_location race sex hispanic agegrp1 eventyear;
where sex="F";
run;


/*------------Other models----------------------*/
/*Adjusted risk of overdose in patients with opioid-inclusive SUD diagnoses.*/
proc logistic data=opioid_flat_file;
class facility_location race sex hispanic agegrp1 eventyear;
model past_od=Opioid_Use_DO_Any_Prior facility_location race sex hispanic agegrp1 eventyear;
run;



/*Adjusted ED and Inpatient utilization in patients with opioid exposure. */
proc logistic data=opioid_flat_file;
class race sex hispanic agegrp1 eventyear;
model ed_ip_yr=opioid_flag facility_location race sex hispanic agegrp1 eventyear;
run;

/*Adjusted ED and Inpatient utilization in patients with opioid-inclusive SUD diagnoses. */
proc logistic data=opioid_flat_file;
class race sex hispanic agegrp1 eventyear;
model ed_ip_yr=Opioid_Use_DO_Any_Prior facility_location race sex hispanic agegrp1 eventyear;
run;

/*Adjusted ED and Inpatient utilization in patients with opioid overdose. */
proc logistic data=opioid_flat_file;
class race sex hispanic agegrp1 eventyear;
model ed_ip_yr=past_od facility_location race sex hispanic agegrp1 eventyear;
run;


/*Predictors of chronic opioid use*/
proc logistic data=opioid_flat_file;
class facility_location race sex hispanic agegrp1 eventyear;
model CHRONIC_OPIOID=opioid_flag facility_location race sex hispanic agegrp1 eventyear;
run;

