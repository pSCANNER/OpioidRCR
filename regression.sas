
 /*Adjusted risk of overdose(Y) in patients with opioid exposure(X)*/
proc logistic data=opioid_flat_file;
class facility_location race sex hispanic AgeAsOfJuly1 eventyear;
model past_od=opioid_flag facility_location race sex hispanic AgeAsOfJuly1 eventyear;
run;

/*Adjusted risk of overdose in patients with opioid-inclusive SUD diagnoses.*/
proc logistic data=opioid_flat_file;
class facility_location race sex hispanic AgeAsOfJuly1 eventyear;
model past_od=Opioid_Use_DO_Any_Prior facility_location race sex hispanic AgeAsOfJuly1 eventyear;
run;

/*Opioid exposure for women of child-bearing age along with rate of NAS (county vs. individual level regression).*/
/*county level*/
proc logistic data=opioid_flat_file;
class facility_location race hispanic AgeAsOfJuly1 eventyear;
model nas=opioid_flag facility_location race sex hispanic AgeAsOfJuly1 eventyear;
where sex="F";
run;
/*individual level*/
proc logistic data=opioid_flat_file;
class race hispanic AgeAsOfJuly1 eventyear;
model nas=opioid_flag facility_location race sex hispanic AgeAsOfJuly1 eventyear;
where sex="F";
run;

/*Adjusted ED and Inpatient utilization in patients with opioid exposure. */
proc logistic data=opioid_flat_file;
class race sex hispanic AgeAsOfJuly1 eventyear;
model ed_ip_yr=opioid_flag facility_location race sex hispanic AgeAsOfJuly1 eventyear;
run;

/*Adjusted ED and Inpatient utilization in patients with opioid-inclusive SUD diagnoses. */
proc logistic data=opioid_flat_file;
class race sex hispanic AgeAsOfJuly1 eventyear;
model ed_ip_yr=Opioid_Use_DO_Any_Prior facility_location race sex hispanic AgeAsOfJuly1 eventyear;
run;

/*Adjusted ED and Inpatient utilization in patients with opioid overdose. */
proc logistic data=opioid_flat_file;
class race sex hispanic AgeAsOfJuly1 eventyear;
model ed_ip_yr=past_od facility_location race sex hispanic AgeAsOfJuly1 eventyear;
run;
