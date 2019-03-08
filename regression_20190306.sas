
%put Temporarily turning log capturing off to avoid printing paths;
proc printto; run;

ods pdf style=style1 file="&DRNOC./Opioid_RCR_report.pdf"  startpage=no style=journal;

proc printto log="&DRNOC.Opioid_RCR.log"; run;
%put Turning log capturing back on;

title "Regression 1: Adjusted risk of OUD in patients with opioid exposure.";
proc logistic data=DMLocal.opioid_flat_file out=DRNOC.opioid_use_do_opioid_flag;
  class facility_location race sex hispanic AGEGRP1 eventyear;
  model Opioid_Use_DO_Post_Date=opioid_flag facility_location race sex hispanic AGEGRP1 eventyear;
  ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf startpage=now;
title "Regression 2: Guideline adherence - mixed effects regression.";
proc glimmix data=DMLocal.opioid_flat_file; *out=DRNOC.opioid_flag_mh_dx_pri;
  class race sex hispanic AGEGRP1 eventyear;
  model opioid_flag=MH_Dx_Pri_Any_Prior race sex hispanic AGEGRP1 eventyear;
  random intercept / subject=Cancer_AnyEncount_Dx_Year_Prior;
  *ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf startpage=now;
title "Regression 3: Predictors of Opioid Exposure Outcomes.";

ods pdf startpage=now;
title "Regression 5: Predictors of chronic opioid use.";
proc logistic data=DMLocal.opioid_flat_file out=DRNOC.chronic_opioid_flag;
  class facility_location race sex hispanic AGEGRP1 eventyear;
  model chronic_opioid=opioid_flag facility_location race sex hispanic AGEGRP1 eventyear;
  ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf startpage=now;
title "Regression 6: Effects of opioid and other sched drugs on deaths.";

ods pdf startpage=now;
title "Regression 7: Predictors of Co-Rx with Benzos.";

ods pdf startpage=now;
title "Regression 8: Adjusted risk of overdose.";
proc logistic data=DMLocal.opioid_flat_file out=DRNOC.od_pre_opioid_script;
  class facility_location race sex hispanic AGEGRP1 eventyear;
  model od_pre=Opioid_Prescription facility_location race sex hispanic AGEGRP1 eventyear;
  ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf startpage=now;
title "Regression 9: Adjusted risk of fatal overdose.";
proc logistic data=DMLocal.opioid_flat_file out=DRNOC.fatal_overdose_opioid_script;
  class facility_location race sex hispanic AGEGRP1 eventyear;
  model fatal_overdose=Opioid_Prescription facility_location race sex hispanic AGEGRP1 eventyear;
  ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf startpage=now;
title "Regression 10: Adjusted odds of smoking.";

ods pdf startpage=now;
title "Regression 11: Adjusted odds of suicide.";

* Other Models;
ods pdf startpage=now;
title "Adjusted risk of overdose in patients with opioid-inclusive SUD diagnoses.";
proc logistic data=DMLocal.opioid_flat_file out=DRNOC.od_pre_opioid_use_do_any_prior;
  class facility_location race sex hispanic AGEGRP1 eventyear;
  model od_pre=Opioid_Use_DO_Any_Prior facility_location race sex hispanic AGEGRP1 eventyear;
  ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf startpage=now;
title "Adjusted ED and Inpatient utilization in patients with opioid exposure.";
proc logistic data=DMLocal.opioid_flat_file out=DRNOC.ed_ip_yr_opioid_flag;
  class race sex hispanic AGEGRP1 eventyear;
  model ed_ip_yr=opioid_flag race sex hispanic AGEGRP1 eventyear;
  ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf startpage=now;
title "Adjusted ED and Inpatient utilization in patients with opioid-inclusive SUD diagnoses.";
proc logistic data=DMLocal.opioid_flat_file out=DRNOC.ed_ip_yr_opioid_use_do_any_prior;
  class race sex hispanic AGEGRP1 eventyear;
  model ed_ip_yr=Opioid_Use_DO_Any_Prior race sex hispanic AGEGRP1 eventyear;
  ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf startpage=now;
title "Adjusted ED and Inpatient utilization in patients with opioid overdose.";
proc logistic data=DMLocal.opioid_flat_file out=DRNOC.ed_ip_yr_od_pre;
  class race sex hispanic AGEGRP1 eventyear;
  model ed_ip_yr=od_pre race sex hispanic AGEGRP1 eventyear;
  ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf close;

%put Turning off log capturing to rewrite log file and mask all numbers less than the low cell count threshold;
proc printto; run;
