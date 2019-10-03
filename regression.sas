
%put Temporarily turning log capturing off to avoid printing paths;
proc printto; run;

ods pdf style=style1 file="&DRNOC./Opioid_RCR_report.pdf"  startpage=no style=journal;

proc printto log="&DRNOC.Opioid_RCR.log"; run;
%put Turning log capturing back on;

* Table for reg3 - reg10;
data opioid_sort; 
  set dmlocal.opioid_flat_file;
run;
proc sort data=opioid_sort; 
  by PATID EventYear;
run;

* Table for reg1 and reg2a;
proc sql;
	create table opioid_sort_gl_b as
	select *
	from opioid_sort
	where GL_B_DENOM_FOR_ST=1;
quit;


ods pdf startpage=now;
title "Regression 1: Adjusted risk of OUD in patients with opioid exposure - Cancer Excluded.";
proc surveylogistic data=opioid_sort_gl_b;
  class opioid_flag(ref='0') binary_race(ref='0') binary_sex(ref='0') binary_hispanic(ref='0') 
        AGEGRP1(ref='>=65') eventyear(ref='2017') Opioid_UDO_Prior_NotInc_CY(ref='0') PATID;
  cluster PATID;
  model Opioid_UD_Any_CY(event='1') = opioid_flag binary_race binary_sex binary_hispanic AGEGRP1 eventyear 
        Opioid_UDO_Prior_NotInc_CY / expb link=logit clodds;
  ods select ModelInfo ConvergenceStatus FitStatistics ModelANOVA ParameterEstimates CLOdds;
  ods output CLOdds = drnoc.reg1or;
run;
quit;

ods pdf startpage=now;
title "Regression 2a: Guideline adherence - mixed effects regression.";
proc surveylogistic data=opioid_sort_gl_b;
  class binary_race(ref='0') binary_sex(ref='0') binary_hispanic(ref='0') AGEGRP1(ref='>=65')
        eventyear(ref='2017') OPIOID_FLAG_Prior_NotInc_CY(ref='0') PATID;
  cluster PATID;
  model OPIOID_FLAG(event='1') = binary_race binary_sex binary_hispanic AGEGRP1 eventyear 
                                 OPIOID_FLAG_Prior_NotInc_CY / expb link=logit clodds;
  ods select ModelInfo ConvergenceStatus FitStatistics ModelANOVA ParameterEstimates CLOdds;
  ods output CLOdds = drnoc.reg2aor;
run;
quit;

ods pdf startpage=now;
title "Regression 2b: Guideline adherence - logistic regression.";

ods pdf startpage=now;
title "Regression 3: Predictors of Opioid Exposure Outcomes.";
proc surveylogistic data=opioid_sort;
  class binary_race(ref='0') binary_sex(ref='0') binary_hispanic(ref='0') AGEGRP1(ref='>=65') eventyear(ref='2017') 
        Alcohol_Use_DO_Any_Prior(ref='0') Substance_Use_DO_Any_Prior(ref='0') Opioid_Use_DO_Any_Prior(ref='0')
        Cannabis_Use_DO_Any_Prior(ref='0') Cocaine_Use_DO_Any_Prior(ref='0') Halluc_Use_DO_Any_Prior(ref='0')
        Inhalant_Use_DO_Any_Prior(ref='0') Other_Stim_Use_DO_Any_Prior(ref='0') SedHypAnx_Use_DO_Any_Prior(ref='0')
        OPIOID_FLAG_Prior_NotInc_CY(ref='0') PATID;
  cluster PATID;
  model OPIOID_FLAG(event='1') = binary_race binary_sex binary_hispanic AGEGRP1 eventyear Alcohol_Use_DO_Any_Prior
                      Substance_Use_DO_Any_Prior Opioid_Use_DO_Any_Prior Cannabis_Use_DO_Any_Prior Cocaine_Use_DO_Any_Prior
                      Halluc_Use_DO_Any_Prior Inhalant_Use_DO_Any_Prior Other_Stim_Use_DO_Any_Prior 
                      SedHypAnx_Use_DO_Any_Prior OPIOID_FLAG_Prior_NotInc_CY / expb link=logit clodds;
  ods select ModelInfo ConvergenceStatus FitStatistics ModelANOVA ParameterEstimates CLOdds;
  ods output CLOdds = drnoc.reg3or;
run;
quit;

ods pdf startpage=now;
title "Regression 5: Predictors of chronic opioid use.";
proc surveylogistic data=opioid_sort;
  class binary_race(ref='0') binary_sex(ref='0') binary_hispanic(ref='0') AGEGRP1(ref='>=65') eventyear(ref='2017') 
        Alcohol_Use_DO_Any_Prior(ref='0') Substance_Use_DO_Any_Prior(ref='0') Opioid_Use_DO_Any_Prior(ref='0')
        Cannabis_Use_DO_Any_Prior(ref='0') Cocaine_Use_DO_Any_Prior(ref='0') Halluc_Use_DO_Any_Prior(ref='0')
        Inhalant_Use_DO_Any_Prior(ref='0') Other_Stim_Use_DO_Any_Prior(ref='0') SedHypAnx_Use_DO_Any_Prior(ref='0')
        CHRON_OPIOID_Prior_NotInc_CY(ref='0') PATID;
  cluster PATID;
  model CHRONIC_OPIOID_CY(event='1') = binary_race binary_sex binary_hispanic AGEGRP1 eventyear Alcohol_Use_DO_Any_Prior
                         Substance_Use_DO_Any_Prior Opioid_Use_DO_Any_Prior Cannabis_Use_DO_Any_Prior Cocaine_Use_DO_Any_Prior
                         Halluc_Use_DO_Any_Prior Inhalant_Use_DO_Any_Prior Other_Stim_Use_DO_Any_Prior 
                         SedHypAnx_Use_DO_Any_Prior CHRON_OPIOID_Prior_NotInc_CY / expb link=logit clodds;
  ods select ModelInfo ConvergenceStatus FitStatistics ModelANOVA ParameterEstimates CLOdds;
  ods output CLOdds = drnoc.reg5or;
run;
quit;

ods pdf startpage=now;
title "Regression 6: Effects of opioid and other sched drugs on deaths.";

ods pdf startpage=now;
title "Regression 7: Predictors of Co-Rx with Benzos.";

ods pdf startpage=now;
title "Regression 8: Adjusted risk of overdose.";
proc surveylogistic data=opioid_sort;
  class Opioid_Prescription(ref='0') binary_race(ref='0') binary_sex(ref='0') binary_hispanic(ref='0')
        eventyear(ref='2017') OD_PRE_Prior_NotInc_CY(ref='0') PATID;
  cluster PATID;
  model od_pre(event='1') = Opioid_Prescription binary_race binary_sex binary_hispanic AgeAsOfJuly1 eventyear 
                            OD_PRE_Prior_NotInc_CY / expb link=logit clodds;
  ods select ModelInfo ConvergenceStatus FitStatistics ModelANOVA ParameterEstimates CLOdds;
  ods output CLOdds = drnoc.reg8or;
run;
quit;

ods pdf startpage=now;
title "Regression 9: Adjusted risk of fatal overdose.";
proc surveylogistic data=opioid_sort;
  class Opioid_Prescription(ref='0') binary_race(ref='0') binary_sex(ref='0') binary_hispanic(ref='0')
        eventyear(ref='2017') PATID;
  cluster PATID;
  model fatal_overdose(event='1') = Opioid_Prescription binary_race binary_sex binary_hispanic AgeAsOfJuly1
                                    eventyear / expb link=logit clodds;
  ods select ModelInfo ConvergenceStatus FitStatistics ModelANOVA ParameterEstimates CLOdds;
  ods output CLOdds = drnoc.reg9or;
run;
quit;

ods pdf startpage=now;
title "Regression 10: Adjusted odds of smoking.";
proc surveylogistic data=opioid_sort;
  class OPIOID_FLAG(ref='0') binary_race(ref='0') binary_sex(ref='0') binary_hispanic(ref='0') 
        AGEGRP1(ref='>=65') eventyear(ref='2017') SMOKING_Prior_NotInc_CY(ref='0') PATID;
  cluster PATID;
  model smoking = OPIOID_FLAG binary_race binary_sex binary_hispanic AGEGRP1 eventyear 
                  SMOKING_Prior_NotInc_CY / expb link=logit clodds;
  ods select ModelInfo ConvergenceStatus FitStatistics ModelANOVA ParameterEstimates CLOdds;
  ods output CLOdds = drnoc.reg10or;
run;
quit;

ods pdf close;

*Remove Work library datasets;
proc datasets lib=work NOlist MEMTYPE=data kill;
run; quit;

%put Turning off log capturing to rewrite log file and mask all numbers less than the low cell count threshold;
proc printto; run;
