
%put Temporarily turning log capturing off to avoid printing paths;
proc printto; run;

ods pdf style=style1 file="&DRNOC./Opioid_RCR_report.pdf"  startpage=no style=journal;

proc printto log="&DRNOC.Opioid_RCR.log"; run;
%put Turning log capturing back on;

title "Adjusted risk of overdose in patients with opioid exposure.";
/*Adjusted risk of overdose(Y) in patients with opioid exposure(X).*/
proc logistic data=DMLocal.opioid_flat_file out=DRNOC.od_pre_opioid_flag;
class facility_location race sex hispanic AGEGRP1 eventyear;
model od_pre=opioid_flag facility_location race sex hispanic AGEGRP1 eventyear;
ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf startpage=now;
title "Adjusted risk of overdose in patients with opioid-inclusive SUD diagnoses.";
/*Adjusted risk of overdose in patients with opioid-inclusive SUD diagnoses.*/
proc logistic data=DMLocal.opioid_flat_file out=DRNOC.od_pre_opioid_use_do_any_prior;
class facility_location race sex hispanic AGEGRP1 eventyear;
model od_pre=Opioid_Use_DO_Any_Prior facility_location race sex hispanic AGEGRP1 eventyear;
ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf startpage=now;
title "Adjusted ED and Inpatient utilization in patients with opioid exposure.";
/*Adjusted ED and Inpatient utilization in patients with opioid exposure.*/
proc logistic data=DMLocal.opioid_flat_file out=DRNOC.ed_ip_yr_opioid_flag;
class race sex hispanic AGEGRP1 eventyear;
model ed_ip_yr=opioid_flag race sex hispanic AGEGRP1 eventyear;
ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf startpage=now;
title "Adjusted ED and Inpatient utilization in patients with opioid-inclusive SUD diagnoses.";
/*Adjusted ED and Inpatient utilization in patients with opioid-inclusive SUD diagnoses.*/
proc logistic data=DMLocal.opioid_flat_file out=DRNOC.ed_ip_yr_opioid_use_do_any_prior;
class race sex hispanic AGEGRP1 eventyear;
model ed_ip_yr=Opioid_Use_DO_Any_Prior race sex hispanic AGEGRP1 eventyear;
ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf startpage=now;
title "Adjusted ED and Inpatient utilization in patients with opioid overdose.";
/*Adjusted ED and Inpatient utilization in patients with opioid overdose.*/
proc logistic data=DMLocal.opioid_flat_file out=DRNOC.ed_ip_yr_od_pre;
class race sex hispanic AGEGRP1 eventyear;
model ed_ip_yr=od_pre race sex hispanic AGEGRP1 eventyear;
ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf close;

%put Turning off log capturing to rewrite log file and mask all numbers less than the low cell count threshold;
proc printto; run;
