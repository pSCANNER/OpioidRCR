
%put Temporarily turning log capturing off to avoid printing paths;
proc printto; run;

ods pdf style=style1 file="&DRNOC./Opioid_RCR_report.pdf"  startpage=no style=journal;

proc printto log="&DRNOC.Opioid_RCR.log"; run;
%put Turning log capturing back on;

data reg1;
  set DMLocal.opioid_flat_file_exc_cancer;
  where Opioid_Use_DO_Any_Prior=0 AND DISPENSE_DATE ne .;
run;

title "Regression 1: Adjusted risk of OUD in patients with opioid exposure - Cancer Excluded.";
proc logistic data=reg1 out=DRNOC.reg1_oud_no_cancer;
  class race sex hispanic AGEGRP1 eventyear;
  model Post_Rx_Opioid_Use_DO_indicator=opioid_flag race sex hispanic AGEGRP1 eventyear; 
  ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

data reg1b;
  set DMLocal.opioid_flat_file;
  where Cancer_Inpt_Dx_Year_Prior=1 OR CANCER_PROC_FLAG=1;
run;

ods pdf startpage=now;
title "Regression 1b: Adjusted risk of OUD in patients with opioid exposure - Cancer Only.";
proc logistic data=reg1b out=DRNOC.reg1b_oud_cancer_only;
  class race sex hispanic AGEGRP1 eventyear;
  model Opioid_Use_DO_Post_Date=opioid_flag race sex hispanic AGEGRP1 eventyear;
  ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

data reg2;
  set DMLocal.opioid_flat_file_exc_cancer;
  where Cancer_AnyEncount_Dx_Year_Prior = 0;
run;

ods pdf startpage=now;
title "Regression 2: Guideline adherence - mixed effects regression.";
proc glimmix data=reg2;
  class race sex hispanic AGEGRP1 eventyear;
  model opioid_flag=MH_Dx_Pri_Any_Prior race sex hispanic AGEGRP1 eventyear;
  random intercept / subject=Cancer_AnyEncount_Dx_Year_Prior;
  ods select ModelInfo ClassLevels Dimensions OptInfo ConvergenceStatus FitStatistics CovParms Tests3;
run;

ods pdf startpage=now;
title "Regression 3: Predictors of Opioid Exposure Outcomes.";
proc phreg data=DMLocal.opioid_flat_file_exc_cancer out=DRNOC.reg3_ph_outcomes;
  class race sex hispanic AGEGRP1 eventyear;
  model lookback_before_index_opioid*opioid_flag(0) = race sex hispanic AGEGRP1 eventyear Alcohol_Use_DO_Any_Prior
        Substance_Use_DO_Any_Prior Opioid_Use_DO_Any_Prior Cannabis_Use_DO_Any_Prior Cocaine_Use_DO_Any_Prior
		Hallucinogen_Use_DO_Any_Prior Inhalant_Use_DO_Any_Prior Other_Stim_Use_DO_Any_Prior SedHypAnx_Use_DO_Any_Prior
        / selection=stepwise;
  ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates;
run;

ods pdf startpage=now;
title "Regression 5: Predictors of chronic opioid use.";
proc phreg data=DMLocal.opioid_flat_file_exc_cancer out=DRNOC.reg5_ph_chronic_opioid;
  class race sex hispanic AGEGRP1 eventyear;
  model chronic_opioid_date*chronic_opioid(0)=race sex hispanic AGEGRP1 eventyear / selection=stepwise;
  ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates;
run;

ods pdf startpage=now;
title "Regression 6: Effects of opioid and other sched drugs on deaths.";

ods pdf startpage=now;
title "Regression 7: Predictors of Co-Rx with Benzos.";

ods pdf startpage=now;
title "Regression 8: Adjusted risk of overdose.";
proc logistic data=DMLocal.opioid_flat_file_exc_cancer out=DRNOC.reg8_overdose;
  class race sex hispanic AGEGRP1 eventyear;
  model od_pre=Opioid_Prescription race sex hispanic AGEGRP1 eventyear;
  ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf startpage=now;
title "Regression 9: Adjusted risk of fatal overdose.";
proc logistic data=DMLocal.opioid_flat_file_exc_cancer out=DRNOC.reg9_fatal_overdose;
  class race sex hispanic AGEGRP1 eventyear;
  model fatal_overdose=Opioid_Prescription race sex hispanic AGEGRP1 eventyear;
  ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf startpage=now;
title "Regression 10: Adjusted odds of smoking.";
proc logistic data=DMLocal.opioid_flat_file_exc_cancer out=DRNOC.reg10_smoking;
  class race sex hispanic AGEGRP1 eventyear;
  model smoking=opioid_flag race sex hispanic AGEGRP1 eventyear;
  ods select ModelInfo ConvergenceStatus FitStatistics GlobalTests ModelANOVA ParameterEstimates OddsRatios Association;
run;

ods pdf close;

*Remove Work library datasets;
proc datasets lib=work NOlist MEMTYPE=data kill;
run; quit;

%put Turning off log capturing to rewrite log file and mask all numbers less than the low cell count threshold;
proc printto; run;
