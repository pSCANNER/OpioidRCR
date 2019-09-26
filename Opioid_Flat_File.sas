/* TODO
1 -- TEST DM UPDATE TO MV CARRYFORWARD (+EXPLICIT SORTING STATEMENTS ~line 2346)
2 -- VERIFY THAT AESOPS VARIABLES ARE 0 FOR ALL PATIENTS W/ OPIOID RX IN THE EVENT YEAR AND NOT MISSINIG
3 -- PROVIDE JASON OPIOID RX DATES AND AESOPS VARIABLES TO CASE CHECK DATE SEQUENCE FOR 3 PATIENTS FOR AESOPS VARIABLES, ONE WITHOUT 728 AND TWO WITH. 
4 -- CHECK AND UPDATE ALL VALUE SETS FOR OPIOIDS AND NALOXONE (NALOXONE LOOKS SUSPICIOUSLY LOW)
     (MC: 7242 appears a lot in CDM RXNORM_CUI for Naloxone and does not appear to be in code list)
     Daniella, let me (Caron) know what I need to do regarding this.
5 -- MC: for line 223 (Create SAS data file dmlocal.opioid_year_prior). Please confirm that the referenced prescribing file is the opioid ref file. 
	Should it be prescribing_select? - Nevermind, I see select was used to create the events file. 
     */

/* DONE 
1 -- REVIEW MISSINIG DATA CARRYFORWARD FOR ISSUES AND DRAFT UPDATE
2 -- UPDATED GOOGLE SHEET FOR OPIOIDS VALUE SETS, BUT HAVE NOT UPDATED SAS YET
     Not sure what needs to be done, all AESOPS variables are 0 if patients have opiod RX but do not meet specified flags
3 -- Data provided to Jason

5 --Added enrolled indicator. Code tested for subset data (no issues), but not on full data set yet.
8/23/19--Fixed bup_presc_evercy and bup_disp_evercy code. Saw similar discrepanies and fixed evercy variables for hepb, hepc, hiv, and naltrex.

8/26/19: Added the carry forward codes for year prior and everCY variables.
	Added the codes for creating the tables for the regressions
	
8/27/19: Enc_type="EI" also added in the code for cancer_dx_events and cancer_dx_events_cy tables.
9/10/19: Merged variables from cancer_dx_events_cy into cancer_dx_events. ~JND
*/

proc printto log="&DRNOC.Opioid_RCR.log" new; run;

%let StudyStartDate = 18263;	*2010-01-01 Inclusive;
%let StudyEndDate = 21185;		*2018-01-01 Exclusive;


*changed all code to make indexdate inclusive;

* Create SAS data file dmlocal.prescribing_formatted;
PROC SQL inobs=max;
CREATE TABLE dmlocal.prescribing_formatted as
select PATID, YEAR(RX_ORDER_DATE) as EventYear, PRESCRIBINGID, RX_ORDER_DATE, RX_ORDER_TIME, RXNORM_CUI, RX_PROVIDERID, RAW_RX_NDC
from indata.prescribing as P
where P.RX_ORDER_DATE >= &StudyStartDate
	and P.RX_ORDER_DATE < &StudyEndDate
order by PATID, EventYear, RX_ORDER_DATE, RX_ORDER_TIME
;
QUIT;

data dmlocal.prescribing_formatted;
set dmlocal.prescribing_formatted;
  RX_NDC_formatted = compress(RAW_RX_NDC, "0123456789", "k");
run;

* Create SAS data file dmlocal.prescribing_select;
PROC SQL inobs=max;
CREATE TABLE dmlocal.prescribing_select as
select P.*
from dmlocal.prescribing_formatted as P
	left join infolder.opioidcui as CUI
		on P.RXNORM_CUI = CUI.Code
	left join infolder.opioidndc as NDC
		on P.RX_NDC_formatted = NDC.Code
where CUI.Code is not NULL
	or NDC.Code is not NULL
order by P.PATID, P.EventYear, P.RX_ORDER_DATE, P.RX_ORDER_TIME
;
QUIT;

* Create SAS data file dmlocal.prescribe_encounter_filter;
PROC SQL inobs=max;
CREATE TABLE dmlocal.prescribe_encounter_filter as
select ENCOUNTERID, PATID, ADMIT_DATE, ADMIT_TIME
	, DISCHARGE_DATE
	, case
		when DayBefore_DISCHARGE_DATE is NULL then ADMIT_DATE
		when DayBefore_DISCHARGE_DATE < ADMIT_DATE then ADMIT_DATE
		else DayBefore_DISCHARGE_DATE
	  end as DayBefore_DISCHARGE_DATE
	, DISCHARGE_TIME
	, ENC_TYPE
from
(
	select ENCOUNTERID, PATID, ADMIT_DATE, ADMIT_TIME
		, coalesce(DISCHARGE_DATE, ADMIT_DATE) as DISCHARGE_DATE
		, INTNX('day', DISCHARGE_DATE, -1, 'same') as DayBefore_DISCHARGE_DATE
		, DISCHARGE_TIME
		, ENC_TYPE
	from indata.encounter as E
	where ENC_TYPE in ('EI', 'IP')
) as E
order by PATID, ADMIT_DATE, ADMIT_TIME, DayBefore_DISCHARGE_DATE, DISCHARGE_TIME
;
QUIT;

* Create SAS data file dmlocal.prescribing_events;
PROC SQL inobs=max;
CREATE TABLE dmlocal.prescribing_events as
select PS.*
from dmlocal.prescribing_select as PS
	left join dmlocal.prescribe_encounter_filter as EF
		on PS.PATID = EF.PATID
			and PS.RX_ORDER_DATE >= EF.ADMIT_DATE
			and PS.RX_ORDER_DATE <= EF.DayBefore_DISCHARGE_DATE
where EF.PATID is NULL
order by PS.PATID, PS.EventYear, PS.RX_ORDER_DATE, PS.RX_ORDER_TIME
;
QUIT;


data dmlocal.prescribing_events_all;	/*we need a copy of this for another variable*/
  set dmlocal.prescribing_events;
run;

data dmlocal.prescribing_events;
  set dmlocal.prescribing_events;
  by PATID EventYear;
  Seq+1;
  if first.EventYear then Seq=1;
run;

data dmlocal.prescribing_events;
  set dmlocal.prescribing_events;
  where Seq=1;
run;

* Create SAS data file dmlocal.dispensing_events;
PROC SQL inobs=max;
CREATE TABLE dmlocal.dispensing_select as
select PATID, YEAR(DISPENSE_DATE) as EventYear, DISPENSINGID, DISPENSE_DATE, NDC
from indata.dispensing as D
	join infolder.opioidndc as M
		on D.NDC = M.Code
where D.DISPENSE_DATE >= &StudyStartDate
	and D.DISPENSE_DATE < &StudyEndDate
order by PATID, EventYear, DISPENSE_DATE
;
QUIT;

data dmlocal.dispensing_events;
  set dmlocal.dispensing_select;
  by PATID EventYear;
  Seq+1;
  if first.EventYear then Seq=1;
run;

data dmlocal.dispensing_events;
  set dmlocal.dispensing_events;
  where Seq=1;
run;

* Create SAS data file dmlocal.encounter_select;
PROC SQL inobs=max;
CREATE TABLE dmlocal.encounter_select as
select ENCOUNTERID, PATID, ADMIT_DATE, coalesce(DISCHARGE_DATE, ADMIT_DATE) as DISCHARGE_DATE, ENC_TYPE
from indata.encounter
where ENC_TYPE in ('AV', 'IP', 'ED', 'EI', 'OS', 'OA')
order by PATID, ADMIT_DATE, DISCHARGE_DATE, ENC_TYPE
;
QUIT;

* Create SAS data file dmlocal.encounter_events;
PROC SQL inobs=max;
CREATE TABLE dmlocal.encounter_events as
select D.PATID, YEAR(D.ADMIT_DATE) as EventYear, E.ENCOUNTERID, D.ADMIT_DATE, E.ENC_TYPE
from dmlocal.encounter_select as E
	join indata.diagnosis as D
		on E.PATID = D.PATID
			and E.ADMIT_DATE 		<= D.ADMIT_DATE
			and E.DISCHARGE_DATE 	>= D.ADMIT_DATE
where D.ADMIT_DATE >= &StudyStartDate		
	and D.ADMIT_DATE < &StudyEndDate	
order by D.PATID, EventYear, D.ADMIT_DATE
;
QUIT;

data dmlocal.encounter_events;
  set dmlocal.encounter_events;
  by PATID EventYear;
  Seq+1;
  if first.EventYear then Seq=1;
run;

data dmlocal.encounter_events;
  set dmlocal.encounter_events;
  where Seq=1;
run;

* Create SAS data file dmlocal.patientyears;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.patientyears AS
  select PATID, EventYear
  from dmlocal.prescribing_events
  union
  select PATID, EventYear
  from dmlocal.dispensing_events
  union
  select PATID, EventYear
  from dmlocal.encounter_events;
RUN;
QUIT;

* Create SAS data file dmlocal.patientevents;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.patientevents AS
  SELECT PY.*
         , case when P.RX_ORDER_DATE is not null and P.RX_ORDER_DATE < D.DISPENSE_DATE then P.RX_ORDER_DATE
				when D.DISPENSE_DATE is not null then D.DISPENSE_DATE
				when P.RX_ORDER_DATE is not null then P.RX_ORDER_DATE
				else E.ADMIT_DATE
				end as IndexDate
         , P.PRESCRIBINGID, P.RX_ORDER_DATE, P.RX_ORDER_TIME, P.RXNORM_CUI, P.RX_NDC_formatted as Prescribing_NDC, P.RX_PROVIDERID
	     , D.DISPENSINGID, D.DISPENSE_DATE, D.NDC
	     , E.ENCOUNTERID, E.ADMIT_DATE, E.ENC_TYPE
  FROM dmlocal.patientyears as PY
	left join dmlocal.prescribing_events as P
		on PY.PATID = P.PATID
			and PY.EventYear = P.EventYear
	left join dmlocal.dispensing_events as D
		on PY.PATID = D.PATID
			and PY.EventYear = D.EventYear
	left join dmlocal.encounter_events as E
		on PY.PATID = E.PATID
			and PY.EventYear = E.EventYear
  where E.PATID is not NULL					/* Ensuring that patients in the cohort have a diagnostic encounter */
;
RUN;
QUIT;

* Create SAS data file dmlocal.opioid_year_prior;
/*PROC SQL inobs=max;
CREATE TABLE dmlocal.opioid_year_prior as
select PE.PATID, PE.EventYear
	, max(case when PS.PATID is not NULL then 1
		when DS.PATID is not NULL then 1
		else 0
		end) as OpioidInYearPrior
from dmlocal.patientevents as PE
	left join dmlocal.prescribing_events_all as PS
		on PE.PATID = PS.PATID
			and PS.RX_ORDER_DATE <= PE.IndexDate
			and PS.RX_ORDER_DATE >= INTNX('day', PE.IndexDate, -365, 'same')
	left join dmlocal.dispensing_select as DS
		on PE.PATID = DS.PATID
			and DS.DISPENSE_DATE <= PE.IndexDate
			and DS.DISPENSE_DATE >= INTNX('day', PE.IndexDate, -365, 'same')
group by PE.PATID, PE.EventYear
;
RUN;
QUIT;
*/

PROC SQL inobs=max;
  CREATE TABLE dmlocal.facility_select AS
  SELECT PATID, YEAR(ADMIT_DATE) as EventYear, count(*) as Qty, ADMIT_DATE, FACILITY_LOCATION
  FROM indata.encounter
  WHERE FACILITY_LOCATION IS NOT NULL
  GROUP BY PATID, EventYear, FACILITY_LOCATION
  ORDER BY PATID, EventYear, Qty DESC, ADMIT_DATE desc
  ;
RUN;
QUIT;

data dmlocal.facility_select(sortedby=PATID EventYear descending Qty descending ADMIT_DATE);
  set dmlocal.facility_select;
  by PATID EventYear descending Qty descending admit_date;
  RowNum+1;
  if first.EventYear then RowNum=1;
run;

data dmlocal.facility_select;
  set dmlocal.facility_select;
  where RowNum=1;
run;


* Create SAS data file dmlocal.patientdemo;
PROC SQL inobs=max;
CREATE TABLE dmlocal.patientdemo as
select PY.PATID, PY.EventYear
	, DM.RACE, DM.SEX, DM.HISPANIC, DM.BIRTH_DATE
	, D.DEATH_DATE, D.DEATH_SOURCE as DEATH_COMPLETE
	, int(yrdif(DM.BIRTH_DATE, MDY(7, 1, PY.EventYear), 'AGE')) as AgeAsOfJuly1
	, E.FACILITY_LOCATION
from dmlocal.patientyears as PY		/* Just being safe since this is the anchor for the flat file, but maybe not needed. */
	left join dmlocal.facility_select as E
		on PY.PATID = E.PATID
			and PY.EventYear = E.EventYear
	left join indata.demographic as DM
		on PY.PATID = DM.PATID
	left join indata.death as D
		on PY.PATID = D.PATID
;
RUN;
QUIT;


* Create SAS data file dmlocal.ED_Visit_Years;
PROC SQL inobs=max;
CREATE TABLE dmlocal.ED_Visit_Years as
select PATiD, EventYear
from
(
	select PATID, year(ADMIT_DATE) as EventYear
	from indata.encounter as E
	where ENC_TYPE = 'ED'
	union
	select PATID, year(DISCHARGE_DATE) as EventYear
	from indata.encounter as E
	where ENC_TYPE = 'ED'
		and DISCHARGE_DATE is not NULL
) as A
order by PATID, EventYear
;
RUN;
QUIT;

* Create SAS data file dmlocal.IP_Visit_Years;
PROC SQL inobs=max;
CREATE TABLE dmlocal.IP_Visit_Years as
select PATiD, EventYear
from
(
	select PATID, year(ADMIT_DATE) as EventYear
	from indata.encounter as E
	where ENC_TYPE = 'IP'
	union
	select PATID, year(DISCHARGE_DATE) as EventYear
	from indata.encounter as E
	where ENC_TYPE = 'IP'
		and DISCHARGE_DATE is not NULL
) as A
order by PATID, EventYear
;
RUN;
QUIT;


* Create SAS data file dmlocal.cancer_dx_events;
PROC SQL inobs=max;
CREATE TABLE dmlocal.cancer_dx_events as
select PE.PATID
	, PE.EventYear
	, max(case when Ca.Code is not NULL
		and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0 end)
		as Cancer_AnyEncount_Dx_Year_Prior
	/*, max(case when Ca.Code is not NULL
		and Dx.ADMIT_DATE <= PE.IndexDate
		and E.ENC_TYPE in ('IP','EI') then 1 else 0 end)
		as Cancer_Inpt_Dx_Year_Prior*/
	, max(case when Ca.Code is not NULL
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0 end)
		as Cancer_AnyEncount_CY
	, max(case when Ca.Code is not NULL
		and year(Dx.ADMIT_DATE) = PE.EventYear
		and E.ENC_TYPE in  ('IP','EI') then 1 else 0 end)
		as Cancer_Inpt_Dx_CY
from indata.diagnosis as Dx
	join infolder.cancerdx as Ca
		on Dx.DX_TYPE = Ca.DX_TYPE
			and Dx.DX = Ca.Code
	join indata.encounter as E
		on Dx.PATID = E.PATID
			and Dx.ADMIT_DATE >= E.ADMIT_DATE
			and Dx.ADMIT_DATE <= coalesce(E.DISCHARGE_DATE, E.ADMIT_DATE)
	right join dmlocal.patientevents as PE
		on Dx.PATID = PE.PATID
			and Dx.ADMIT_DATE >= INTNX('day', PE.IndexDate, -365, 'same')
			and year(Dx.ADMIT_DATE) <= PE.EventYear
group by PE.PATID, PE.EventYear
order by PE.PATID, PE.EventYear
;
RUN;
QUIT;


* Create SAS data file dmlocal.cancer_proc_events;
/*PROC SQL inobs=max;
CREATE TABLE dmlocal.cancer_proc_events as
select PE.PATID
	, PE.EventYear
	, max(case when Procs.Chemo_Code is not NULL then 1 else 0 end)
		as Chemo_AnyEncount_Year_Prior
	, max(case when Procs.Rad_Code is not NULL then 1 else 0 end)
		as Rad_AnyEncount_Year_Prior
from
(
	select Procs.PATID, Procs.ADMIT_DATE
		, Chemo.Code as Chemo_Code
		, Rad.Code as Rad_Code
	from indata.procedures as Procs
		left join infolder.chemo as Chemo
			on Chemo.PX_TYPE = Procs.PX_TYPE
				and Chemo.Code = Procs.PX
		left join infolder.radiation as Rad
			on Rad.PX_TYPE = Procs.PX_TYPE
				and Rad.Code = Procs.PX
	where Chemo.code is not NULL
		or Rad.Code is not NULL
) as Procs
	right join dmlocal.patientevents as PE
		on PE.PATID = Procs.PATID
			and Procs.ADMIT_DATE <= PE.IndexDate
			and Procs.ADMIT_DATE >= INTNX('day', PE.IndexDate, -365, 'same')
group by PE.PATID, PE.EventYear
order by PE.PATID, PE.EventYear
;
QUIT;
*/

*New -- calendar year data (Chemo_AnyEncount_CY, Rad_AnyEncount_CY);
* Create SAS data file dmlocal.cancer_proc_events_cy;
PROC SQL inobs=max;
CREATE TABLE dmlocal.cancer_proc_events_cy as
select PE.PATID
	, PE.EventYear
	, max(case when Procs.Chemo_Code is not NULL then 1 else 0 end)
		as Chemo_AnyEncount_CY
	, max(case when Procs.Rad_Code is not NULL then 1 else 0 end)
		as Rad_AnyEncount_CY
from
(
	select Procs.PATID, Procs.ADMIT_DATE
		, Chemo.Code as Chemo_Code
		, Rad.Code as Rad_Code
	from indata.procedures as Procs
		left join infolder.chemo as Chemo
			on Chemo.PX_TYPE = Procs.PX_TYPE
				and Chemo.Code = Procs.PX
		left join infolder.radiation as Rad
			on Rad.PX_TYPE = Procs.PX_TYPE
				and Rad.Code = Procs.PX
	where Chemo.code is not NULL
		or Rad.Code is not NULL
) as Procs
	right join dmlocal.patientevents as PE
		on PE.PATID = Procs.PATID
			and year(Procs.ADMIT_DATE) = PE.EventYear
group by PE.PATID, PE.EventYear
order by PE.PATID, PE.EventYear
;
QUIT;


* Create SAS data file dmlocal.first_diag;
PROC SQL inobs=max;
CREATE TABLE dmlocal.first_diag as
select PATID, min(ADMIT_DATE) as FirstDiagEncDate
from indata.diagnosis
where ADMIT_DATE >= &StudyStartDate
	and ADMIT_DATE < &StudyEndDate
group by PATID
order by PATID
;
RUN;
QUIT;


* Create SAS data file dmlocal.first_opioid;
PROC SQL inobs=max;
CREATE TABLE dmlocal.first_opioid as
select OD.PATID,
	min(OD.OpioidDate) as FirstOpioidDate
from 
(
	select PS.PATID, PS.RX_ORDER_DATE as OpioidDate
	from dmlocal.prescribing_events_all as PS
	union all
	select DS.PATID, DS.DISPENSE_DATE as OpioidDate
	from dmlocal.dispensing_select as DS
) as OD
group by OD.PATID
order by OD.PATID
;
RUN;
QUIT;


* Create SAS data file dmlocal.uds_events;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.uds_events AS
  SELECT AGG.PATID
  	, AGG.EventYear
	, max(AGG.UDS_LOINC) as UDS_LOINC
	, max(AGG.UDS_CPT) as UDS_CPT
	, max(AGG.UDS_LOINC_Qty_perYear) as UDS_LOINC_Qty_perYear
	, max(AGG.UDS_CPT_Qty_perYear) as UDS_CPT_Qty_perYear
  FROM
  (
	  SELECT PE.PATID
		, PE.EventYear
		, CASE WHEN UDS_LOINC.EventYear IS NOT NULL THEN 1 ELSE 0
			END AS UDS_LOINC
		, CASE WHEN (UDS_CPT1.EventYear IS NOT NULL OR UDS_CPT2.EventYear IS NOT NULL) THEN 1 ELSE 0
			END AS UDS_CPT
		, count(UDS_LOINC.EventYear) as UDS_LOINC_Qty_perYear
		, count(CASE WHEN (UDS_CPT1.EventYear IS NOT NULL OR UDS_CPT2.EventYear IS NOT NULL) THEN 1 END) as UDS_CPT_Qty_perYear
	  FROM dmlocal.patientevents as PE
	  LEFT JOIN
	  (
		SELECT PE.PATID
			, PE.EventYear
		FROM dmlocal.patientevents as PE
		INNER JOIN indata.lab_result_cm as LAB_L 
		ON PE.PATID = LAB_L.PATID
		INNER JOIN infolder.udsloinc AS UDS 
		ON UDS.Code = LAB_L.LAB_PX 
		WHERE (UDS.Code_System = 'LOINC' AND LAB_L.LAB_PX_TYPE = 'LC') 
			AND LAB_L.RESULT_DATE <= PE.IndexDate
			AND LAB_L.RESULT_DATE >= INTNX('day', PE.IndexDate, -365, 'same')  
		GROUP BY PE.PATID, PE.EventYear) as UDS_LOINC
	  ON PE.PATID = UDS_LOINC.PATID AND PE.EventYear = UDS_LOINC.EventYear

	  LEFT JOIN

	  (
		SELECT PE.PATID
			, PE.EventYear
		FROM dmlocal.patientevents as PE
		INNER JOIN indata.procedures as LAB_P
		ON PE.PATID = LAB_P.PATID
		INNER JOIN infolder.udscpt AS UDS 
		ON UDS.Code = LAB_P.PX 
		WHERE (UDS.Code_System = 'CPT/HCPCS' AND LAB_P.PX_TYPE = 'CH')
			AND LAB_P.ADMIT_DATE <= PE.IndexDate
			AND LAB_P.ADMIT_DATE >= INTNX('day', PE.IndexDate, -365, 'same')  
		GROUP BY PE.PATID, PE.EventYear) as UDS_CPT1
	  ON PE.PATID = UDS_CPT1.PATID AND PE.EventYear = UDS_CPT1.EventYear

	  LEFT JOIN

	  (
		SELECT PE.PATID
			, PE.EventYear
		FROM dmlocal.patientevents as PE
		INNER JOIN indata.lab_result_cm as LAB_L 
		ON PE.PATID = LAB_L.PATID
		INNER JOIN infolder.udscpt AS UDS 
		ON UDS.Code = LAB_L.LAB_PX 
		WHERE (UDS.Code_System = 'CPT/HCPCS' AND LAB_L.LAB_PX_TYPE = 'CH')
			AND LAB_L.RESULT_DATE <= PE.IndexDate
			AND LAB_L.RESULT_DATE >= INTNX('day', PE.IndexDate, -365, 'same')  
		GROUP BY PE.PATID, PE.EventYear) as UDS_CPT2
	  ON PE.PATID = UDS_CPT2.PATID AND PE.EventYear = UDS_CPT2.EventYear
	  group by PE.EventYear
  ) as AGG
  GROUP BY AGG.PATID, AGG.EventYear
  ;
RUN;
QUIT;


* Create SAS data file dmlocal.mental_health_events;
/*PROC SQL inobs=max;
  CREATE TABLE dmlocal.mental_health_events as
  SELECT MH.PATID
	, MH.EventYear
	, MAX(MH.MH_Dx_Pri_Any_Prior) AS MH_Dx_Pri_Any_Prior
	, MAX(MH.MH_Dx_Pri_Year_Prior) AS MH_Dx_Pri_Year_Prior
	, MAX(MH.MH_Dx_Exp_Any_Prior) AS MH_Dx_Exp_Any_Prior
	, MAX(MH.MH_Dx_Exp_Year_Prior) AS MH_Dx_Exp_Year_Prior
  FROM
	(
		select PE.PATID
			, PE.EventYear
			, CASE WHEN MH.Code IS NOT NULL AND MH.Code_Subset = 'Primary' THEN 1 ELSE 0
				END AS MH_Dx_Pri_Any_Prior
			, CASE WHEN (MH.Code IS NOT NULL AND MH.Code_Subset = 'Primary' AND Dx.ADMIT_DATE >= INTNX('day', PE.IndexDate, -365, 'same')) THEN 1 ELSE 0
				END AS MH_Dx_Pri_Year_Prior
			, CASE WHEN MH.Code IS NOT NULL AND MH.Code_Subset = 'Exploratory' THEN 1 ELSE 0 
				END AS MH_Dx_Exp_Any_Prior
			, CASE WHEN (MH.Code IS NOT NULL AND MH.Code_Subset = 'Exploratory' AND Dx.ADMIT_DATE >= INTNX('day', PE.IndexDate, -365, 'same')) THEN 1 ELSE 0
				END AS MH_Dx_Exp_Year_Prior
		from indata.diagnosis AS Dx
			join infolder.mentalhealth as MH 
				on MH.Code = Dx.DX
					and MH.DX_TYPE = Dx.DX_TYPE
			right join dmlocal.patientevents as PE
				on PE.PATID = Dx.PATID
					and Dx.ADMIT_DATE <= PE.IndexDate
	) as MH
  GROUP BY MH.PATID, MH.EventYear
  ;
RUN;
QUIT;
*/

* New -- calendar year data (MH_Dx_Pri_CY, MH_Dx_Exp_CY);
* Create SAS data file dmlocal.mental_health_events_cy;
* NOTE: THIS LOOKS LIKE IT COULD BE COMBINED WITH BLOCK ABOVE;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.mental_health_events_cy as
  SELECT MH.PATID
	, MH.EventYear
	, MAX(MH.MH_Dx_Pri_CY) AS MH_Dx_Pri_CY /*new*/
	, MAX(MH.MH_Dx_Exp_CY) AS MH_Dx_Exp_CY /*new*/
  FROM
	(
		select PE.PATID
			, PE.EventYear
			, CASE WHEN (MH.Code IS NOT NULL AND MH.Code_Subset = 'Primary' AND year(Dx.ADMIT_DATE) = PE.EventYear) THEN 1 ELSE 0
				END AS MH_Dx_Pri_CY
			, CASE WHEN (MH.Code IS NOT NULL AND MH.Code_Subset = 'Exploratory' AND year(Dx.ADMIT_DATE) = PE.EventYear) THEN 1 ELSE 0
				END AS MH_Dx_Exp_CY
		from indata.diagnosis AS Dx
			join infolder.mentalhealth as MH 
				on MH.Code = Dx.DX
					and MH.DX_TYPE = Dx.DX_TYPE
			right join dmlocal.patientevents as PE
				on PE.PATID = Dx.PATID
					and year(Dx.ADMIT_DATE) = PE.EventYear
	) as MH
  GROUP BY MH.PATID, MH.EventYear
  ;
RUN;
QUIT;


* Create SAS data file dmlocal.substance_use_do_events;
*new variables added: Cannabis_UD_Any_CY, Cocaine_UD_Any_CY, Other_Stim_UD_Any_CY, Hallucinogen_UD_Any_CY, Inhalant_UD_Any_CY, SedHypAnx_UD_Any_CY, 
	Opioid_UD_Any_CY, Alcohol_UD_Any_CY, Substance_UD_Any_CY;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.substance_use_do_events AS
select PE.PATID, PE.EventYear
	/*, max(case when SU.Code_List_1 = 'Alcohol Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as Alcohol_Use_DO_Year_Prior*/
	, max(case when SU.Code_List_1 = 'Alcohol Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as Alcohol_Use_DO_Any_Prior
	, min(case when SU.Code_List_1 = 'Alcohol Use Disorder'
		and Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as Alcohol_Use_DO_Post_Date
	, max(case when SU.Code_List_1 = 'Alcohol Use Disorder'
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as Alcohol_UD_Any_CY /*new*/
	/*, max(case when (SU.Code_List_1 = 'Substance Use Disorder' or SU.Code_List_2 = 'Substance Use Disorder')
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as Substance_Use_DO_Year_Prior*/
	, max(case when (SU.Code_List_1 = 'Substance Use Disorder' or SU.Code_List_2 = 'Substance Use Disorder')
		and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as Substance_Use_DO_Any_Prior
	, min(case when (SU.Code_List_1 = 'Substance Use Disorder' or SU.Code_List_2 = 'Substance Use Disorder')
		and Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as Substance_Use_DO_Post_Date
	, max(case when (SU.Code_List_1 = 'Substance Use Disorder' or SU.Code_List_2 = 'Substance Use Disorder')
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as Substance_UD_Any_CY /*new*/
	/*, max(case when SU.Code_List_1 = 'Opioid Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as Opioid_Use_DO_Year_Prior*/
	, max(case when SU.Code_List_1 = 'Opioid Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as Opioid_Use_DO_Any_Prior
	, min(case when SU.Code_List_1 = 'Opioid Use Disorder'
		and Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as Opioid_Use_DO_Post_Date
	, max(case when SU.Code_List_1 = 'Opioid Use Disorder'
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as Opioid_UD_Any_CY /*new*/
	, max(case when SU.Code_List_1 = 'Opioid Use Disorder'
		and Dx.ADMIT_DATE is not NULL
		and Year(Dx.ADMIT_DATE) < PE.EventYear then 1 else 0
		end) as Opioid_UDO_Prior_NotInc_CY
	/*, max(case when SU.Code_List_2 = 'Cannabis Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as Cannabis_Use_DO_Year_Prior*/
	, max(case when SU.Code_List_2 = 'Cannabis Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as Cannabis_Use_DO_Any_Prior
	, min(case when SU.Code_List_2 = 'Cannabis Use Disorder'
		and Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as Cannabis_Use_DO_Post_Date
	, max(case when SU.Code_List_2 = 'Cannabis Use Disorder'
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as Cannabis_UD_Any_CY /*new*/
	/*, max(case when SU.Code_List_2 = 'Cocaine Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as Cocaine_Use_DO_Year_Prior*/
	, max(case when SU.Code_List_2 = 'Cocaine Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as Cocaine_Use_DO_Any_Prior
	, min(case when SU.Code_List_2 = 'Cocaine Use Disorder'
		and Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as Cocaine_Use_DO_Post_Date
	, max(case when SU.Code_List_2 = 'Cocaine Use Disorder'
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as Cocaine_UD_Any_CY /*new*/
	, max(case when SU.Code_List_2 = 'Hallucinogen Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as Hallucinogen_Use_DO_Year_Prior
	, max(case when SU.Code_List_2 = 'Hallucinogen Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as Hallucinogen_Use_DO_Any_Prior
	, min(case when SU.Code_List_2 = 'Hallucinogen Use Disorder'
		and Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as Hallucinogen_Use_DO_Post_Date
	, max(case when SU.Code_List_2 = 'Hallucinogen Use Disorder'
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as Hallucinogen_UD_Any_CY /*new*/
	/*, max(case when SU.Code_List_2 = 'Inhalant Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as Inhalant_Use_DO_Year_Prior*/
	, max(case when SU.Code_List_2 = 'Inhalant Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as Inhalant_Use_DO_Any_Prior
	, min(case when SU.Code_List_2 = 'Inhalant Use Disorder'
		and Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as Inhalant_Use_DO_Post_Date
	, max(case when SU.Code_List_2 = 'Inhalant Use Disorder'
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as Inhalant_UD_Any_CY /*new*/
	/*, max(case when SU.Code_List_2 = 'Other Stimulant Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as Other_Stim_Use_DO_Year_Prior*/
	, max(case when SU.Code_List_2 = 'Other Stimulant Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as Other_Stim_Use_DO_Any_Prior
	, min(case when SU.Code_List_2 = 'Other Stimulant Use Disorder'
		and Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as Other_Stim_Use_DO_Post_Date
	, max(case when SU.Code_List_2 = 'Other Stimulant Use Disorder'
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as Other_Stim_UD_Any_CY /*new*/
	/*, max(case when SU.Code_List_2 = 'S/H/A Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as SedHypAnx_Use_DO_Year_Prior*/
	, max(case when SU.Code_List_2 = 'S/H/A Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as SedHypAnx_Use_DO_Any_Prior
	, min(case when SU.Code_List_2 = 'S/H/A Use Disorder'
		and Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as SedHypAnx_Use_DO_Post_Date
	, max(case when SU.Code_List_2 = 'S/H/A Use Disorder'
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as SedHypAnx_UD_Any_CY /*new*/
from indata.DIAGNOSIS as Dx
	join infolder.substanceusedisorder as SU
		on SU.Code = Dx.DX 
			and Su.DX_TYPE = Dx.DX_TYPE
	right join
	(
		select PATID, EventYear, IndexDate, INTNX('day', IndexDate, -365, 'same') as YearPriorDate
		from dmlocal.patientevents
	) as PE
		on PE.PATID = Dx.PATID
group by PE.PATID, PE.EventYear
  ;
RUN;
QUIT;



* New--Create SAS data file dmlocal.substance_use_do_events_ever;
*new variables added: Opioid_UD_Any_everCY, Alcohol_UD_Any_everCY, Substance_UD_Any_everCY, OUD_SUD_everCY, Substance_UD_Any_CY, Opioid_UD_Any_CY, OUD_SUD_CY ;
* NOTE: THIS LOOKS LIKE IT COULD BE COMBINED WITH BLOCK ABOVE;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.substance_use_do_events_ever AS
  select patid, eventyear, max(Alcohol_UD_Any_everCY ) as Alcohol_UD_Any_everCY ,
  		max(Substance_UD_Any_everCY) as Substance_UD_Any_everCY,
		max(Opioid_UD_Any_everCY) as Opioid_UD_Any_everCY,
		max(OUD_SUD_everCY) as OUD_SUD_everCY,
		max(max(Substance_UD_Any_CY, Opioid_UD_Any_CY)) as OUD_SUD_CY /*new*/
  from 
(select PE.PATID, PE.EventYear
	, case when SU.Code_List_1 = 'Alcohol Use Disorder'
		and year(min(Dx.ADMIT_DATE)) <= PE.EventYear then 1 else 0
		end as Alcohol_UD_Any_everCY /*new*/
	, case when (SU.Code_List_1 = 'Substance Use Disorder' or SU.Code_List_2 = 'Substance Use Disorder')
		and year(min(Dx.ADMIT_DATE)) <= PE.EventYear then 1 else 0
		end as Substance_UD_Any_everCY /*new*/
	, case when SU.Code_List_1 = 'Opioid Use Disorder'
		and year(min(Dx.ADMIT_DATE)) <= PE.EventYear then 1 else 0
		end as Opioid_UD_Any_everCY /*new*/
	, max(calculated Substance_UD_Any_everCY, calculated Opioid_UD_Any_everCY)
		as OUD_SUD_everCY /*new*/
	, case when (SU.Code_List_1 = 'Substance Use Disorder' or SU.Code_List_2 = 'Substance Use Disorder')
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end as Substance_UD_Any_CY /*new*/
	, case when SU.Code_List_1 = 'Opioid Use Disorder'
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end as Opioid_UD_Any_CY /*new*/
from indata.DIAGNOSIS as Dx
	join infolder.substanceusedisorder as SU
		on SU.Code = Dx.DX 
			and Su.DX_TYPE = Dx.DX_TYPE
	right join
	(
		select PATID, EventYear, IndexDate, INTNX('day', IndexDate, -365, 'same') as YearPriorDate
		from dmlocal.patientevents
	) as PE
		on PE.PATID = Dx.PATID
group by PE.PATID)
group by PATID, EventYear
  ;
QUIT;


* Create SAS data file rcr.hepb_events;
*new variables added: HepB_Dx_Any_CY;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.hepb_events AS
select PE.PATID
	, PE.EventYear
	/*, max(case when Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as HepB_Dx_Year_Prior*/
	/*, max(case when Dx.ADMIT_DATE IS NOT NULL and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0 
		end) as HepB_Dx_Any_Prior*/   								/* null exclusion added by SKP 3/6/2019 */
	, min(case when Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as HepB_Dx_Post_Date
	, max(case when Dx.ADMIT_DATE IS NOT NULL and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0  /*new--null exclusion kept*/
		end) as HepB_Dx_Any_CY 
from indata.diagnosis as Dx
	join infolder.HepB as HB
		on HB.Code = Dx.DX
			and HB.DX_TYPE = Dx.DX_TYPE
	right join
	(
		select PATID, EventYear, IndexDate, INTNX('day', IndexDate, -365, 'same') as YearPriorDate
		from dmlocal.PatientEvents
	) as PE
		on PE.PATID = Dx.PATID
group by PE.PATID, PE.EventYear
;
RUN;
QUIT;


* New--Create SAS data file rcr.hepb_events_ever;
*new variables added: HepB_Dx_Any_everCY;
* NOTE: THIS LOOKS LIKE IT COULD BE COMBINED WITH BLOCK ABOVE;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.hepb_events_ever AS
  select distinct PE.PATID
	, PE.EventYear
	/*, case when .<year(min(Dx.ADMIT_DATE)) <= PE.EventYear then 1 else 0*/  /*new*/
		/*end as HepB_Dx_Any_everCY */
from indata.diagnosis as Dx
	join infolder.HepB as HB
		on HB.Code = Dx.DX
			and HB.DX_TYPE = Dx.DX_TYPE
	right join
	(
		select PATID, EventYear, IndexDate, INTNX('day', IndexDate, -365, 'same') as YearPriorDate
		from dmlocal.PatientEvents
	) as PE
		on PE.PATID = Dx.PATID
group by PE.PATID
;
RUN;
QUIT;



* Create SAS data file dmlocal.hepc_events;
*new variables added: HepC_Dx_Any_CY ;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.hepc_events AS
select PE.PATID
	, PE.EventYear
	/*, max(case when Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE > PE.YearPriorDate then 1 else 0
		end) as HepC_Dx_Year_Prior*/
	/*, max(case when Dx.ADMIT_DATE IS NOT NULL and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0 
		end) as HepC_Dx_Any_Prior*/  								/* null exclusion added by SKP 3/6/2019 */
	, min(case when Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as HepC_Dx_Post_Date
	, max(case when Dx.ADMIT_DATE IS NOT NULL and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0  /*new--null exclusion kept*/
		end) as HepC_Dx_Any_CY 	
from indata.DIAGNOSIS as Dx
	join infolder.HepC as HC
		on HC.Code = Dx.DX
			and HC.DX_TYPE = Dx.DX_TYPE
	right join
	(
		select PATID, EventYear, IndexDate, INTNX('day', IndexDate, -365, 'same') as YearPriorDate
		from dmlocal.PatientEvents
	) as PE
		on PE.PATID = Dx.PATID
group by PE.PATID, PE.EventYear
;
RUN;
QUIT;




* New--Create SAS data file dmlocal.hepc_events_ever;
*new variables added: HepC_Dx_Any_everCY ;
* NOTE: THIS LOOKS LIKE IT COULD BE COMBINED WITH BLOCK ABOVE;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.hepc_events_ever AS
  select distinct PE.PATID
	, PE.EventYear
	/*, case when .<year(min(Dx.ADMIT_DATE)) <= PE.EventYear then 1 else 0*/  /*new*/
		/*end as HepC_Dx_Any_everCY */
from indata.DIAGNOSIS as Dx
	join infolder.HepC as HC
		on HC.Code = Dx.DX
			and HC.DX_TYPE = Dx.DX_TYPE
	right join
	(
		select PATID, EventYear, IndexDate, INTNX('day', IndexDate, -365, 'same') as YearPriorDate
		from dmlocal.PatientEvents
	) as PE
		on PE.PATID = Dx.PATID
group by PE.PATID
;
RUN;
QUIT;



* Create SAS data file dmlocal.hiv_events;
*new variables added: HIV_Dx_Any_CY;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.hiv_events AS
select PE.PATID
	, PE.EventYear
	/*, max(case when Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as HIV_Dx_Year_Prior*/
	/*, max(case when Dx.ADMIT_DATE IS NOT NULL and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as HIV_Dx_Any_Prior 	*/							/* null exclusion added by SKP 3/6/2019 */
	, min(case when Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as HIV_Dx_Post_Date
	, max(case when Dx.ADMIT_DATE IS NOT NULL and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as HIV_Dx_Any_CY  /*new*/
from indata.DIAGNOSIS as Dx
	join infolder.HIV as HIV
		on HIV.Code = Dx.DX
			and HIV.DX_TYPE = Dx.DX_TYPE
	right join
	(
		select PATID, EventYear, IndexDate, INTNX('day', IndexDate, -365, 'same') as YearPriorDate
		from dmlocal.PatientEvents
	) as PE
		on PE.PATID = Dx.PATID
group by PE.PATID, PE.EventYear
;
RUN;
QUIT;


* New--Create SAS data file dmlocal.hiv_events_ever;
*new variables added: HIV_Dx_Any_everCY ;
* NOTE: THIS LOOKS LIKE IT COULD BE COMBINED WITH BLOCK ABOVE;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.hiv_events_ever AS
  select distinct PE.PATID
	, PE.EventYear
/*	, case when .<year(min(Dx.ADMIT_DATE)) <= PE.EventYear then 1 else 0
		end as HIV_Dx_Any_everCY*/  /*new*/
from indata.DIAGNOSIS as Dx
	join infolder.HIV as HIV
		on HIV.Code = Dx.DX
			and HIV.DX_TYPE = Dx.DX_TYPE
	right join
	(
		select PATID, EventYear, IndexDate, INTNX('day', IndexDate, -365, 'same') as YearPriorDate
		from dmlocal.PatientEvents
	) as PE
		on PE.PATID = Dx.PATID
group by PE.PATID
;
RUN;
QUIT;


* Create SAS data file dmlocal.bup_events;
/*
PROC SQL inobs=max;
CREATE TABLE dmlocal.bup_events as
select PE.PATID
	, PE.EventYear
	, MAX(CASE WHEN PRESC.RX_ORDER_DATE IS NOT NULL and PRESC.RX_ORDER_DATE <= PE.IndexDate then 1 else 0 
	  end) as BUP_PRESC_PRE
	, MAX(CASE WHEN PRESC.RX_ORDER_DATE IS NOT NULL and PRESC.RX_ORDER_DATE <= PE.IndexDate then PRESC.RX_ORDER_DATE 
      end) as BUP_PRESC_PRE_DATE
	, MAX(CASE WHEN PRESC.RX_ORDER_DATE >= PE.IndexDate then 1 else 0 
	  end) as BUP_PRESC_POST
	, MIN(CASE WHEN PRESC.RX_ORDER_DATE >= PE.IndexDate then PRESC.RX_ORDER_DATE 
	  end) as BUP_PRESC_POST_DATE
	, MAX(CASE WHEN DISP.DISPENSE_DATE IS NOT NULL and DISP.DISPENSE_DATE <= PE.IndexDate then 1 else 0 
	  end) as BUP_DISP_PRE
	, MAX(CASE WHEN DISP.DISPENSE_DATE IS NOT NULL and DISP.DISPENSE_DATE <= PE.IndexDate then DISP.DISPENSE_DATE 
	  end) as BUP_DISP_PRE_DATE
	, MAX(CASE WHEN DISP.DISPENSE_DATE >= PE.IndexDate then 1 else 0 
	  end) as BUP_DISP_POST
	, MIN(CASE WHEN DISP.DISPENSE_DATE >= PE.IndexDate then DISP.DISPENSE_DATE 
	  end) as BUP_DISP_POST_DATE
from dmlocal.patientevents as PE*/		/* handle data for missing patients */
	/*left join
	(
		select PE.PATID
			, PE.EventYear
			, PRESC.RX_ORDER_DATE 
		from indata.prescribing as PRESC
			join infolder.benzocui as CUI
				on CUI.Code = PRESC.RXNORM_CUI
			join dmlocal.patientevents as PE
				on PE.PATID = PRESC.PATID
					and PRESC.RX_ORDER_DATE <= INTNX('day', PE.IndexDate, 365, 'same')
					and PRESC.RX_ORDER_DATE >= INTNX('day', PE.IndexDate, -365, 'same')
		group by PE.PATID, PE.EventYear
	) as PRESC
		on PE.PATID = PRESC.PATID and PE.EventYear = PRESC.EventYear
	left join
	(
		select PE.PATID
			, PE.EventYear
			, DISP.DISPENSE_DATE 
		from indata.dispensing as DISP
			join infolder.benzondc as NDC
				on NDC.Code = DISP.NDC
			join dmlocal.patientevents as PE
				on PE.PATID = DISP.PATID
					and DISP.DISPENSE_DATE <= INTNX('day', PE.IndexDate, 365, 'same')
					and DISP.DISPENSE_DATE >= INTNX('day', PE.IndexDate, -365, 'same')
		group by PE.PATID, PE.EventYear
	) as DISP
		on PE.PATID = DISP.PATID and PE.EventYear = DISP.EventYear
	GROUP BY PE.PATID, PE.EventYear
	;
RUN;
QUIT;
*/

* New -- calendar year data (BUP_PRESC_CY, BUP_DISP_CY);
* Create SAS data file dmlocal.bup_events_cy;
* NOTE: THIS LOOKS LIKE IT COULD BE COMBINED WITH BLOCK ABOVE;
PROC SQL inobs=max;
CREATE TABLE dmlocal.bup_events_cy as
select PE.PATID
	, PE.EventYear
	, MAX(CASE WHEN PRESC.RX_ORDER_DATE IS NOT NULL and year(PRESC.RX_ORDER_DATE) = PE.EventYear then 1 else 0 
	  end) as BUP_PRESC_CY /*new*/
	, MAX(CASE WHEN DISP.DISPENSE_DATE IS NOT NULL and year(DISP.DISPENSE_DATE) = PE.EventYear then 1 else 0 
	  end) as BUP_DISP_CY /*new*/
from dmlocal.patientevents as PE		/* handle data for missing patients */
	left join
	(
		select PE.PATID
			, PE.EventYear
			, PRESC.RX_ORDER_DATE 
		from indata.prescribing as PRESC
			join infolder.benzocui as CUI
				on CUI.Code = PRESC.RXNORM_CUI
			join dmlocal.patientevents as PE
				on PE.PATID = PRESC.PATID
					and year(PRESC.RX_ORDER_DATE) = PE.EventYear
		group by PE.PATID, PE.EventYear
	) as PRESC
		on PE.PATID = PRESC.PATID and PE.EventYear = PRESC.EventYear
	left join
	(
		select PE.PATID
			, PE.EventYear
			, DISP.DISPENSE_DATE 
		from indata.dispensing as DISP
			join infolder.benzondc as NDC
				on NDC.Code = DISP.NDC
			join dmlocal.patientevents as PE
				on PE.PATID = DISP.PATID
					and year(DISP.DISPENSE_DATE) = PE.EventYear
		group by PE.PATID, PE.EventYear
	) as DISP
		on PE.PATID = DISP.PATID and PE.EventYear = DISP.EventYear
	GROUP BY PE.PATID, PE.EventYear
	;
RUN;
QUIT;




* New -- calendar year data (BUP_PRESC_everCY, BUP_DISP_everCY);
* Create SAS data file dmlocal.bup_events_ever;
PROC SQL inobs=max;
CREATE TABLE dmlocal.bup_events_ever as
select distinct PE.PATID
	, PE.EventYear
	, CASE WHEN .<year(min(PRESC.RX_ORDER_DATE)) <= PE.EventYear then 1 else 0 
	  end as BUP_PRESC_everCY /*new*/
	, CASE WHEN  .<year(min(DISP.DISPENSE_DATE)) <= PE.EventYear then 1 else 0 
	  end as BUP_DISP_everCY /*new*/
from dmlocal.patientevents as PE		/* handle data for missing patients */
	left join
	(
		select PE.PATID
			, PE.EventYear
			, PRESC.RX_ORDER_DATE 
		from indata.prescribing as PRESC
			join infolder.benzocui as CUI
				on CUI.Code = PRESC.RXNORM_CUI
			join dmlocal.patientevents as PE
				on PE.PATID = PRESC.PATID
					and year(PRESC.RX_ORDER_DATE) = PE.EventYear
		group by PE.PATID, PE.EventYear
	) as PRESC
		on PE.PATID = PRESC.PATID and PE.EventYear = PRESC.EventYear
	left join
	(
		select PE.PATID
			, PE.EventYear
			, DISP.DISPENSE_DATE 
		from indata.dispensing as DISP
			join infolder.benzondc as NDC
				on NDC.Code = DISP.NDC
			join dmlocal.patientevents as PE
				on PE.PATID = DISP.PATID
					and year(DISP.DISPENSE_DATE) = PE.EventYear
		group by PE.PATID, PE.EventYear
	) as DISP
		on PE.PATID = DISP.PATID and PE.EventYear = DISP.EventYear
	GROUP BY PE.PATID
	;
RUN;
QUIT;


* Create SAS data file dmlocal.naltrex_events;
/*PROC SQL inobs=max;
CREATE TABLE dmlocal.naltrex_events as
select PE.PATID
	, PE.EventYear
	, max(case when PRESC.RX_ORDER_DATE IS NOT NULL and PRESC.RX_ORDER_DATE <= PE.IndexDate then 1 else 0 
	  end) as NALTREX_PRESC_PRE
	, max(case when PRESC.RX_ORDER_DATE IS NOT NULL and PRESC.RX_ORDER_DATE <= PE.IndexDate then PRESC.RX_ORDER_DATE 
	  end) as NALTREX_PRESC_PRE_DATE
	, max(case when PRESC.RX_ORDER_DATE >= PE.IndexDate then 1 else 0 
	  end) as NALTREX_PRESC_POST
	, min(case when PRESC.RX_ORDER_DATE >= PE.IndexDate then PRESC.RX_ORDER_DATE 
	  end) 	as NALTREX_PRESC_POST_DATE
	, max(case when DISP.DISPENSE_DATE IS NOT NULL and DISP.DISPENSE_DATE <= PE.IndexDate then 1 else 0 
	  end) as NALTREX_DISP_PRE
	, max(case when DISP.DISPENSE_DATE IS NOT NULL and DISP.DISPENSE_DATE <= PE.IndexDate then DISP.DISPENSE_DATE 
	  end) as NALTREX_DISP_PRE_DATE
	, max(case when DISP.DISPENSE_DATE >= PE.IndexDate then 1 else 0 
	  end) as NALTREX_DISP_POST
	, min(case when DISP.DISPENSE_DATE >= PE.IndexDate then DISP.DISPENSE_DATE 
	  end) as NALTREX_DISP_POST_DATE
from dmlocal.patientevents as PE*/		/* handle data for missing patients */
/*	left join
	(
		select PE.PATID
			, PE.EventYear
			, PRESC.RX_ORDER_DATE
		from indata.prescribing as PRESC
			join infolder.naltrexonecui as CUI
				on CUI.Code = PRESC.RXNORM_CUI
			join dmlocal.patientevents as PE
				on PE.PATID = PRESC.PATID
					and PRESC.RX_ORDER_DATE <= INTNX('day', PE.IndexDate, 365, 'same')
					and PRESC.RX_ORDER_DATE >= INTNX('day', PE.IndexDate, -365, 'same')
		group by PE.PATID, PE.EventYear
	) as PRESC
		on PE.PATID = PRESC.PATID and PE.EventYear = PRESC.EventYear
	left join
	(
		select PE.PATID
			, PE.EventYear
			, DISP.DISPENSE_DATE
		from indata.dispensing as DISP
			join infolder.naltrexonendc as NDC
				on NDC.Code = DISP.NDC
			join dmlocal.patientevents as PE
				on PE.PATID = DISP.PATID
					and DISP.DISPENSE_DATE <= INTNX('day', PE.IndexDate, 365, 'same')
					and DISP.DISPENSE_DATE >= INTNX('day', PE.IndexDate, -365, 'same')
		group by PE.PATID, PE.EventYear
	) as DISP
		on PE.PATID = DISP.PATID and PE.EventYear = DISP.EventYear
	GROUP BY PE.PATID, PE.EventYear
  ;
RUN;
QUIT;
*/

* New -- calendar year data (NALTREX_PRESC_CY, NALTREX_DISP_CY);
* Create SAS data file dmlocal.naltrex_events_cy;
* NOTE: THIS LOOKS LIKE IT COULD BE COMBINED WITH BLOCK ABOVE;
PROC SQL inobs=max;
CREATE TABLE dmlocal.naltrex_events_cy as
select PE.PATID
	, PE.EventYear
	, max(case when PRESC.RX_ORDER_DATE IS NOT NULL and year(PRESC.RX_ORDER_DATE) = PE.EventYear then 1 else 0 
	  end) as NALTREX_PRESC_CY /*new*/
	, max(case when DISP.DISPENSE_DATE IS NOT NULL and year(DISP.DISPENSE_DATE) = PE.EventYear then 1 else 0 
	  end) as NALTREX_DISP_CY /*new*/
from dmlocal.patientevents as PE		/* handle data for missing patients */
	left join
	(
		select PE.PATID
			, PE.EventYear
			, PRESC.RX_ORDER_DATE
		from indata.prescribing as PRESC
			join infolder.naltrexonecui as CUI
				on CUI.Code = PRESC.RXNORM_CUI
			join dmlocal.patientevents as PE
				on PE.PATID = PRESC.PATID
					and year(PRESC.RX_ORDER_DATE) = PE.EventYear
		group by PE.PATID, PE.EventYear
	) as PRESC
		on PE.PATID = PRESC.PATID and PE.EventYear = PRESC.EventYear
	left join
	(
		select PE.PATID
			, PE.EventYear
			, DISP.DISPENSE_DATE
		from indata.dispensing as DISP
			join infolder.naltrexonendc as NDC
				on NDC.Code = DISP.NDC
			join dmlocal.patientevents as PE
				on PE.PATID = DISP.PATID
					and year(DISP.DISPENSE_DATE) = PE.EventYear
		group by PE.PATID, PE.EventYear
	) as DISP
		on PE.PATID = DISP.PATID and PE.EventYear = DISP.EventYear
	GROUP BY PE.PATID, PE.EventYear
  ;
RUN;
QUIT;



* New -- calendar year data (NALTREX_PRESC_everCY, NALTREX_DISP_everCY);
* Create SAS data file dmlocal.naltrex_events_ever;
PROC SQL inobs=max;
CREATE TABLE dmlocal.naltrex_events_ever as
 select distinct PE.PATID
	, PE.EventYear
	, case when .<year(min(PRESC.RX_ORDER_DATE)) <= PE.EventYear then 1 else 0 
	  end as NALTREX_PRESC_everCY /*new*/
	, case when .<year(min(DISP.DISPENSE_DATE)) <= PE.EventYear then 1 else 0 
	  end as NALTREX_DISP_everCY /*new*/
from dmlocal.patientevents as PE		/* handle data for missing patients */
	left join
	(
		select PE.PATID
			, PE.EventYear
			, PRESC.RX_ORDER_DATE
		from indata.prescribing as PRESC
			join infolder.naltrexonecui as CUI
				on CUI.Code = PRESC.RXNORM_CUI
			join dmlocal.patientevents as PE
				on PE.PATID = PRESC.PATID
					and year(PRESC.RX_ORDER_DATE) = PE.EventYear
		group by PE.PATID, PE.EventYear
	) as PRESC
		on PE.PATID = PRESC.PATID and PE.EventYear = PRESC.EventYear
	left join
	(
		select PE.PATID
			, PE.EventYear
			, DISP.DISPENSE_DATE
		from indata.dispensing as DISP
			join infolder.naltrexonendc as NDC
				on NDC.Code = DISP.NDC
			join dmlocal.patientevents as PE
				on PE.PATID = DISP.PATID
					and year(DISP.DISPENSE_DATE) = PE.EventYear
		group by PE.PATID, PE.EventYear
	) as DISP
		on PE.PATID = DISP.PATID and PE.EventYear = DISP.EventYear
	GROUP BY PE.PATID
  ;
RUN;
QUIT;

* Create SAS data file dmlocal.methadone_events;
/*PROC SQL inobs=max;
CREATE TABLE dmlocal.methadone_events as
select PE.PATID
	, PE.EventYear
	, max(case when PRESC.RX_ORDER_DATE IS NOT NULL and PRESC.RX_ORDER_DATE <= PE.IndexDate then 1 else 0 
	  end) as METHADONE_PRESC_PRE
	, max(case when PRESC.RX_ORDER_DATE IS NOT NULL and PRESC.RX_ORDER_DATE <= PE.IndexDate then PRESC.RX_ORDER_DATE 
	  end) as METHADONE_PRESC_PRE_DATE
	, max(case when PRESC.RX_ORDER_DATE >= PE.IndexDate then 1 else 0 
	  end) as METHADONE_PRESC_POST
	, min(case when PRESC.RX_ORDER_DATE >= PE.IndexDate then PRESC.RX_ORDER_DATE 
	  end) as METHADONE_PRESC_POST_DATE	
	, max(case when DISP.DISPENSE_DATE IS NOT NULL and DISP.DISPENSE_DATE <= PE.IndexDate then 1 else 0 
	  end) as METHADONE_DISP_PRE
	, max(case when DISP.DISPENSE_DATE IS NOT NULL and DISP.DISPENSE_DATE <= PE.IndexDate then DISP.DISPENSE_DATE 
	  end) as METHADONE_DISP_PRE_DATE
	, max(case when DISP.DISPENSE_DATE >= PE.IndexDate then 1 else 0 
	  end) as METHADONE_DISP_POST
	, min(case when DISP.DISPENSE_DATE >= PE.IndexDate then DISP.DISPENSE_DATE 
	  end) as METHADONE_DISP_POST_DATE
from dmlocal.patientevents as PE*/			/* handle data for missing patients */
	/*left join
	(
		select PE.PATID
			, PE.EventYear
			, PRESC.RX_ORDER_DATE 
		from indata.prescribing as PRESC
			join infolder.methadonecui as CUI
				on CUI.Code = PRESC.RXNORM_CUI
			join dmlocal.patientevents as PE
				on PE.PATID = PRESC.PATID
					and PRESC.RX_ORDER_DATE <= INTNX('day', PE.IndexDate, 365, 'same')
					and PRESC.RX_ORDER_DATE >= INTNX('day', PE.IndexDate, -365, 'same')
		group by PE.PATID, PE.EventYear
	) as PRESC
		on PE.PATID = PRESC.PATID and PE.EventYear = PRESC.EventYear
	left join
	(
		select PE.PATID
			, PE.EventYear
			, DISP.DISPENSE_DATE 
		from indata.dispensing as DISP
			join infolder.methadonendc as NDC
				on NDC.Code = DISP.NDC
			join dmlocal.patientevents as PE
				on PE.PATID = DISP.PATID
					and DISP.DISPENSE_DATE <= INTNX('day', PE.IndexDate, 365, 'same')
					and DISP.DISPENSE_DATE >= INTNX('day', PE.IndexDate, -365, 'same')
		group by PE.PATID, PE.EventYear
	) as DISP
		on PE.PATID = DISP.PATID and PE.EventYear = DISP.EventYear
	GROUP BY PE.PATID, PE.EventYear
  ;
RUN;
QUIT;
*/

* New -- calendar year data (METHADONE_ANY_CY);
* Create SAS data file dmlocal.methadone_events_cy;
* NOTE: THIS LOOKS LIKE IT COULD BE COMBINED WITH BLOCK ABOVE;
PROC SQL inobs=max;
CREATE TABLE dmlocal.methadone_events_cy as
select PE.PATID
	, PE.EventYear
	/*, max(case when PRESC.RX_ORDER_DATE IS NOT NULL and (year(PRESC.RX_ORDER_DATE) = PE.IndexDate or year(DISP.DISPENSE_DATE) = PE.IndexDate) then 1 else 0 
	  end) as METHADONE_ANY_CY*/ /*new*/
from dmlocal.patientevents as PE			/* handle data for missing patients */
	left join
	(
		select PE.PATID
			, PE.EventYear
			, PRESC.RX_ORDER_DATE 
		from indata.prescribing as PRESC
			join infolder.methadonecui as CUI
				on CUI.Code = PRESC.RXNORM_CUI
			join dmlocal.patientevents as PE
				on PE.PATID = PRESC.PATID
					and year(PRESC.RX_ORDER_DATE) = PE.EventYear
		group by PE.PATID, PE.EventYear
	) as PRESC
		on PE.PATID = PRESC.PATID and PE.EventYear = PRESC.EventYear
	left join
	(
		select PE.PATID
			, PE.EventYear
			, DISP.DISPENSE_DATE 
		from indata.dispensing as DISP
			join infolder.methadonendc as NDC
				on NDC.Code = DISP.NDC
			join dmlocal.patientevents as PE
				on PE.PATID = DISP.PATID
					and year(DISP.DISPENSE_DATE) = PE.EventYear
		group by PE.PATID, PE.EventYear
	) as DISP
		on PE.PATID = DISP.PATID and PE.EventYear = DISP.EventYear
	GROUP BY PE.PATID, PE.EventYear
  ;
RUN;
QUIT;


* Create SAS data file dmlocal.bdz_events;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.bdz_events AS
  SELECT PE.PATID
	, PE.EventYear
	, MAX(CASE WHEN PRESC.EventYear is not NULL or DISP.EventYear is not NULL THEN 1 ELSE 0
		END) AS BDZ_CY
	/*, MAX(CASE WHEN PRESC.EventYear IS NOT NULL THEN 1 ELSE 0
		END) AS BDZ_Presc_3mo
	, MAX(CASE WHEN DISP.EventYear IS NOT NULL THEN 1 ELSE 0
		END) AS BDZ_Disp_3mo*/
  FROM dmlocal.patientevents as PE
  LEFT JOIN
	(
		SELECT PE.PATID
		, PE.EventYear
		FROM dmlocal.patientevents as PE
		INNER JOIN indata.prescribing as PRESC
		ON PE.PATID = PRESC.PATID
		INNER JOIN infolder.benzocui as CUI
		ON CUI.Code = PRESC.RXNORM_CUI
		WHERE year(PRESC.RX_ORDER_DATE) = PE.EventYear
		GROUP BY PE.PATID, PE.EventYear 
	) as PRESC
  ON PE.PATID = PRESC.PATID AND PE.EventYear = PRESC.EventYear
  LEFT JOIN
	(
		SELECT PE.PATID
		, PE.EventYear
		FROM dmlocal.patientevents as PE
		INNER JOIN indata.dispensing as DISP
		ON PE.PATID = DISP.PATID
		INNER JOIN infolder.benzondc as NDC
		ON NDC.Code = DISP.NDC
		WHERE year(DISP.DISPENSE_DATE) = PE.EventYear
		GROUP BY PE.PATID, PE.EventYear 
	) as DISP
  ON PE.PATID = DISP.PATID AND PE.EventYear = DISP.EventYear
  GROUP BY PE.PATID, PE.EventYear
  ;
RUN;
QUIT;


* Create SAS data file dmlocal.nalox_encounter_filter;
PROC SQL inobs=max;
CREATE TABLE dmlocal.nalox_encounter_filter as
select ENCOUNTERID, PATID, ADMIT_DATE, ADMIT_TIME, coalesce(DISCHARGE_DATE, ADMIT_DATE) as DISCHARGE_DATE, DISCHARGE_TIME, ENC_TYPE
from indata.encounter as E
where ENC_TYPE in ('EI', 'ED')
order by PATID, ADMIT_DATE, ADMIT_TIME, DISCHARGE_DATE, DISCHARGE_TIME
;
RUN;
QUIT;


* Create SAS data file dmlocal.nalox_presc;
PROC SQL inobs=max;
CREATE TABLE dmlocal.nalox_presc as
select distinct PRESC.PATID
	, year(PRESC.RX_ORDER_DATE) as EventYear
	, count(*) as CT_NALOXONE_PRESCRIBE
from indata.prescribing as PRESC
	join infolder.naloxonecui as CUI
		on CUI.Code = PRESC.RXNORM_CUI
	join dmlocal.nalox_encounter_filter as EF
		on PRESC.PATID = EF.PATID
			and PRESC.RX_ORDER_DATE >= EF.ADMIT_DATE
			and PRESC.RX_ORDER_DATE <= EF.DISCHARGE_DATE
group by PRESC.PATID, year(PRESC.RX_ORDER_DATE)
order by PRESC.PATID, EventYear
;
RUN;
QUIT;


* Create SAS data file dmlocal.nalox_disp;
PROC SQL inobs=max;
CREATE TABLE dmlocal.nalox_disp as
select distinct DISP.PATID
	, year(DISP.DISPENSE_DATE) as EventYear
	, count(*) as CT_NALOXONE_DISPENSE
from indata.dispensing as DISP
	join infolder.naloxonendc as NDC
		on NDC.Code = DISP.NDC
	join dmlocal.nalox_encounter_filter as EF
		on DISP.PATID = EF.PATID
			and DISP.DISPENSE_DATE >= EF.ADMIT_DATE
			and DISP.DISPENSE_DATE <= EF.DISCHARGE_DATE
group by DISP.PATID, year(DISP.DISPENSE_DATE)
order by DISP.PATID, EventYear
;
RUN;
QUIT;

* Create SAS data file dmlocal.nalox_admin_cui;
PROC SQL inobs=max;
CREATE TABLE dmlocal.nalox_admin_cui as
select distinct ADMIN.PATID
	, year(ADMIN.MEDADMIN_START_DATE) as EventYear
	, count(*) as CT_NALOXONE_ADMIN_CUI
from indata.med_admin as ADMIN
	join infolder.naloxonecui as CUI
		on ADMIN.MEDADMIN_TYPE = 'RX'
			and CUI.Code = ADMIN.MEDADMIN_CODE
	join dmlocal.nalox_encounter_filter as EF
		on ADMIN.PATID = EF.PATID
			and ADMIN.MEDADMIN_START_DATE >= EF.ADMIT_DATE
			and ADMIN.MEDADMIN_START_DATE <= EF.DISCHARGE_DATE
group by ADMIN.PATID, year(ADMIN.MEDADMIN_START_DATE)
order by ADMIN.PATID, EventYear
;
RUN;
QUIT;


* Create SAS data file dmlocal.nalox_admin_ndc;
PROC SQL inobs=max;
CREATE TABLE dmlocal.nalox_admin_ndc as
select distinct ADMIN.PATID
	, year(ADMIN.MEDADMIN_START_DATE) as EventYear
	, count(*) as CT_NALOXONE_ADMIN_NDC
from indata.med_admin as ADMIN
	join infolder.naloxonendc as NDC
		on ADMIN.MEDADMIN_TYPE = 'ND'
			and NDC.Code = ADMIN.MEDADMIN_CODE
	join dmlocal.nalox_encounter_filter as EF
		on ADMIN.PATID = EF.PATID
			and ADMIN.MEDADMIN_START_DATE >= EF.ADMIT_DATE
			and ADMIN.MEDADMIN_START_DATE <= EF.DISCHARGE_DATE
group by ADMIN.PATID, year(ADMIN.MEDADMIN_START_DATE)
order by ADMIN.PATID, EventYear
;
RUN;
QUIT;


* Create SAS data file dmlocal.naloxone_events;
PROC SQL inobs=max;
CREATE TABLE dmlocal.naloxone_events as
select PE.PATID
	, PE.EventYear
	, case when PRESC.PATID is not NULL then 1 else 0 end as NALOXONE_PRESCRIBE_RESCUE
	, case when DISP.PATID is not NULL then 1 else 0 end as NALOXONE_DISPENSE_RESCUE
	, case when ADMIN_CUI.PATID is not NULL then 1
		when ADMIN_NDC.PATID is not NULL then 1
		else 0
		end as NALOXONE_ADMIN_RESCUE
	, case when PRESC.PATID is not NULL then 1
		when DISP.PATID is not NULL then 1
		when ADMIN_CUI.PATID is not NULL then 1
		when ADMIN_NDC.PATID is not NULL then 1
		else 0
		end as NALOXONE_INFERRED_RESCUE
	, PRESC.CT_NALOXONE_PRESCRIBE
	, DISP.CT_NALOXONE_DISPENSE
	, ADMIN_CUI.CT_NALOXONE_ADMIN_CUI
	, ADMIN_NDC.CT_NALOXONE_ADMIN_NDC
	, PRESC.CT_NALOXONE_PRESCRIBE  + ADMIN_CUI.CT_NALOXONE_ADMIN_CUI + ADMIN_NDC.CT_NALOXONE_ADMIN_NDC as CT_NALOXONE_RESCUE
from dmlocal.patientevents as PE
	left join dmlocal.nalox_presc as PRESC
		on PE.PATID = PRESC.PATID and PE.EventYear = PRESC.EventYear
	left join dmlocal.nalox_disp as DISP
		on PE.PATID = DISP.PATID and PE.EventYear = DISP.EventYear
	left join dmlocal.nalox_admin_cui as ADMIN_CUI
		on PE.PATID = ADMIN_CUI.PATID and PE.EventYear = ADMIN_CUI.EventYear
	left join dmlocal.nalox_admin_ndc as ADMIN_NDC
		on PE.PATID = ADMIN_NDC.PATID and PE.EventYear = ADMIN_NDC.EventYear
;
RUN;
QUIT;


* Create SAS data file dmlocal.nalox_ambu_presc;
PROC SQL inobs=max;
CREATE TABLE dmlocal.nalox_ambu_presc as
select PRESC.PATID
	, year(PRESC.RX_ORDER_DATE) as EventYear
	, PRESC.PRESCRIBINGID, PRESC.RX_ORDER_DATE, PRESC.RX_ORDER_TIME, PRESC.RXNORM_CUI, PRESC.RX_PROVIDERID
from indata.prescribing as PRESC
	join infolder.naloxonecui as CUI
		on CUI.Code = PRESC.RXNORM_CUI
	left join dmlocal.prescribe_encounter_filter as EF	/* This is correct, not the nalox_encounter_filter. JND 20190226 */
		on PRESC.PATID = EF.PATID
			and PRESC.RX_ORDER_DATE >= EF.ADMIT_DATE
			and PRESC.RX_ORDER_DATE <= EF.DayBefore_DISCHARGE_DATE
where EF.PATID is NULL
order by PRESC.PATID, EventYear, PRESC.RX_ORDER_DATE, PRESC.RX_ORDER_TIME
;
RUN;
QUIT;


* Create SAS data file dmlocal.nalox_ambu_disp;
PROC SQL inobs=max;
CREATE TABLE dmlocal.nalox_ambu_disp as
select DISP.PATID
	, year(DISP.DISPENSE_DATE) as EventYear
	, DISP.DISPENSINGID, DISP.DISPENSE_DATE, DISP.NDC
from indata.dispensing as DISP
	join infolder.naloxonendc as NDC
		on NDC.Code = DISP.NDC
	left join dmlocal.prescribe_encounter_filter as EF	/* This is correct, not the nalox_encounter_filter. JND 20190226 */
		on DISP.PATID = EF.PATID
			and DISP.DISPENSE_DATE >= EF.ADMIT_DATE
			and DISP.DISPENSE_DATE <= EF.DayBefore_DISCHARGE_DATE
where EF.PATID is NULL
order by DISP.PATID, EventYear, DISP.DISPENSE_DATE
;
RUN;
QUIT;


* Create SAS data file dmlocal.nalox_ambulatory;
PROC SQL inobs=max;
CREATE TABLE dmlocal.nalox_ambulatory as
select PY.PATID
	, PY.EventYear
	, min(NALOX_DATE) as NALOX_DATE
from dmlocal.patientyears as PY
	join
	(
		select PATID, EventYear, RX_ORDER_DATE as NALOX_DATE
		from dmlocal.nalox_ambu_presc
		union all
		select PATID, EventYear, DISPENSE_DATE as NALOX_DATE
		from dmlocal.nalox_ambu_disp
	) as NALOX
		on PY.PATID = NALOX.PATID
			and PY.EventYear = NALOX.EventYear
group by PY.PATID, PY.EventYear
order by PY.PATID, PY.EventYear
;
RUN;
QUIT;


* Create SAS data file dmlocal.od_events;
*new variables added: OD_CY, f_CY;
PROC SQL inobs=max;
CREATE TABLE dmlocal.od_events as
select PE.PATID
	, PE.EventYear
	, max(case when OD.DX_DATE IS NOT NULL and OD.DX_DATE <= PE.IndexDate then 1 else 0 
	  end) as OD_PRE
	, max(case when OD.DX_DATE IS NOT NULL and year(OD.DX_DATE) < PE.EventYear then 1 else 0 
	  end) as OD_PRE_Prior_NotInc_CY
	, max(case when OD.DX_DATE IS NOT NULL and year(OD.DX_DATE) = PE.EventYear then 1 else 0 
	  end) as OD_CY /*new*/
	/*, max(case when OD.DX_DATE <= PE.IndexDate 
		and OD.ENC_TYPE IN ('ED', 'EI') 
		and OD.DX_DATE >= OD.ADMIT_DATE
		and OD.DX_DATE <= OD.DISCHARGE_DATE then 1 else 0 end) as ED_OD_PRE*/
	, max(case when year(OD.DX_DATE) = PE.EventYear 
		and OD.ENC_TYPE IN ('ED', 'EI') 
		and OD.DX_DATE >= OD.ADMIT_DATE
		and OD.DX_DATE <= OD.DISCHARGE_DATE then 1 else 0 end) as ED_OD_CY /*new*/
	, max(case when OD.DX_DATE IS NOT NULL and OD.DX_DATE <= PE.IndexDate then OD.DX_DATE 
	  end) as OD_PRE_DATE
	/*, max(case when OD.DX_DATE <= PE.IndexDate 
		and OD.ENC_TYPE IN ('ED', 'EI') 
		and OD.DX_DATE >= OD.ADMIT_DATE 
		and OD.DX_DATE <= OD.DISCHARGE_DATE then OD.DX_DATE end)	as ED_OD_PRE_DATE*/
	/*, max(case when OD.DX_DATE >= PE.IndexDate then 1 else 0 end) as OD_POST*/
	/*, max(case when OD.DX_DATE >= PE.IndexDate
		and OD.ENC_TYPE IN ('ED', 'EI') 
		and OD.DX_DATE >= OD.ADMIT_DATE
		and OD.DX_DATE <= OD.DISCHARGE_DATE then 1 else 0 end) as ED_OD_POST*/
	/*, min(case when OD.DX_DATE >= PE.IndexDate then OD.DX_DATE end) as OD_POST_DATE*/
	/*, min(case when OD.DX_DATE >= PE.IndexDate 
		and OD.ENC_TYPE IN ('ED', 'EI') 
		and OD.DX_DATE >= OD.ADMIT_DATE
		and OD.DX_DATE <= OD.DISCHARGE_DATE then OD.DX_DATE end)	as ED_OD_POST_DATE*/
from dmlocal.patientevents as PE		/* handle missing patients */	
	left join 
	( 
		SELECT D.PATID
			, D.ADMIT_DATE as DX_DATE
			, E.ADMIT_DATE
			, coalesce(E.DISCHARGE_DATE, E.ADMIT_DATE) as DISCHARGE_DATE
			, E.ENC_TYPE
		FROM indata.diagnosis as D
		JOIN infolder.opioidoverdose OD
		ON D.DX_TYPE = OD.Dx_TYPE AND D.DX = OD.Code
		JOIN indata.encounter as E
		ON D.PATID = E.PATID
		where D.ADMIT_DATE >= &StudyStartDate		
			and D.ADMIT_DATE < &StudyEndDate
	) AS OD
ON PE.PATID = OD.PATID
group by PE.PATID, PE.EventYear
;
QUIT;





PROC SQL inobs=max;
CREATE TABLE dmlocal.fatal_od as
select PY.PATID
	, PY.EventYear
/*, DIAG.PATID, DIAG.DX_TYPE, DIAG.DX, DIAG.ADMIT_DATE as Dx_DATE
, D.DEATH_DATE, E.ADMIT_DATE, E.DISCHARGE_DATE*/
	, max(case when E.PATID is not NULL and D.DEATH_DATE is not NULL then 1 else 0 end) as FATAL_OVERDOSE
	, max(case when E.PATID is not NULL and D.DEATH_DATE is NULL then 1 else 0 end) as NONFATAL_OD_CY /*new*/
from indata.diagnosis as DIAG
	JOIN infolder.opioidoverdose OD
		ON DIAG.DX_TYPE = OD.Dx_TYPE AND DIAG.DX = OD.Code
			and DIAG.PATID is not NULL
			and DIAG.ADMIT_DATE is not NULL
	join indata.encounter as E
		on DIAG.PATID = E.PATID
			and E.ADMIT_DATE is not NULL
			and E.ADMIT_DATE <= DIAG.ADMIT_DATE
			and DIAG.ADMIT_DATE is not NULL
			and DIAG.ADMIT_DATE <= coalesce(E.DISCHARGE_DATE, E.ADMIT_DATE)
			and E.RAW_ENC_TYPE <> "Outpatient Visit Within Inpatient Visit"
	left join indata.death as D
		on DIAG.PATID = D.PATID
			and E.ADMIT_DATE <= D.DEATH_DATE
			and D.DEATH_DATE <= coalesce(E.DISCHARGE_DATE, E.ADMIT_DATE)
	right join dmlocal.patientyears as PY
		on DIAG.PATID = PY.PATID
			and PY.EventYear = year(DIAG.ADMIT_DATE)
group by PY.PATID, PY.EventYear
order by PY.PATID, PY.EventYear
/*order by DIAG.PATID, DIAG.ADMIT_DATE*/
;
QUIT;



* Create SAS data file dmlocal.suicide_events;
*new variables added: SUICIDE_SH_ATTEMPT_CY;
PROC SQL inobs=max;
CREATE TABLE dmlocal.suicide_events as
select PE.PATID
	, PE.EventYear
	/*, max(case when SUIC.ADMIT_DATE IS NOT NULL and SUIC.ADMIT_DATE <= PE.IndexDate then 1 else 0 
	  end) as SUICIDE_PRE
	, max(case when SUIC.ADMIT_DATE IS NOT NULL and SUIC.ADMIT_DATE <= PE.IndexDate then SUIC.ADMIT_DATE 
	  end) as SUICIDE_PRE_DATE*/
	/*, max(case when SUIC.ADMIT_DATE >= PE.IndexDate then 1 else 0 end) as SUICIDE_POST
	, min(case when SUIC.ADMIT_DATE >= PE.IndexDate then SUIC.ADMIT_DATE end) as SUICIDE_POST_DATE*/
	, max(case when SUIC.ADMIT_DATE IS NOT NULL and year(SUIC.ADMIT_DATE) = PE.EventYear then 1 else 0 
	  end) as SUICIDE_SH_ATTEMPT_CY /*new*/
from dmlocal.patientevents as PE	
	left join 
	( 
		SELECT D.PATID
			, D.ADMIT_DATE
		FROM indata.diagnosis as D
		JOIN infolder.suicide S
		ON D.DX_TYPE = S.Dx_TYPE AND D.DX = S.Code
		where D.ADMIT_DATE >= &StudyStartDate		
			and D.ADMIT_DATE < &StudyEndDate
	) AS SUIC
	ON PE.PATID = SUIC.PATID
	group by PE.PATID, PE.EventYear
;
RUN;
QUIT;


* Create SAS data file dmlocal.smoking_events;
PROC SQL inobs=max;
CREATE TABLE dmlocal.smoking_events as
select PE.PATID
	, PE.EventYear
	, max(case when SMOK.PATID IS NOT NULL
		and PE.EventYear = SMOK.EventYear then 1 else 0
		end) as SMOKING
	, max(case when SMOK.PATID IS NOT NULL
		and SMOK.EventYear is not NULL
		and PE.EventYear > SMOK.EventYear then 1 else 0
		end) as SMOKING_Prior_NotInc_CY
from dmlocal.patientevents as PE
left join
	(	
		select D.PATID
			, YEAR(D.ADMIT_DATE) as EventYear
		from indata.diagnosis as D
			join infolder.smoking S
				on D.DX_TYPE = S.Dx_TYPE
					and D.DX = S.Code
		where D.ADMIT_DATE >= &StudyStartDate		
			and D.ADMIT_DATE < &StudyEndDate
	) AS SMOK
ON PE.PATID = SMOK.PATID
group by PE.PATID, PE.EventYear
;
RUN;
QUIT;


* Create SAS data file dmlocal.prescribing_chronic_opioids;
PROC SQL inobs=max;
CREATE TABLE dmlocal.prescribing_chronic_opioids as
select PATID, EventYear, min(RX_ORDER_DATE) as First_PRESCRIBE_DATE, count(*) as Prescribing_Qty
from dmlocal.prescribing_events_all
group by PATID, EventYear
order by PATID, EventYear
;
RUN;
QUIT;


* Create SAS data file dmlocal.dispensing_chronic_opioids;
PROC SQL inobs=max;
CREATE TABLE dmlocal.dispensing_chronic_opioids as
select PATID, EventYear, min(DISPENSE_DATE) as First_DISPENSE_DATE, count(*) as Dispensing_Qty
from dmlocal.dispensing_select
group by PATID, EventYear
order by PATID, EventYear
;
RUN;
QUIT;


* Create SAS data file dmlocal.chronic_opioids;
*new variables added:  CHRONIC_OPIOID_CY;
PROC SQL inobs=max;
CREATE TABLE dmlocal.chronic_opioids as
select PY.PATID, PY.EventYear
	, case when PO_Cur.Prescribing_Qty >= 3 and DO_Cur.Dispensing_Qty >= 3 
			and PO_Cur.First_PRESCRIBE_DATE IS NOT NULL 
			and PO_Cur.First_PRESCRIBE_DATE <= DO_Cur.First_DISPENSE_DATE then PO_Cur.First_PRESCRIBE_DATE
		when PO_Cur.Prescribing_Qty >= 3 and DO_Cur.Dispensing_Qty >= 3 then DO_Cur.First_DISPENSE_DATE
		when PO_Cur.Prescribing_Qty >= 3 then PO_Cur.First_PRESCRIBE_DATE
		when DO_Cur.Dispensing_Qty >= 3 then DO_Cur.First_DISPENSE_DATE
		end as CHRONIC_OPIOID_DATE
	, case when PO_Cur.Prescribing_Qty >= 3 or DO_Cur.Dispensing_Qty >= 3 then 1 else 0
		end as CHRONIC_OPIOID
	, case when PO_Cur.Prescribing_Qty >= 3 or DO_Cur.Dispensing_Qty >= 3
			or PO_Prior.Prescribing_Qty >= 3 or DO_Prior.Dispensing_Qty >= 3 then 1 else 0
		end as CHRONIC_OPIOID_CURRENT_PRIOR
	, case when calculated CHRONIC_OPIOID_DATE is not null and year(calculated CHRONIC_OPIOID_DATE)=PY.EventYear then 1 else 0
		end as CHRONIC_OPIOID_CY /*new*/
from dmlocal.patientyears as PY
	left join dmlocal.prescribing_chronic_opioids as PO_Cur
		on PY.PATID = PO_Cur.PATID
			and PY.EventYear = PO_Cur.EventYear 
	left join dmlocal.prescribing_chronic_opioids as PO_Prior
		on PY.PATID = PO_Prior.PATID
			and PY.EventYear - 1 = PO_Prior.EventYear
	left join dmlocal.dispensing_chronic_opioids as DO_Cur
		on PY.PATID = DO_Cur.PATID
			and PY.EventYear = DO_Cur.EventYear 
	left join dmlocal.dispensing_chronic_opioids as DO_Prior
		on PY.PATID = DO_Prior.PATID
			and PY.EventYear - 1 = DO_Prior.EventYear
order by PY.PATID, PY.EventYear
;
RUN;
QUIT;

* New--Create SAS data file dmlocal.chronic_opioids_ever;
*new variables added:  CHRONIC_OPIOID_everCY;
PROC SQL inobs=max;
CREATE TABLE dmlocal.chronic_opioids_ever as
select distinct patid, eventyear, min(chronic_opioid_date)as min_date
	, case when .< year(calculated min_date)<= EventYear then 1 else 0
		end as CHRONIC_OPIOID_everCY /*new*/
	, case when .< year(calculated min_date)< EventYear then 1 else 0
		end as CHRONIC_OPIOID_Prior_NotInc_CY /*new*/
from dmlocal.chronic_opioids 
GROUP BY patid
order by PATID, EventYear
;
QUIT;



* New--Create SAS data file dmlocal.nalox_opioid_co_rx;
*new variables added:  nalox_opioid_co_rx;
proc sql inobs=max;
	create table dmlocal.nalox_opioid_co_rx as
	select distinct P.patid, p.eventyear, 1 as nalox_opioid_co_rx
	from dmlocal.prescribing_select as p
		join dmlocal.nalox_ambu_presc as n
		on p.patid=n.patid and p.RX_ORDER_DATE=n.RX_ORDER_DATE
	;
quit;


proc sql inobs=max;
	create table dmlocal.zips as
	select distinct zip3, coalesce(REMAP_TO, state) as State
	from infolder.zipcode
	order by zip3, state
	;
quit;



* Create SAS data file dmlocal.opioid_flat_file;
*new variables added: MAT_ANY_CY, MAT_ANY_everCY, HIV_HBV_HBC_CY, HIV_HBV_HBC_everCY, state, ANY_ENC_CY, CANCER_PX_CURRENT_YEAR,
	BUP_ANY_CY, NALTREX_ANY_CY, NALOX_OPIOID_CO_RX, chronic_opioid_ind, opioid_exp_ind, oud_ind, substance_ind, alcohol_ind, sud_oud_ind, overdose_ind;
data sites;
format DataMartID $20.;
%LET DataMartID=compress("&DMID.&SITEID.");
run;

PROC SQL inobs=max;
  CREATE TABLE dmlocal.opioid_flat_file AS
  SELECT &DataMartID as DataMartID
	, DEMO.*
	, Z.state
	, case when DEMO.DEATH_DATE IS NOT NULL 
		and DEMO.DEATH_DATE < EVNTS.ADMIT_DATE then 1 else 0 end as ZOMBIE_FLAG 
	, case when DEMO.DEATH_DATE IS NOT NULL
		then DEMO.DEATH_DATE - EVNTS.IndexDate end AS DaysToDeath /* Changed to include all patients, not just those on opioids */ 
	, case when DEMO.AgeAsOfJuly1 >= 0 and DEMO.AgeAsOfJuly1 < 15 then '0-14'
  		when DEMO.AgeAsOfJuly1 >= 15 and DEMO.AgeAsOfJuly1 < 20 then '15-19'
		when DEMO.AgeAsOfJuly1 >= 20 and DEMO.AgeAsOfJuly1 < 25 then '20-24'
		when DEMO.AgeAsOfJuly1 >= 25 and DEMO.AgeAsOfJuly1 < 35 then '25-34'
		when DEMO.AgeAsOfJuly1 >= 35 and DEMO.AgeAsOfJuly1 < 45 then '35-44'
		when DEMO.AgeAsOfJuly1 >= 45 and DEMO.AgeAsOfJuly1 < 55 then '45-54'
		when DEMO.AgeAsOfJuly1 >= 55 and DEMO.AgeAsOfJuly1 < 65 then '55-64'
		when DEMO.AgeAsOfJuly1 >= 65 then '>=65'
		end as AGEGRP1 
	/*, case when DEMO.AgeAsOfJuly1 >= 0 and DEMO.AgeAsOfJuly1 < 11 then '0-10'
		when DEMO.AgeAsOfJuly1 >= 11 and DEMO.AgeAsOfJuly1 < 18 then '11-17'
		when DEMO.AgeAsOfJuly1 >= 18 and DEMO.AgeAsOfJuly1 < 26 then '18-25'
		when DEMO.AgeAsOfJuly1 >= 26 and DEMO.AgeAsOfJuly1 < 36 then '26-35'
		when DEMO.AgeAsOfJuly1 >= 36 and DEMO.AgeAsOfJuly1 < 46 then '36-45'
		when DEMO.AgeAsOfJuly1 >= 46 and DEMO.AgeAsOfJuly1 < 56 then '46-55'
		when DEMO.AgeAsOfJuly1 >= 56 and DEMO.AgeAsOfJuly1 < 65 then '56-64'
		when DEMO.AgeAsOfJuly1 >= 65 and DEMO.AgeAsOfJuly1 < 75 then '65-74'
		when DEMO.AgeAsOfJuly1 >= 75 and DEMO.AgeAsOfJuly1 < 85 then '75-84'
		when DEMO.AgeAsOfJuly1 >= 85 then '85+'
		end as AGEGRP2 */
	, EVNTS.IndexDate 
    , EVNTS.PRESCRIBINGID 
    , EVNTS.RX_ORDER_DATE 
	, case when EVNTS.RX_ORDER_DATE IS NOT NULL then 1 else 0 end as Opioid_Prescription 
    , EVNTS.RXNORM_CUI
	, EVNTS.Prescribing_NDC 
	, EVNTS.RX_PROVIDERID 
    , EVNTS.DISPENSINGID 
    , EVNTS.DISPENSE_DATE 
	, case when EVNTS.DISPENSE_DATE IS NOT NULL then 1  else 0 end as Opioid_Dispensation 
    , EVNTS.NDC as Dispensing_NDC 
	, CASE
		WHEN (EVNTS.RX_ORDER_DATE IS NOT NULL OR EVNTS.DISPENSE_DATE IS NOT NULL) THEN 1 ELSE 0
		END AS OPIOID_FLAG
	, case when (FIRST_OPIOID.FirstOpioidDate is not NULL
		and year(FIRST_OPIOID.FirstOpioidDate) < EVNTS.EventYear) then 1 else 0 end as OPIOID_FLAG_Prior_NotInc_CY /*new*/
    , EVNTS.ENCOUNTERID 
    , EVNTS.ADMIT_DATE 
    , EVNTS.ENC_TYPE 
	, case when PRIOR_YEAR_ENC.PATID is not NULL then 1 else 0 end as PRIOR_YEAR_ENCOUNTER 
	/*, OpioidInYearPrior.OpioidInYearPrior */
	, FIRST_OPIOID.FirstOpioidDate 
	, FIRST_DIAG.FirstDiagEncDate as OBS_START 
	, FIRST_OPIOID.FirstOpioidDate - FIRST_DIAG.FirstDiagEncDate as LOOKBACK_BEFORE_INDEX_OPIOID 
	, case when ED_Visit_Years.PATID is not NULL then 1 else 0 end as ED_YR 
	, case when IP_Visit_Years.PATID is not NULL then 1 else 0 end as IP_YR 
	/*, case when ED_Visit_Years.PATID is not NULL then 1
		when IP_Visit_Years.PATID is not NULL then 1
		else 0
		end as ED_IP_YR */
	, CA_DX.Cancer_AnyEncount_Dx_Year_Prior as Cancer_AnyEnc_Dx_Year_Prior  /*rename due to length*/
	/*, CA_DX.Cancer_Inpt_Dx_Year_Prior */
	/*, CA_PROC.Chemo_AnyEncount_Year_Prior 
	, CA_PROC.Rad_AnyEncount_Year_Prior
	, CASE
		WHEN (CA_PROC.Chemo_AnyEncount_Year_Prior = 1
				OR CA_PROC.Rad_AnyEncount_Year_Prior = 1) THEN 1 ELSE 0
		END AS CANCER_PROC_FLAG */
	, case 
		when UDS.UDS_LOINC_Qty_perYear = 0 then 'NA'
		when UDS.UDS_LOINC = 1 then 'Y'
		else 'N'
		end as UDS_LOINC 
	, case
		when UDS.UDS_CPT_Qty_perYear = 0 then 'NA'
		when UDS.UDS_CPT = 1 then 'Y'
		else 'N'
		end as UDS_CPT 
	, case
		when (UDS.UDS_LOINC_Qty_perYear = 0 and UDS.UDS_CPT_Qty_perYear = 0) then 'NA'
		when (UDS.UDS_LOINC = 1 or UDS.UDS_CPT = 1) then 'Y'
		else 'N'
		end as UDS_FLAG 
	/*, MH_Dx_Pri_Any_Prior */
	/*, MH_Dx_Pri_Year_Prior */
	/*, MH_Dx_Exp_Any_Prior */
	/*, MH_Dx_Exp_Year_Prior */
	/*, SUD.Alcohol_Use_DO_Year_Prior */
	, SUD.Alcohol_Use_DO_Any_Prior 
	, SUD.Alcohol_Use_DO_Post_Date 
	/*, SUD.Substance_Use_DO_Year_Prior */
	, SUD.Substance_Use_DO_Any_Prior 
	, SUD.Substance_Use_DO_Post_Date 
	/*, SUD.Opioid_Use_DO_Year_Prior */
	, SUD.Opioid_Use_DO_Any_Prior 
	, SUD.Opioid_Use_DO_Post_Date 
	/*, SUD.Cannabis_Use_DO_Year_Prior */
	, SUD.Cannabis_Use_DO_Any_Prior 
	, SUD.Cannabis_Use_DO_Post_Date 
	/*, SUD.Cocaine_Use_DO_Year_Prior */
	, SUD.Cocaine_Use_DO_Any_Prior 
	, SUD.Cocaine_Use_DO_Post_Date 
	/*, SUD.Hallucinogen_Use_DO_Year_Prior as Halluc_Use_DO_Year_Prior*/  /*rename due to length*/
	/*, SUD.Hallucinogen_Use_DO_Any_Prior as Halluc_Use_DO_Any_Prior*/  /*rename due to length*/
	, SUD.Hallucinogen_Use_DO_Post_Date as Halluc_Use_DO_Post_Date  /*rename due to length*/
	/*, SUD.Inhalant_Use_DO_Year_Prior */
	, SUD.Inhalant_Use_DO_Any_Prior 
	, SUD.Inhalant_Use_DO_Post_Date 
	/*, SUD.Other_Stim_Use_DO_Year_Prior */
	, SUD.Other_Stim_Use_DO_Any_Prior 
	, SUD.Other_Stim_Use_DO_Post_Date 
	/*, SUD.SedHypAnx_Use_DO_Year_Prior */
	, SUD.SedHypAnx_Use_DO_Any_Prior 
	, SUD.SedHypAnx_Use_DO_Post_Date 
	/*, HEPB.HepB_Dx_Year_Prior */
	/*, HEPB.HepB_Dx_Any_Prior */
	, HEPB.HepB_Dx_Post_Date 
	/*, HEPC.HepC_Dx_Year_Prior */
	/*, HEPC.HepC_Dx_Any_Prior */
	, HEPC.HepC_Dx_Post_Date 
	/*, HIV.HIV_Dx_Year_Prior */
	/*, HIV.HIV_Dx_Any_Prior */
	, HIV.HIV_Dx_Post_Date 
	/*, case when HEPB.HepB_Dx_Year_Prior = 1 then 1
		when HEPC.HepC_Dx_Year_Prior = 1 then 1
		when HIV.HIV_Dx_Year_Prior = 1 then 1
		else 0
		end as ANY_STD_Year_Prior */
	, BDZ.BDZ_CY
	, case when BDZ.BDZ_CY = 1 and calculated OPIOID_FLAG = 1 then 1 else 0 end as BDZ_Opioid_CoOccurr_CY
    /*, BDZ.BDZ_Presc_3mo 
   	, BDZ.BDZ_Disp_3mo */
	/*, BUP.BUP_PRESC_PRE 
	, BUP.BUP_PRESC_PRE_DATE 
	, BUP.BUP_PRESC_POST 
	, BUP.BUP_PRESC_POST_DATE */
	/*, BUP.BUP_DISP_PRE 
	, BUP.BUP_DISP_PRE_DATE 
	, BUP.BUP_DISP_POST 
	, BUP.BUP_DISP_POST_DATE */
	/*, NALTREX.NALTREX_PRESC_PRE 
	, NALTREX.NALTREX_PRESC_PRE_DATE 
	, NALTREX.NALTREX_PRESC_POST 
	, NALTREX.NALTREX_PRESC_POST_DATE 
	, NALTREX.NALTREX_DISP_PRE 
	, NALTREX.NALTREX_DISP_PRE_DATE 
	, NALTREX.NALTREX_DISP_POST 
	, NALTREX.NALTREX_DISP_POST_DATE */
	/*, METHADONE.METHADONE_PRESC_PRE 
	, METHADONE.METHADONE_PRESC_PRE_DATE */
	/*, METHADONE.METHADONE_PRESC_POST 
	, METHADONE.METHADONE_PRESC_POST_DATE */
	/*, METHADONE.METHADONE_DISP_PRE 
	, METHADONE.METHADONE_DISP_PRE_DATE */
	/*, METHADONE.METHADONE_DISP_POST 
	, METHADONE.METHADONE_DISP_POST_DATE */
	, NALOX.NALOXONE_PRESCRIBE_RESCUE 
	, NALOX.NALOXONE_DISPENSE_RESCUE 
	, NALOX.NALOXONE_ADMIN_RESCUE 
	, NALOX.NALOXONE_INFERRED_RESCUE 
	, NALOX.CT_NALOXONE_PRESCRIBE 
	, NALOX.CT_NALOXONE_DISPENSE 
	, NALOX.CT_NALOXONE_ADMIN_CUI 
	, NALOX.CT_NALOXONE_ADMIN_NDC 
	, NALOX.CT_NALOXONE_RESCUE 
	, NALOX_AMBU.NALOX_DATE as NALOX_AMBULATORY_DATE 
	, case when NALOX_AMBU.NALOX_DATE is not NULL then 1 else 0 end as NALOX_AMBULATORY 
	, OD.OD_PRE
	, OD.OD_PRE_Prior_NotInc_CY /*new*/
	, OD.OD_PRE_DATE 
	/*, OD.OD_POST 
	, OD.OD_POST_DATE */
	/*, OD.ED_OD_PRE 
	, OD.ED_OD_PRE_DATE */
	/*, OD.ED_OD_POST 
	, OD.ED_OD_POST_DATE */
	, FATAL_OD.FATAL_OVERDOSE 
	/*, SUIC.SUICIDE_PRE 
	, SUIC.SUICIDE_PRE_DATE */
	/*, SUIC.SUICIDE_POST 
	, SUIC.SUICIDE_POST_DATE */
	, SUIC.SUICIDE_SH_ATTEMPT_CY
	, SMOK.SMOKING
	, SMOK.SMOKING_Prior_NotInc_CY	/*new*/
	, CHRON_OP.CHRONIC_OPIOID_DATE 
	, CHRON_OP.CHRONIC_OPIOID 
	, CHRON_OP.CHRONIC_OPIOID_CURRENT_PRIOR as CHRONIC_OPIOID_CURR_PRIOR  /*rename due to length*/
	, CA_DX.Cancer_AnyEncount_CY  /*new*/
	, CA_DX.Cancer_Inpt_Dx_CY  /*new*/
	, SUD.Cannabis_UD_Any_CY  /*new*/
	, SUD.Cocaine_UD_Any_CY  /*new*/
	, SUD.Other_Stim_UD_Any_CY  /*new*/
	, SUD.Hallucinogen_UD_Any_CY  /*new*/
	, SUD.Inhalant_UD_Any_CY  /*new*/
	, SUD.SedHypAnx_UD_Any_CY  /*new*/
	, SUD.Opioid_UD_Any_CY  /*new*/
	, SUD.Opioid_UDO_Prior_NotInc_CY /*new*/
	, SUD.Alcohol_UD_Any_CY  /*new*/
	, SUD.Substance_UD_Any_CY  /*new*/
	, SUDe.Opioid_UD_Any_everCY  /*new*/
	, SUDe.Alcohol_UD_Any_everCY  /*new*/
	, SUDe.Substance_UD_Any_everCY  /*new*/
	, SUDe.OUD_SUD_everCY  /*new*/
	, SUDe.OUD_SUD_CY  /*new*/
	, HEPB.HepB_Dx_Any_CY  /*new*/
	/*, HEPBe.HepB_Dx_Any_everCY*/  /*new*/
	, HEPC.HepC_Dx_Any_CY  /*new*/
	/*, HEPCe.HepC_Dx_Any_everCY*/  /*new*/
	, MH_CY.MH_Dx_Pri_CY  /*new*/
	, MH_CY.MH_Dx_Exp_CY  /*new*/
	, HIV.HIV_Dx_Any_CY  /*new*/
	/*, HIVe.HIV_Dx_Any_everCY*/  /*new*/
	, BUP_CY.BUP_PRESC_CY  /*new*/
	, BUP_CY.BUP_DISP_CY  /*new*/
	, BUP_CYe.BUP_PRESC_everCY  /*new*/
	, BUP_CYe.BUP_DISP_everCY  /*new*/
	, NALTREX_CY.NALTREX_PRESC_CY  /*new*/
	, NALTREX_CY.NALTREX_DISP_CY  /*new*/
	, NALTREX_CYe.NALTREX_PRESC_everCY  /*new*/
	, NALTREX_CYe.NALTREX_DISP_everCY  /*new*/
	/*, METH_CY.METHADONE_ANY_CY*/  /*new*/
	, OD.OD_CY  /*new*/
	, OD.ED_OD_CY  /*new*/
	/*, max(BUP_CY.BUP_DISP_CY, BUP_CY.BUP_PRESC_CY, NALTREX_CY.NALTREX_DISP_CY, NALTREX_CY.NALTREX_PRESC_CY) as MAT_ANY_CY*/ /*new*/
	/*, max(BUP_CYe.BUP_DISP_everCY, BUP_CYe.BUP_PRESC_everCY, NALTREX_CYe.NALTREX_DISP_everCY, NALTREX_CYe.NALTREX_PRESC_everCY) as MAT_ANY_everCY*/ /*new*/
	/*, max(HIV.HIV_Dx_Any_CY, HEPB.HepB_Dx_Any_CY, HEPC.HepC_Dx_Any_CY) as HIV_HBV_HBC_CY*/ /*new*/
	/*, max(HIVe.HIV_Dx_Any_everCY, HEPBe.HepB_Dx_Any_everCY, HEPCe.HepC_Dx_Any_everCY) as HIV_HBV_HBC_everCY*/  /*new*/
	, max(BUP_CY.BUP_DISP_CY, BUP_CY.BUP_PRESC_CY) as BUP_ANY_CY /*new*/
	, max(NALTREX_CY.NALTREX_DISP_CY, NALTREX_CY.NALTREX_PRESC_CY) as NALTREX_ANY_CY /*new*/
	, FATAL_OD.NONFATAL_OD_CY  /*new*/
	, CHRON_OP.CHRONIC_OPIOID_CY  /*new*/
	, CHRON_OPe.CHRONIC_OPIOID_everCY  /*new*/
	, CHRON_OPe.CHRONIC_OPIOID_Prior_NotInc_CY as CHRON_OPIOID_Prior_NotInc_CY	/*new*/
	/*, case when DEMO.PATID=ENC_EVENT.PATID and DEMO.EventYear=ENC_EVENT.EventYear and ENC_EVENT.EventYear is not null then 1 else 0 end as ANY_ENC_CY*/ /*new*/
	, case when CA_DX.Cancer_AnyEncount_CY=0 then 1 else 0 end as GL_A_DENOM_FOR_ST
	, case when CA_PROC_CY.Chemo_AnyEncount_CY=1 or CA_PROC_CY.Rad_AnyEncount_CY=1 then 1 else 0 end as CANCER_PX_CURRENT_YEAR  /*new*/
	, case when CA_DX.Cancer_Inpt_Dx_CY=1 or calculated CANCER_PX_CURRENT_YEAR=1 then 0 else 1 end as GL_B_DENOM_FOR_ST
	, case when NAL_CORX.NALOX_OPIOID_CO_RX=1 then 1 else 0 end as NALOX_OPIOID_CO_RX  /*new*/
	,case when calculated GL_B_DENOM_FOR_ST=1 and CHRON_OP.chronic_opioid_cy=1 then 1 else 0 end as CHRONIC_OPIOID_IND /*new*/
	,case when calculated GL_B_DENOM_FOR_ST=1 and calculated opioid_flag=1 then 1 else 0 end as OPIOID_EXP_IND /*new*/
	,case when calculated GL_B_DENOM_FOR_ST=1 and SUD.Opioid_UD_Any_CY=1 then 1 else 0 end as OUD_IND /*new*/
	,case when calculated GL_B_DENOM_FOR_ST=1 and SUD.Substance_UD_Any_CY=1 then 1 else 0 end as substance_IND /*new*/
	,case when calculated GL_B_DENOM_FOR_ST=1 and SUD.Alcohol_UD_Any_CY=1 then 1 else 0 end as alcohol_IND /*new*/
	,case when calculated GL_B_DENOM_FOR_ST=1 and (OD.OD_CY=1) then 1 else 0 end as overdose_IND /*new*/
	,case when calculated GL_B_DENOM_FOR_ST=1 and (SUD.Opioid_UD_Any_CY=1 or SUD.Substance_UD_Any_CY=1 or SUDe.OUD_SUD_CY=1) then 1 else 0 end as OUD_SUD_IND /*new*/
	,case when  DEMO.race IN ("NI","OT") then .
	   	when DEMO.race="05" then 1
		else 0 end as BINARY_RACE
	,case when DEMO.sex in ("NI","OT") then .
		when DEMO.sex = "F" then 1
		ELSE 0 end as BINARY_SEX
	,case when DEMO.hispanic IN ("NI","OT") then .
		when DEMO.hispanic = "Y" then 1
		ELSE 0 end as BINARY_HISPANIC
	,Opioid_Use_DO_Post_date - FirstOpioidDate as TimeFromIndexOpioidToOUD /*new*/
	,case when calculated TimeFromIndexOpioidToOUD>0 then 1
		else 0 end as OUD_Post_Opioid_Exp /*new*/
  FROM dmlocal.patientevents as EVNTS
  LEFT JOIN dmlocal.patientdemo as DEMO
  ON DEMO.PATID = EVNTS.PATID AND DEMO.EventYear = EVNTS.EventYear
	left join dmlocal.encounter_events as PRIOR_YEAR_ENC
		on DEMO.PATID = PRIOR_YEAR_ENC.PATID and DEMO.EventYear - 1 = PRIOR_YEAR_ENC.EventYear
	left join dmlocal.first_diag as FIRST_DIAG
		on DEMO.PATID = FIRST_DIAG.PATID
	left join dmlocal.first_opioid as FIRST_OPIOID
		on DEMO.PATID = FIRST_OPIOID.PATID
	/*left join dmlocal.opioid_year_prior as OpioidInYearPrior
		on DEMO.PATID = OpioidInYearPrior.PATID and DEMO.EventYear = OpioidInYearPrior.EventYear*/
	left join dmlocal.ED_Visit_Years
		on DEMO.PATID = ED_Visit_Years.PATID and DEMO.EventYear = ED_Visit_Years.EventYear
	left join dmlocal.IP_Visit_Years
		on DEMO.PATID = IP_Visit_Years.PATID and DEMO.EventYear = IP_Visit_Years.EventYear
  LEFT JOIN dmlocal.cancer_dx_events as CA_DX
  ON DEMO.PATID = CA_DX.PATID AND DEMO.EventYear = CA_DX.EventYear
  /*LEFT JOIN dmlocal.cancer_proc_events as CA_PROC
  ON DEMO.PATID = CA_PROC.PATID AND DEMO.EventYear = CA_PROC.EventYear*/
  LEFT JOIN dmlocal.uds_events AS UDS
  ON DEMO.PATID = UDS.PATID AND DEMO.EventYear = UDS.EventYear
  /*LEFT JOIN dmlocal.mental_health_events as MH
  ON DEMO.PATID = MH.PATID AND DEMO.EventYear = MH.EventYear*/
  left join dmlocal.substance_use_do_events as SUD
  	on DEMO.PATID = SUD.PATID AND DEMO.EventYear = SUD.EventYear
  left join dmlocal.substance_use_do_events_ever as SUDe
  	on DEMO.PATID = SUDe.PATID AND DEMO.EventYear = SUDe.EventYear
	left join dmlocal.hepb_events as HEPB
		on DEMO.PATID = HEPB.PATID
			and DEMO.EventYear = HEPB.EventYear
	left join dmlocal.hepb_events_ever as HEPBe
		on DEMO.PATID = HEPBe.PATID
			and DEMO.EventYear = HEPBe.EventYear
	left join dmlocal.hepc_events as HEPC
		on DEMO.PATID = HEPC.PATID
			and DEMO.EventYear = HEPC.EventYear
	left join dmlocal.hepc_events_ever as HEPCe
		on DEMO.PATID = HEPCe.PATID
			and DEMO.EventYear = HEPCe.EventYear
	left join dmlocal.hiv_events as HIV
		on DEMO.PATID = HIV.PATID
			and DEMO.EventYear = HIV.EventYear
	left join dmlocal.hiv_events_ever as HIVe
		on DEMO.PATID = HIVe.PATID
			and DEMO.EventYear = HIVe.EventYear
  LEFT JOIN dmlocal.BDZ_Events as BDZ
   ON DEMO.PATID = BDZ.PATID AND DEMO.EventYear = BDZ.EventYear
	/*left join dmlocal.bup_events as BUP
		on DEMO.PATID = BUP.PATID and DEMO.EventYear = BUP.EventYear*/
	/*left join dmlocal.naltrex_events as NALTREX
		on DEMO.PATID = NALTREX.PATID and DEMO.EventYear = NALTREX.EventYear*/
	/*left join dmlocal.methadone_events as METHADONE
		on DEMO.PATID = METHADONE.PATID and DEMO.EventYear = METHADONE.EventYear*/
	left join dmlocal.naloxone_events as NALOX
		on DEMO.PATID = NALOX.PATID and DEMO.EventYear = NALOX.EventYear
	left join dmlocal.nalox_ambulatory as NALOX_AMBU
		on DEMO.PATID = NALOX_AMBU.PATID and DEMO.EventYear = NALOX_AMBU.EventYear
	left join dmlocal.od_events as OD
		on DEMO.PATID = OD.PATID and DEMO.EventYear = OD.EventYear
	left join dmlocal.fatal_od as FATAL_OD
		on DEMO.PATID = FATAL_OD.PATID and DEMO.EventYear = FATAL_OD.EventYear
	left join dmlocal.suicide_events as SUIC
		on DEMO.PATID = SUIC.PATID and DEMO.EventYear = SUIC.EventYear
	left join dmlocal.smoking_events as SMOK
		on DEMO.PATID = SMOK.PATID and DEMO.EventYear = SMOK.EventYear
	left join dmlocal.chronic_opioids as CHRON_OP
		on DEMO.PATID = CHRON_OP.PATID and DEMO.EventYear = CHRON_OP.EventYear
	left join dmlocal.chronic_opioids_ever as CHRON_OPe
		on DEMO.PATID = CHRON_OPe.PATID and DEMO.EventYear = CHRON_OPe.EventYear
	left join dmlocal.cancer_proc_events_cy as CA_PROC_CY
		on DEMO.PATID = CA_PROC_CY.PATID AND DEMO.EventYear = CA_PROC_CY.EventYear
	left join dmlocal.mental_health_events_cy as MH_CY
		ON DEMO.PATID = MH_CY.PATID AND DEMO.EventYear = MH_CY.EventYear
	left join dmlocal.bup_events_cy as BUP_CY
		on DEMO.PATID = BUP_CY.PATID and DEMO.EventYear = BUP_CY.EventYear
	left join dmlocal.bup_events_ever as BUP_CYe
		on DEMO.PATID = BUP_CYe.PATID and DEMO.EventYear = BUP_CYe.EventYear
	left join dmlocal.naltrex_events_cy as NALTREX_CY
		on DEMO.PATID = NALTREX_CY.PATID and DEMO.EventYear = NALTREX_CY.EventYear
	left join dmlocal.naltrex_events_ever as NALTREX_CYe
		on DEMO.PATID = NALTREX_CYe.PATID and DEMO.EventYear = NALTREX_CYe.EventYear
	left join dmlocal.methadone_events_cy as METH_CY
		on DEMO.PATID = METH_CY.PATID and DEMO.EventYear = METH_CY.EventYear
	left join dmlocal.encounter_events as ENC_EVENT
		on DEMO.PATID = ENC_EVENT.PATID and DEMO.EventYear = ENC_EVENT.EventYear
	left join dmlocal.nalox_opioid_co_rx as NAL_CORX
		on DEMO.PATID = NAL_CORX.PATID and DEMO.EventYear = NAL_CORX.EventYear
	left join dmlocal.zips as Z
		on DEMO.facility_location=Z.zip3
WHERE DEMO.AgeAsOfJuly1 >= 0  
  ;
QUIT;
*GL_A_DENOM_FOR_ST_rev and GL_B_DENOM_FOR_ST_rev are reverse codes for GL_A_DENOM_FOR_ST and GL_B_DENOM_FOR_ST so that when we use the arrays to 
set missing to 0 later it would make sense that 1=cancer and 0=no cancer.
At the end they are reverted back to GL_A_DENOM_FOR_ST and GL_B_DENOM_FOR_ST so that 1=no cancer and 0=cancer;

/*
proc sql inobs=max;
	create table dmlocal.QA as
	select PATID, EventYear, count(*) as Qty
	from dmlocal.opioid_flat_file as F
	group by PATID, EventYear
	having count(*) > 1
	;
quit;
*/


*labels;
data dmlocal.opioid_flat_file;
	set dmlocal.opioid_flat_file;
	label ENCOUNTERID='Encounter ID';
label FACILITY_LOCATION='Zip Code - most frequent zip code for encounter-year, use recency to break ties.';
label RX_PROVIDERID='RX_PROVIDERID';
label STATE='STATE - use crosswalk ';
label PRIOR_YEAR_ENCOUNTER='Prior Year Encounter Y/N';
label PATID='Patient_ID ';
label RACE='Race ';
label SEX='Sex ';
label HISPANIC='Ethnicity ';
label AgeAsOfJuly1='Age (calculated by patient age for majority of calendar year) ';
label AGEGRP1='AGEGROUP (must be derived)';
/*label AGEGRP2='AGEGROUP (must be derived)';*/
label EventYear='Year ';
label PRESCRIBINGID='PRESCRIBINGID ';
/*label OpioidInYearPrior='(Y/N) Was there opioid order or fill in the 365 days prior to index date';*/
label LOOKBACK_BEFORE_INDEX_OPIOID='Clean period (days between first observation in data set and first observed exposure)';
label ADMIT_DATE='Index diagnostic (qualifying for prevalance denominator) encounter date';
label IndexDate='Index date for event year (date of first opioid prescription, dispensation, or diagnostic encounter)';
label FirstOpioidDate='The first Opioid prescription or dispensation date for the patient for all time.';
label RX_ORDER_DATE='Index opioid Prescription date ';
label Opioid_Prescription='NON-inpatient Opioid Prescription during calendar year (Y/N)-1st prescription for the year ';
/*label OPIOID_NAIVE_90D_0='Captures non-chronic opioid users that got an opioid: if ANY Opioid_Prescription = Y AND NOT an opioid prescription with a start date < 91 days (including prior calendar year) and NOT prior OPIOID_CHRONIC_90D within 728, if count is 0';
label OPIOID_NAIVE_90D_1='Captures non-chronic opioid users that got an opioid: if ANY Opioid_Prescription = Y AND NOT an opioid prescription with a start date < 91 days (including prior calendar year) and NOT prior OPIOID_CHRONIC_90D within 728, if count is 1';
label OPIOID_NAIVE_90D_2='Captures non-chronic opioid users that got an opioid: if ANY Opioid_Prescription = Y AND NOT an opioid prescription with a start date < 91 days (including prior calendar year) and NOT prior OPIOID_CHRONIC_90D within 728, if count is 2';
label OPIOID_NAIVE_90D_3='Captures non-chronic opioid users that got an opioid: if ANY Opioid_Prescription = Y AND NOT an opioid prescription with a start date < 91 days (including prior calendar year) and NOT prior OPIOID_CHRONIC_90D within 728, if count is 3';
label OPIOID_NAIVE_90D_4='Captures non-chronic opioid users that got an opioid: if ANY Opioid_Prescription = Y AND NOT an opioid prescription with a start date < 91 days (including prior calendar year) and NOT prior OPIOID_CHRONIC_90D within 728, if count is >=4';
label OPIOID_TRANS_180D_0='Intended to capture naive patients that get a second prescription, putting them at risk for chronic use. Any interval between prescriptions less than 90 days. EXCLUDING patients that have been previously labled as chronic in last 728 days, including this prescription. If count is 0.';
label OPIOID_TRANS_180D_1='Intended to capture naive patients that get a second prescription, putting them at risk for chronic use. Any interval between prescriptions less than 90 days. EXCLUDING patients that have been previously labled as chronic in last 728 days, including this prescription. If count is 1.';
label OPIOID_TRANS_180D_2='Intended to capture naive patients that get a second prescription, putting them at risk for chronic use. Any interval between prescriptions less than 90 days. EXCLUDING patients that have been previously labled as chronic in last 728 days, including this prescription. If count is 2.';
label OPIOID_TRANS_180D_3='Intended to capture naive patients that get a second prescription, putting them at risk for chronic use. Any interval between prescriptions less than 90 days. EXCLUDING patients that have been previously labled as chronic in last 728 days, including this prescription. If count is 3.';
label OPIOID_TRANS_180D_4='Intended to capture naive patients that get a second prescription, putting them at risk for chronic use. Any interval between prescriptions less than 90 days. EXCLUDING patients that have been previously labled as chronic in last 728 days, including this prescription. If count is >=4.';*/
/*label OPIOID_CHRONIC_90D='Opioid_Prescription = Y AND Opioid prescription with a start date > 1 day (from Opioid_Prescription Date) and next 2 previous intervals are < 91 days';*/
/*label FIRST_EVER_OP_CHRON_90D='First lifetime Opioid_Chronic_90D (1 in first year, 0 otherwise)';*/
label DISPENSE_DATE='Dispense date';
label Opioid_Dispensation='Two or more opioid prescriptions with two different start dates both > 1 day and < 91 days';
label OPIOID_FLAG='Opioid Prescription or Dispensation (Y/N)';
label Cancer_AnyEnc_Dx_Year_Prior='Cancer any encounter Dx Inpatient in Year Prior (Y/N)';
/*label Cancer_Inpt_Dx_Year_Prior='Cancer Dx Inpatient in Year Prior (Y/N)';*/
label Cancer_inpt_Dx_CY='ANY MEMBER OF CANCER DX VALUE SET IN INPATIENT VISIT (MISSING IF NOT OBSERVATION PERIOD)';
label CANCER_PX_CURRENT_YEAR='ANY MEMBER OF CANCER PROCEDURE VALUE SET CURRENT YEAR';
label GL_A_DENOM_FOR_ST='PATIENTS WITHOUT CANCER DX IN THE CURRENT YEAR CANCER_ANY_ENC (renamed cancer_anyencount_cy, at bottom of spreadsheet)';
label GL_B_DENOM_FOR_ST='PATIENTS WITHOUT INPATIENT CANCER DX **OR** CANCER PROCEDURE IN THE CURRENT YEAR Cancer_inpt_Dx_CY AND CANCER_PX_CURRENT_YEAR (renamed cancer_inpt_dx_cy, at bottom of spreadsheet)';
label Cannabis_UD_Any_CY='1 if patient is "active" in data in current year and CANO_UD diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';
label Cocaine_UD_Any_CY='1 if patient is "active" in data in current year and COCA_UD diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';
label Other_Stim_UD_Any_CY='1 if patient is "active" in data in current year and STIM_UD diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';
label Hallucinogen_UD_Any_CY='1 if patient is "active" in data in current year and HALL_UD diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';
label Inhalant_UD_Any_CY='1 if patient is "active" in data in current year and INHL_UD diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';
label SedHypAnx_UD_Any_CY='1 if patient is "active" in data in current year and S_HYP_UD diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';
label HepB_Dx_Any_CY='1 if patient is "active" in data in current year and HepB diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';
label HepC_Dx_Any_CY='1 if patient is "active" in data in current year and HepC diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';
/*label CANCER_PROC_FLAG='Cancer Procedure in Year prior (Y/N) → within 365 days before index anchor ';*/
label MH_Dx_Pri_CY='1 not missing from observable data and match MH value set, 0 if patient is observed that year w/o MH dx';
label MH_Dx_Exp_CY='Mental health exploratory calendar year';
/*label MH_Dx_Pri_Year_Prior='Mental Health Dx Primary in year prior (Y/N) → 365 days before index anchor ';*/
/*label MH_Dx_Pri_Any_Prior='Mental Health Dx Primary any prior (Y/N) ';*/
/*label MH_Dx_Exp_Year_Prior='Mental Health Dx Exploratory in year prior (Y/N) → 365 days before index anchor ';*/
/*label MH_Dx_Exp_Any_Prior='Mental Health Dx Exploratory any prior to index exposure (Y/N) ';*/
/*label Alcohol_Use_DO_Year_Prior='Alcohol Use Disorder Dx in year prior (Y/N) → 365 days before index anchor';*/
label Alcohol_Use_DO_Any_Prior='Alcohol Use Disorder Dx any prior (Y/N)';
label Alcohol_Use_DO_Post_Date='First Alcohol Use Disorder Date after IndexDate';
/*label Substance_Use_DO_Year_Prior='Substance Use Disorder Year Prior (Y/N) → 365 days before index anchor';*/
label Substance_Use_DO_Any_Prior='Substance Use Disorder Dx any prior (Y/N)';
label Substance_Use_DO_Post_Date='First Substance Use Disorder Date after IndexDate';
/*label Opioid_Use_DO_Year_Prior='Opioid Use Disorder Year Prior (Y/N) → 365 days before index anchor';*/
label Opioid_Use_DO_Any_Prior='Opioid Use Disorder Dx any prior (Y/N)';
label Opioid_Use_DO_Post_date='First Opioid Use Disorder Date after IndexDate';
label TimeFromIndexOpioidToOUD='Opioid_Use_DO_Post_date - FirstOpioidDate';
label OUD_Post_Opioid_Exp='OUD_Post_Opioid_Exp';
/*label Cannabis_Use_DO_Year_Prior='Cannabis Use Disorder Year Prior (Y/N) → 365 days before index anchor';*/
label Cannabis_Use_DO_Any_Prior='Cannabis Use Disorder Dx any prior (Y/N)';
label Cannabis_Use_DO_Post_Date='First Cannabis Use Disorder Date after IndexDate';
/*label Cocaine_Use_DO_Year_Prior='Cocaine Use Disorder Year Prior (Y/N) → 365 days before index anchor';*/
label Cocaine_Use_DO_Any_Prior='Cocaine Use Disorder Dx any prior (Y/N)';
label Cocaine_Use_DO_Post_Date='First Cocaine Use Disorder Date after IndexDate';
/*label Halluc_Use_DO_Year_Prior='Hallucinogen Use Disorder Year Prior (Y/N) → 365 days before index anchor';*/
/*label Halluc_Use_DO_Any_Prior='Hallucinogen Use Disorder Dx any prior (Y/N)';*/
label Halluc_Use_DO_Post_Date='First Hallucinogen Use Disorder Date after IndexDate';
/*label Inhalant_Use_DO_Year_Prior='Inhalant Use Disorder Year Prior (Y/N) → 365 days before index anchor';*/
label Inhalant_Use_DO_Any_Prior='Inhalant Use Disorder Dx any prior (Y/N)';
label Inhalant_Use_DO_Post_Date='First Inhalant Use Disorder Date after IndexDate';
/*label Other_Stim_Use_DO_Year_Prior='Other Stimulant Use Disorder Year Prior (Y/N) → 365 days before index anchor';*/
label Other_Stim_Use_DO_Any_Prior='Other Stimulant Use Disorder Dx any prior (Y/N)';
label Other_Stim_Use_DO_Post_Date='First Other Stimulant Use Disorder Date after IndexDate';
/*label SedHypAnx_Use_DO_Year_Prior='Sedative/Hypnotic/Anxiolytic Use Disorder Year Prior (Y/N) → 365 days before index anchor';*/
label SedHypAnx_Use_DO_Any_Prior='Sedative/Hypnotic/Anxiolytic Use Disorder Dx any prior (Y/N)';
label SedHypAnx_Use_DO_Post_Date='First Sedative/Hypnotic/Anxiolytic Use Disorder Date after IndexDate';
label Opioid_UD_Any_CY='1 if patient is "active" in data in current year and OUD diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';
label Alcohol_UD_Any_CY='1 if patient is "active" in data in current year and AUD diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';
label Substance_UD_Any_CY='1 if patient is "active" in data in current year and SUD diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';
label OUD_SUD_IND='GL_B_DENOM_FOR_ST=1 and (Opioid_UD_Any_CY=1 or Substance_UD_Any_CY=1 or HIV_Dx_Any_CY=1 or OUD_SUD_CY=1)';
label HIV_Dx_Any_CY='1 if patient is "active" in data in current year and HIV diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';
/*label MAT_ANY_CY='1 if patient is "active" in data in current year and MAT diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';*/
/*label HIV_HBV_HBC_CY='1 if patient is "active" in data in current year and HIV, HBV, or HCV diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';*/
label Opioid_UD_Any_everCY='1 if patient is "active" in data in current year or any prior and OUD diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';
label Alcohol_UD_Any_everCY='1 if patient is "active" in data in current year or any prior and AUD diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';
label Substance_UD_Any_everCY='1 if patient is "active" in data in current year or any prior and SUD diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';
label OUD_SUD_everCY='max of EVER_OUD and EVER_SUD';
label OUD_SUD_CY='OUD or SUD current calendar year';
/*label HIV_Dx_Any_everCY='1 if patient is "active" in data in current year or any prior HIV diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';*/
/*label HepB_Dx_Any_everCY='1 if patient is "active" in data in current year or any prior and HBV diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';*/
/*label HepC_Dx_Any_everCY='1 if patient is "active" in data in current year or any prior   and HCV diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';*/
/*label MAT_ANY_everCY='1 if patient is "active" in data in current year current year or any prior  and MAT diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';*/
/*label HIV_HBV_HBC_everCY='1 if patient is "active" in data in current year current year or any prior  and HIV, HBV, or HCV diagnosis value is observed, 0 if it is not observed, missing if patient is not in data in year ';*/
label BINARY_RACE='Binary Race (White vs. Non-White)';
label BINARY_HISPANIC='Binary HISPANIC (HISPANIC vs. OTHER)';
label DEATH_DATE='Date of death';
label ZOMBIE_FLAG='Flag for date of death PRIOR to event year index encounter';
label FATAL_OVERDOSE='Fatal Overdose → Will only have date of death, cause of death not integrated into PCORI. In addition, will likely only have death as discharge disposition (not external death). Try deceased + OUD DX same date.';
label DaysToDeath='Time elapsed between opioid exposure & death';
label DEATH_COMPLETE='Externally available death data at site in curent year?';
/*label ED_OD_PRE='Nonfatal accidental Overdose (ED visit administrative code) prior to index exposure';
label ED_OD_PRE_DATE='Nonfatal accidental Overdose date (ED visit administrative code) prior to index exposure';*/
/*label ED_OD_POST='Nonfatal accidental Overdose (ED visit administrative code) after index exposure';
label ED_OD_POST_DATE='Nonfatal accidental Overdose date (ED visit administrative code) after index exposure';*/
label OD_PRE='Any accidental overdose prior to index exposure';
label OD_PRE_DATE='Date of last accidental overdose prior to index exposure';
/*label OD_POST='Any accidental overdose after index exposure';
label OD_POST_DATE='Date of first accidental overdose after index exposure';*/
label NONFATAL_OD_CY='NONFATAL Accidental OD CURRENT YEAR';
label OD_CY='Any OD current year';
/*label SUICIDE_PRE='Any suicide attempt prior to index exposure';
label SUICIDE_PRE_DATE='Date of last suicide attempt prior to index exposure';*/
/*label SUICIDE_POST='Any suicide attempt after index exposure';
label SUICIDE_POST_DATE='Date of first suicide attempt after index exposure';*/
label SUICIDE_SH_ATTEMPT_CY='any suicide or self harm attempt in thecurrent calendar year';
label SMOKING='Smoking';
label CHRONIC_OPIOID_DATE='index date of non-inpatient chronic opioid use';
label CHRONIC_OPIOID='Chronic Opioids any 3 non inpatient opioid {3 rx or 3 disp.} with third one in current calendar year';
label CHRONIC_OPIOID_CURR_PRIOR='chronic opioids current or prior year';
label CHRONIC_OPIOID_everCY='1 if date is greater than first CHRONIC_OPIOID_DATE, 0 otherwise, missing if patient is not observed Clarified with Daniella to be year(chronic_opioid_date)<=eventyear.';
label CHRONIC_OPIOID_CY='Based on a meeting iwth Daniella, I also added year(chronic_opioid_date)=eventyear';
/*label HIV_Dx_Year_Prior='HIV year prior (365 days)';*/
/*label HIV_Dx_Any_Prior='HIV any prior';*/
label HIV_Dx_Post_Date='HIV any time after index exposure';
/*label HepB_Dx_Year_Prior='Hep B year prior (365 days)';*/
/*label HepB_Dx_Any_Prior='Hep B any prior';*/
label HepB_Dx_Post_Date='Hepatitis B Virus any time after index exposure';
/*label HepC_Dx_Year_Prior='Hep C year prior (365 days)';*/
/*label HepC_Dx_Any_Prior='Hep C any prior';*/
label HepC_Dx_Post_Date='Hepatitis C Virus any time after index exposure';
/*label ANY_STD_Year_Prior='any HIV, HEPB, HEPC, current or prior year';*/
label UDS_CPT='Urine Drug Screen by CPT code (Y/N/NA) in the year NA if none of these codes appear in the organization-year.';
label UDS_LOINC='Urine Drug Screen by LOINC code (Y/N/NA) (LOINC codes were not in the LOINC to include so they will not be in VA Result data which was pulled by LOINC codes, Louisiana thought they did have drug screens in their data) NA if site does not capture LOINC codes of any kind.';
label UDS_FLAG='Urine Drug Screen (Y/N/NA) → merged result of CPT and LOINC code variables ';
label NALOXONE_INFERRED_RESCUE='Naloxone ED Prescription or Dispensing or Admin (Y/N)';
label NALOXONE_PRESCRIBE_RESCUE='Naloxone Prescription (y/n)';
label NALOXONE_DISPENSE_RESCUE='Naloxone Dispensation (Y/N)';
label NALOXONE_ADMIN_RESCUE='Naloxone MED_ADMIN for sites that have med admin only';
label NALOX_AMBULATORY='Naloxone in ambulatory (dispensing or prescribing, but not admin) (y/n)';
label NALOX_AMBULATORY_DATE='Naloxone in ambulatory (dispensing or prescribing, but not admin) first event date for EventYear';
label NALOX_OPIOID_CO_RX='1 if ANY records where patient-date of Opioid Value Set match in PRESCRIBING table is same as naloxone_ambulatory (not just the first of the year, but any time in  year), 0 otherwise';
label CT_NALOXONE_RESCUE='Count of Any Naloxone Rescue';
label ED_YR='ED visit current year';
label IP_YR='IP visit current year';
/*label ED_IP_YR='ED or IP visit in current year';*/
/*label ANY_ENC_CY='ANY encoutner current_year (should be 0 if patient is not in the observation period)'; */
/*label BDZ_Presc_3mo='Benzodiazepine Prescription +/- 3 months of IndexDate';
label BDZ_Disp_3mo='Benzodiazepine Dispensation +/- 3 months of IndexDate';*/
label BDZ_CY ='Benzodiazepine Rx or dispense within the calendar year';
label BDZ_Opioid_CoOccurr_CY = 'Benzo/Opioid co prescribing or dispensing in calendar year';
/*label BUP_PRESC_PRE='Buprenorphine Prescription in 365 days prior to index date (Y/N)';
label BUP_PRESC_PRE_DATE='Date of last Buprenorphine Prescription in the 365 days prior to index date';
label BUP_PRESC_POST='Buprenorphine Prescription in 365 days after index date (Y/N)';
label BUP_PRESC_POST_DATE='Date of first Buprenorphine Prescription in the 365 days after index date';*/
/*label BUP_DISP_PRE='Buprenorphine Dispensation in 365 days prior to index date(Y/N)';
label BUP_DISP_PRE_DATE='Date of last Buprenorphine Dispensation in the 365 days prior to index date';
label BUP_DISP_POST='Buprenorphine Dispensation in 365 days after index date(Y/N)';
label BUP_DISP_POST_DATE='Date of first Buprenorphine Dispensation in the 365 days after index date';*/
label BUP_ANY_CY='Any Buprenorphine RX or DISP in current calendar year';
label BUP_DISP_CY='Any Buprenorphine DISP in current calendar year';
label BUP_PRESC_CY='Any Buprenorphine RX in current calendar year';
label BUP_DISP_everCY='Any Buprenorphine DISP ever in current calendar year';
label BUP_PRESC_everCY='Any Buprenorphine RX ever in current or prior CY';
label NALTREX_ANY_CY='ANY Naltrexone RX or DISP in Current year';
label NALTREX_DISP_CY='ANY Naltrexone DISP in Current year';
label NALTREX_PRESC_CY='ANY Naltrexone RX in Current year';
label NALTREX_DISP_everCY='ANY Naltrexone DISP ever  in Current year';
label NALTREX_PRESC_everCY='ANY Naltrexone RX ever in Current year';
/*label METHADONE_ANY_CY='ANY Methodone/RX or DISP in current year';*/
label NALTREX_PRESC_PRE='Naltrexone Prescription in 365 days prior to index date (Y/N)';
label NALTREX_PRESC_PRE_DATE='Date of last Naltrexone Prescription in the 365 days prior to index date';
label NALTREX_PRESC_POST='Naltrexone Prescription in 365 days after index date (Y/N)';
label NALTREX_PRESC_POST_DATE='Date of first Naltrexone Prescription in the 365 days after index date';
label NALTREX_DISP_PRE='Naltrexone Dispensation in 365 days prior to index date(Y/N)';
label NALTREX_DISP_PRE_DATE='Date of last Naltrexone Dispensation in the 365 days prior to index date';
/*label NALTREX_DISP_POST='Naltrexone Dispensation in 365 days after index date(Y/N)';
label NALTREX_DISP_POST_DATE='Date of first Naltrexone Dispensation in the 365 days after index date';*/
/*label METHADONE_PRESC_PRE='Methadone Prescription in 365 days prior to index date (Y/N)';
label METHADONE_PRESC_PRE_DATE='Date of last Methadone Prescription in the 365 days prior to index date';*/
/*label METHADONE_PRESC_POST='Methadone Prescription in 365 days after index date (Y/N)';
label METHADONE_PRESC_POST_DATE='Date of first Methadone Prescription in the 365 days after index date';*/
/*label METHADONE_DISP_PRE='Methadone Dispensation in 365 days prior to index date(Y/N)';
label METHADONE_DISP_PRE_DATE='Date of last Methadone Dispensation in the 365 days prior to index date';*/
/*label METHADONE_DISP_POST='Methadone Dispensation in 365 days after index date(Y/N)';
label METHADONE_DISP_POST_DATE='Date of last Methadone Dispensation in the 365 days prior to index date';*/
label Cancer_AnyEncount_CY='Cancer any encounter calendar year';
label CHRONIC_OPIOID_IND='chronic_opioid_cy=1 and gl_b_denom_for_st=1';
label CT_NALOXONE_ADMIN_CUI='Naloxone admin CUI count';
label CT_NALOXONE_ADMIN_NDC='Naloxone admin ndc count';
label CT_NALOXONE_DISPENSE='naclxone dispense count';
label CT_NALOXONE_PRESCRIBE='Naloxone prescribe count';
label BIRTH_DATE='Birth date';
/*label Chemo_AnyEncount_Year_Prior='Chemo any encounter year prior';*/
label DISPENSINGID='Dispensing ID';
label DataMartID='Datamart ID';
label ED_OD_CY='ED OD calendar year';
label ENC_TYPE='Encounter type';
/*label enr_start_date='Enrollment start date';*/
label PRESCRIBING_NDC='Prescribing NDC';
label RXNORM_CUI='RxNorm CUI';
/*label RAD_ANYENCOUNT_YEAR_PRIOR='Radiation any encounter year prior';*/
label OPIOID_EXP_IND='OPIOID_FLAG=1 and GL_B_DENOM_FOR_ST=1';
label oud_ind='Opioid_UD_Any_CY=1 and GL_B_DENOM_FOR_ST=1';
label substance_ind='Substance_UD_Any_CY=1 and GL_B_DENOM_FOR_ST=1';
label alcohol_ind='Alcohol_UD_Any_CY=1 and GL_B_DENOM_FOR_ST=1';
label overdose_IND='GL_B_DENOM_FOR_ST=1 and (OD_CY=1)';
/*label enrolled='Indicates year a patient is enrolled, includes all years between enrollment start and end date.';*/
run;


*clean up;
/*
proc sql;
	drop table dmlocal.aesop1, dmlocal.aesop2, dmlocal.aesop3, dmlocal.aesop4, dmlocal.aesop5, dmlocal.aesop6, dmlocal.aesop7, dmlocal.aesop8,
		dmlocal.opioid_flat_file_pre, dmlocal.opioid_flat_file_pre2, dmlocal.opioid_flat_file_pre3, dmlocal.opioid_flat_file_pre4,
		dmlocal.opioid_flat_file_pre5;
quit;
*/
