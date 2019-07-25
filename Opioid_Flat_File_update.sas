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
PROC SQL inobs=max;
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
	, max(case when Ca.Code is not NULL then 1 else 0 end)
		as Cancer_AnyEncount_Dx_Year_Prior
	, max(case when Ca.Code is not NULL and E.ENC_TYPE = 'IP' 
		and Dx.ADMIT_DATE >= E.ADMIT_DATE
		and Dx.ADMIT_DATE <= coalesce(E.DISCHARGE_DATE, E.ADMIT_DATE) then 1 else 0 end)
		as Cancer_Inpt_Dx_Year_Prior
from indata.diagnosis as Dx
	join infolder.cancerdx as Ca
		on Dx.DX_TYPE = Ca.DX_TYPE
			and Dx.DX = Ca.Code
	join indata.encounter as E
		on Dx.PATID = E.PATID
	right join dmlocal.patientevents as PE
		on Dx.PATID = PE.PATID
			and Dx.ADMIT_DATE >= INTNX('day', PE.IndexDate, -365, 'same')
			and Dx.ADMIT_DATE <= PE.IndexDate
group by PE.PATID, PE.EventYear
order by PE.PATID, PE.EventYear
;
RUN;
QUIT;



*New -- calendar year data (Cancer_AnyEncount_CY, Cancer_Inpt_Dx_CY);
* Create SAS data file dmlocal.cancer_dx_events_cy;
PROC SQL inobs=max;
CREATE TABLE dmlocal.cancer_dx_events_cy as
select PE.PATID
	, PE.EventYear
	, max(case when Ca.Code is not NULL then 1 else 0 end)
		as Cancer_AnyEncount_CY
	, max(case when Ca.Code is not NULL and E.ENC_TYPE = 'IP' 
		and Dx.ADMIT_DATE >= E.ADMIT_DATE
		and Dx.ADMIT_DATE <= coalesce(E.DISCHARGE_DATE, E.ADMIT_DATE) then 1 else 0 end)
		as Cancer_Inpt_Dx_CY
from indata.diagnosis as Dx
	join infolder.cancerdx as Ca
		on Dx.DX_TYPE = Ca.DX_TYPE
			and Dx.DX = Ca.Code
	join indata.encounter as E
		on Dx.PATID = E.PATID
	right join dmlocal.patientevents as PE
		on Dx.PATID = PE.PATID
			and year(Dx.ADMIT_DATE) = PE.EventYear
group by PE.PATID, PE.EventYear
order by PE.PATID, PE.EventYear
;
RUN;
QUIT;


* Create SAS data file dmlocal.cancer_proc_events;
PROC SQL inobs=max;
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
PROC SQL inobs=max;
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


* New -- calendar year data (MH_Dx_Pri_CY, MH_Dx_Exp_CY);
* Create SAS data file dmlocal.mental_health_events_cy;
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
	Opioid_UD_Any_CY, Alcohol_UD_Any_CY, Substance_UD_Any_CY, Opioid_UD_Any_everCY, Alcohol_UD_Any_everCY, Substance_UD_Any_everCY, OUD_SUD_everCY ;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.substance_use_do_events AS
select PE.PATID, PE.EventYear
	, max(case when SU.Code_List_1 = 'Alcohol Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as Alcohol_Use_DO_Year_Prior
	, max(case when SU.Code_List_1 = 'Alcohol Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as Alcohol_Use_DO_Any_Prior
	, min(case when SU.Code_List_1 = 'Alcohol Use Disorder'
		and Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as Alcohol_Use_DO_Post_Date
	, max(case when SU.Code_List_1 = 'Alcohol Use Disorder'
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as Alcohol_UD_Any_CY /*new*/
	, max(case when SU.Code_List_1 = 'Alcohol Use Disorder'
		and year(Dx.ADMIT_DATE) <= PE.EventYear then 1 else 0
		end) as Alcohol_UD_Any_everCY /*new*/
	, max(case when (SU.Code_List_1 = 'Substance Use Disorder' or SU.Code_List_2 = 'Substance Use Disorder')
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as Substance_Use_DO_Year_Prior
	, max(case when (SU.Code_List_1 = 'Substance Use Disorder' or SU.Code_List_2 = 'Substance Use Disorder')
		and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as Substance_Use_DO_Any_Prior
	, min(case when (SU.Code_List_1 = 'Substance Use Disorder' or SU.Code_List_2 = 'Substance Use Disorder')
		and Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as Substance_Use_DO_Post_Date
	, max(case when (SU.Code_List_1 = 'Substance Use Disorder' or SU.Code_List_2 = 'Substance Use Disorder')
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as Substance_UD_Any_CY /*new*/
	, max(case when (SU.Code_List_1 = 'Substance Use Disorder' or SU.Code_List_2 = 'Substance Use Disorder')
		and year(Dx.ADMIT_DATE) <= PE.EventYear then 1 else 0
		end) as Substance_UD_Any_everCY /*new*/
	, max(case when SU.Code_List_1 = 'Opioid Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as Opioid_Use_DO_Year_Prior
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
		and year(Dx.ADMIT_DATE) <= PE.EventYear then 1 else 0
		end) as Opioid_UD_Any_everCY /*new*/
	, max(calculated Substance_UD_Any_everCY, calculated Opioid_UD_Any_everCY)
		as OUD_SUD_everCY /*new*/
	, max(case when SU.Code_List_2 = 'Cannabis Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as Cannabis_Use_DO_Year_Prior
	, max(case when SU.Code_List_2 = 'Cannabis Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as Cannabis_Use_DO_Any_Prior
	, min(case when SU.Code_List_2 = 'Cannabis Use Disorder'
		and Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as Cannabis_Use_DO_Post_Date
	, max(case when SU.Code_List_2 = 'Cannabis Use Disorder'
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as Cannabis_UD_Any_CY /*new*/
	, max(case when SU.Code_List_2 = 'Cocaine Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as Cocaine_Use_DO_Year_Prior
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
	, max(case when SU.Code_List_2 = 'Inhalant Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as Inhalant_Use_DO_Year_Prior
	, max(case when SU.Code_List_2 = 'Inhalant Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as Inhalant_Use_DO_Any_Prior
	, min(case when SU.Code_List_2 = 'Inhalant Use Disorder'
		and Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as Inhalant_Use_DO_Post_Date
	, max(case when SU.Code_List_2 = 'Inhalant Use Disorder'
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as Inhalant_UD_Any_CY /*new*/
	, max(case when SU.Code_List_2 = 'Other Stimulant Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as Other_Stim_Use_DO_Year_Prior
	, max(case when SU.Code_List_2 = 'Other Stimulant Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as Other_Stim_Use_DO_Any_Prior
	, min(case when SU.Code_List_2 = 'Other Stimulant Use Disorder'
		and Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as Other_Stim_Use_DO_Post_Date
	, max(case when SU.Code_List_2 = 'Other Stimulant Use Disorder'
		and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as Other_Stim_UD_Any_CY /*new*/
	, max(case when SU.Code_List_2 = 'S/H/A Use Disorder'
		and Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as SedHypAnx_Use_DO_Year_Prior
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



* Create SAS data file rcr.hepb_events;
*new variables added: HepB_Dx_Any_CY, HepB_Dx_Any_everCY;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.hepb_events AS
select PE.PATID
	, PE.EventYear
	, max(case when Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as HepB_Dx_Year_Prior
	, max(case when Dx.ADMIT_DATE IS NOT NULL and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0 
		end) as HepB_Dx_Any_Prior   								/* null exclusion added by SKP 3/6/2019 */
	, min(case when Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as HepB_Dx_Post_Date
	, max(case when Dx.ADMIT_DATE IS NOT NULL and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0  /*new--null exclusion kept*/
		end) as HepB_Dx_Any_CY 
	, max(case when Dx.ADMIT_DATE IS NOT NULL and year(Dx.ADMIT_DATE) <= PE.EventYear then 1 else 0  /*new--null exclusion kept*/
		end) as HepB_Dx_Any_everCY 
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


* Create SAS data file dmlocal.hepc_events;
*new variables added: HepC_Dx_Any_CY, HepC_Dx_Any_everCY ;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.hepc_events AS
select PE.PATID
	, PE.EventYear
	, max(case when Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE > PE.YearPriorDate then 1 else 0
		end) as HepC_Dx_Year_Prior
	, max(case when Dx.ADMIT_DATE IS NOT NULL and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0 
		end) as HepC_Dx_Any_Prior  								/* null exclusion added by SKP 3/6/2019 */
	, min(case when Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as HepC_Dx_Post_Date
	, max(case when Dx.ADMIT_DATE IS NOT NULL and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0  /*new--null exclusion kept*/
		end) as HepC_Dx_Any_CY 	
	, max(case when Dx.ADMIT_DATE IS NOT NULL and year(Dx.ADMIT_DATE) <= PE.EventYear then 1 else 0  /*new--null exclusion kept*/
		end) as HepC_Dx_Any_everCY 
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


* Create SAS data file dmlocal.hiv_events;
*new variables added: HIV_Dx_Any_CY, HIV_Dx_Any_everCY ;
PROC SQL inobs=max;
  CREATE TABLE dmlocal.hiv_events AS
select PE.PATID
	, PE.EventYear
	, max(case when Dx.ADMIT_DATE <= PE.IndexDate and Dx.ADMIT_DATE >= PE.YearPriorDate then 1 else 0
		end) as HIV_Dx_Year_Prior
	, max(case when Dx.ADMIT_DATE IS NOT NULL and Dx.ADMIT_DATE <= PE.IndexDate then 1 else 0
		end) as HIV_Dx_Any_Prior 								/* null exclusion added by SKP 3/6/2019 */
	, min(case when Dx.ADMIT_DATE >= PE.IndexDate then Dx.ADMIT_DATE
		end) as HIV_Dx_Post_Date
	, max(case when Dx.ADMIT_DATE IS NOT NULL and year(Dx.ADMIT_DATE) = PE.EventYear then 1 else 0
		end) as HIV_Dx_Any_CY  /*new*/
	, max(case when Dx.ADMIT_DATE IS NOT NULL and year(Dx.ADMIT_DATE) <= PE.EventYear then 1 else 0
		end) as HIV_Dx_Any_everCY  /*new*/
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


* Create SAS data file dmlocal.bup_events;
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


* New -- calendar year data (BUP_PRESC_CY, BUP_DISP_CY, BUP_PRESC_everCY, BUP_DISP_everCY);
* Create SAS data file dmlocal.bup_events_cy;
PROC SQL inobs=max;
CREATE TABLE dmlocal.bup_events_cy as
select PE.PATID
	, PE.EventYear
	, MAX(CASE WHEN PRESC.RX_ORDER_DATE IS NOT NULL and year(PRESC.RX_ORDER_DATE) = PE.EventYear then 1 else 0 
	  end) as BUP_PRESC_CY /*new*/
	, MAX(CASE WHEN DISP.DISPENSE_DATE IS NOT NULL and year(DISP.DISPENSE_DATE) = PE.EventYear then 1 else 0 
	  end) as BUP_DISP_CY /*new*/
	, MAX(CASE WHEN PRESC.RX_ORDER_DATE IS NOT NULL and year(PRESC.RX_ORDER_DATE) <= PE.EventYear then 1 else 0 
	  end) as BUP_PRESC_everCY /*new*/
	, MAX(CASE WHEN DISP.DISPENSE_DATE IS NOT NULL and year(DISP.DISPENSE_DATE) <= PE.EventYear then 1 else 0 
	  end) as BUP_DISP_everCY /*new*/
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


* Create SAS data file dmlocal.naltrex_events;
PROC SQL inobs=max;
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


* New -- calendar year data (NALTREX_PRESC_CY, NALTREX_DISP_CY, NALTREX_PRESC_everCY, NALTREX_DISP_everCY);
* Create SAS data file dmlocal.naltrex_events_cy;
PROC SQL inobs=max;
CREATE TABLE dmlocal.naltrex_events_cy as
select PE.PATID
	, PE.EventYear
	, max(case when PRESC.RX_ORDER_DATE IS NOT NULL and year(PRESC.RX_ORDER_DATE) = PE.EventYear then 1 else 0 
	  end) as NALTREX_PRESC_CY /*new*/
	, max(case when DISP.DISPENSE_DATE IS NOT NULL and year(DISP.DISPENSE_DATE) = PE.EventYear then 1 else 0 
	  end) as NALTREX_DISP_CY /*new*/
	, max(case when PRESC.RX_ORDER_DATE IS NOT NULL and year(PRESC.RX_ORDER_DATE) <= PE.EventYear then 1 else 0 
	  end) as NALTREX_PRESC_everCY /*new*/
	, max(case when DISP.DISPENSE_DATE IS NOT NULL and year(DISP.DISPENSE_DATE) <= PE.EventYear then 1 else 0 
	  end) as NALTREX_DISP_everCY /*new*/
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


* Create SAS data file dmlocal.methadone_events;
PROC SQL inobs=max;
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


* New -- calendar year data (METHADONE_ANY_CY);
* Create SAS data file dmlocal.methadone_events_cy;
PROC SQL inobs=max;
CREATE TABLE dmlocal.methadone_events_cy as
select PE.PATID
	, PE.EventYear
	, max(case when PRESC.RX_ORDER_DATE IS NOT NULL and (year(PRESC.RX_ORDER_DATE) = PE.IndexDate or year(DISP.DISPENSE_DATE) = PE.IndexDate) then 1 else 0 
	  end) as METHADONE_ANY_CY /*new*/
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
		END) AS BDZ_3MO
	, MAX(CASE WHEN PRESC.EventYear IS NOT NULL THEN 1 ELSE 0
		END) AS BDZ_Presc_3mo
	, MAX(CASE WHEN DISP.EventYear IS NOT NULL THEN 1 ELSE 0
		END) AS BDZ_Disp_3mo
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
		WHERE PRESC.RX_ORDER_DATE <= INTNX('month', PE.IndexDate, 3, 'same')
			AND PRESC.RX_ORDER_DATE >= INTNX('month', PE.IndexDate, -3, 'same')
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
		WHERE DISP.DISPENSE_DATE <= INTNX('month', PE.IndexDate, 3, 'same')
			AND DISP.DISPENSE_DATE >= INTNX('month', PE.IndexDate, -3, 'same')
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
*new variables added: OD_CY, ED_OD_CY;
PROC SQL inobs=max;
CREATE TABLE dmlocal.od_events as
select PE.PATID
	, PE.EventYear
	, max(case when OD.DX_DATE IS NOT NULL and OD.DX_DATE <= PE.IndexDate then 1 else 0 
	  end) as OD_PRE
	, max(case when OD.DX_DATE IS NOT NULL and year(OD.DX_DATE) = PE.EventYear then 1 else 0 
	  end) as OD_CY /*new*/
	, max(case when OD.DX_DATE <= PE.IndexDate 
		and OD.ENC_TYPE IN ('ED', 'EI') 
		and OD.DX_DATE >= OD.ADMIT_DATE
		and OD.DX_DATE <= OD.DISCHARGE_DATE then 1 else 0 end) as ED_OD_PRE
	, max(case when year(OD.DX_DATE) = PE.EventYear 
		and OD.ENC_TYPE IN ('ED', 'EI') 
		and OD.DX_DATE >= OD.ADMIT_DATE
		and OD.DX_DATE <= OD.DISCHARGE_DATE then 1 else 0 end) as ED_OD_CY /*new*/
	, max(case when OD.DX_DATE IS NOT NULL and OD.DX_DATE <= PE.IndexDate then OD.DX_DATE 
	  end) as OD_PRE_DATE
	, max(case when OD.DX_DATE <= PE.IndexDate 
		and OD.ENC_TYPE IN ('ED', 'EI') 
		and OD.DX_DATE >= OD.ADMIT_DATE 
		and OD.DX_DATE <= OD.DISCHARGE_DATE then OD.DX_DATE end)	as ED_OD_PRE_DATE
	, max(case when OD.DX_DATE >= PE.IndexDate then 1 else 0 end) as OD_POST
	, max(case when OD.DX_DATE >= PE.IndexDate
		and OD.ENC_TYPE IN ('ED', 'EI') 
		and OD.DX_DATE >= OD.ADMIT_DATE
		and OD.DX_DATE <= OD.DISCHARGE_DATE then 1 else 0 end) as ED_OD_POST
	, min(case when OD.DX_DATE >= PE.IndexDate then OD.DX_DATE end) as OD_POST_DATE
	, min(case when OD.DX_DATE >= PE.IndexDate 
		and OD.ENC_TYPE IN ('ED', 'EI') 
		and OD.DX_DATE >= OD.ADMIT_DATE
		and OD.DX_DATE <= OD.DISCHARGE_DATE then OD.DX_DATE end)	as ED_OD_POST_DATE
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


* Create SAS data file dmlocal.fatal_od;
*new variables added: NONFATAL_OD_CY;
PROC SQL inobs=max;
CREATE TABLE dmlocal.fatal_od as
select PY.PATID
	, PY.EventYear
	, max(case when D.DEATH_DATE is not NULL and D.DEATH_DATE = DIAG.ADMIT_DATE then 1
		when E.PATID is not NULL then 1
		else 0
		end) as FATAL_OVERDOSE
	, max(case when D.DEATH_DATE is NULL or D.DEATH_DATE > DIAG.ADMIT_DATE then 1
		when D.DEATH_DATE is NULL or D.DEATH_DATE > E.DISCHARGE_DATE then 1
		when E.PATID is not NULL then 1
		else 0
		end) as NONFATAL_OD_CY /*new*/
from indata.diagnosis as DIAG
	JOIN infolder.opioidoverdose OD
		ON DIAG.DX_TYPE = OD.Dx_TYPE AND DIAG.DX = OD.Code
	join indata.death as D
		on DIAG.PATID = D.PATID
	left join indata.encounter as E
		on DIAG.PATID = E.PATID
			and E.ADMIT_DATE <= DIAG.ADMIT_DATE
			and DIAG.ADMIT_DATE <= coalesce(E.DISCHARGE_DATE, E.ADMIT_DATE)
			and E.ADMIT_DATE <= D.DEATH_DATE
			and D.DEATH_DATE <= coalesce(E.DISCHARGE_DATE, E.ADMIT_DATE)
	right join dmlocal.patientyears as PY
		on PY.PATID = D.PATID
			and PY.EventYear = year(D.DEATH_DATE)
group by PY.PATID, PY.EventYear
order by PY.PATID, PY.EventYear
;
RUN;
QUIT;


* Create SAS data file dmlocal.suicide_events;
PROC SQL inobs=max;
CREATE TABLE dmlocal.suicide_events as
select PE.PATID
	, PE.EventYear
	, max(case when SUIC.ADMIT_DATE IS NOT NULL and SUIC.ADMIT_DATE <= PE.IndexDate then 1 else 0 
	  end) as SUICIDE_PRE
	, max(case when SUIC.ADMIT_DATE IS NOT NULL and SUIC.ADMIT_DATE <= PE.IndexDate then SUIC.ADMIT_DATE 
	  end) as SUICIDE_PRE_DATE
	, max(case when SUIC.ADMIT_DATE >= PE.IndexDate then 1 else 0 end) as SUICIDE_POST
	, min(case when SUIC.ADMIT_DATE >= PE.IndexDate then SUIC.ADMIT_DATE end) as SUICIDE_POST_DATE
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
	, max(case when SMOK.PATID IS NOT NULL then 1 else 0
		end) as SMOKING
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
ON PE.PATID = SMOK.PATID and PE.EventYear = SMOK.EventYear
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
*new variables added:  CHRONIC_OPIOID_CY, CHRONIC_OPIOID_everCY;
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
	, case when calculated CHRONIC_OPIOID_DATE is not null and year(calculated CHRONIC_OPIOID_DATE)<=PY.EventYear then 1 else 0
		end as CHRONIC_OPIOID_everCY /*new*/
from dmlocal.patientyears as PY
	left join dmlocal.prescribing_chronic_opioids as PO_Cur
		on PY.PATID = PO_Cur.PATID
			and PY.EventYear = PO_Cur.EventYear 
	left join dmlocal.prescribing_chronic_opioids as PO_Prior
		on PY.PATID = PO_Prior.PATID
			and PY.EventYear = PO_Prior.EventYear - 1
	left join dmlocal.dispensing_chronic_opioids as DO_Cur
		on PY.PATID = DO_Cur.PATID
			and PY.EventYear = DO_Cur.EventYear 
	left join dmlocal.dispensing_chronic_opioids as DO_Prior
		on PY.PATID = DO_Prior.PATID
			and PY.EventYear = DO_Prior.EventYear - 1
order by PY.PATID, PY.EventYear
;
RUN;
QUIT;


* Create SAS data file dmlocal.opioid_flat_file;
*new variables added: MAT_ANY_CY, MAT_ANY_everCY, HIV_HBV_HBC_CY, HIV_HBV_HBC_everCY, state, ANY_ENC_CY, GL_A_DENOM_FOR_ST, GL_B_DENOM_FOR_ST, CANCER_PX_CURRENT_YEAR,
	BUP_ANY_CY, NALTREX_ANY_CY;
data sites;
format DataMartID $20.;
%LET DataMartID=compress("&DMID.&SITEID.");
run;

PROC SQL inobs=max;
  CREATE TABLE dmlocal.opioid_flat_file_pre AS
  SELECT &DataMartID as DataMartID
	, DEMO.*
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
	, case when DEMO.AgeAsOfJuly1 >= 0 and DEMO.AgeAsOfJuly1 < 11 then '0-10'
		when DEMO.AgeAsOfJuly1 >= 11 and DEMO.AgeAsOfJuly1 < 18 then '11-17'
		when DEMO.AgeAsOfJuly1 >= 18 and DEMO.AgeAsOfJuly1 < 26 then '18-25'
		when DEMO.AgeAsOfJuly1 >= 26 and DEMO.AgeAsOfJuly1 < 36 then '26-35'
		when DEMO.AgeAsOfJuly1 >= 36 and DEMO.AgeAsOfJuly1 < 46 then '36-45'
		when DEMO.AgeAsOfJuly1 >= 46 and DEMO.AgeAsOfJuly1 < 56 then '46-55'
		when DEMO.AgeAsOfJuly1 >= 56 and DEMO.AgeAsOfJuly1 < 65 then '56-64'
		when DEMO.AgeAsOfJuly1 >= 65 and DEMO.AgeAsOfJuly1 < 75 then '65-74'
		when DEMO.AgeAsOfJuly1 >= 75 and DEMO.AgeAsOfJuly1 < 85 then '75-84'
		when DEMO.AgeAsOfJuly1 >= 85 then '85+'
		end as AGEGRP2
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
    , EVNTS.ENCOUNTERID
    , EVNTS.ADMIT_DATE
    , EVNTS.ENC_TYPE
	, case when PRIOR_YEAR_ENC.PATID is not NULL then 1 else 0 end as PRIOR_YEAR_ENCOUNTER
	, OpioidInYearPrior.OpioidInYearPrior
	, FIRST_OPIOID.FirstOpioidDate
	, FIRST_DIAG.FirstDiagEncDate as OBS_START
	, FIRST_OPIOID.FirstOpioidDate - FIRST_DIAG.FirstDiagEncDate as LOOKBACK_BEFORE_INDEX_OPIOID
	, case when ED_Visit_Years.PATID is not NULL then 1 else 0 end as ED_YR
	, case when IP_Visit_Years.PATID is not NULL then 1 else 0 end as IP_YR
	, case when ED_Visit_Years.PATID is not NULL then 1
		when IP_Visit_Years.PATID is not NULL then 1
		else 0
		end as ED_IP_YR
	, CA_DX.Cancer_AnyEncount_Dx_Year_Prior as Cancer_AnyEnc_Dx_Year_Prior /*rename due to length*/
	, CA_DX.Cancer_Inpt_Dx_Year_Prior
	, CA_PROC.Chemo_AnyEncount_Year_Prior 
	, CA_PROC.Rad_AnyEncount_Year_Prior
	, CASE
		WHEN (CA_PROC.Chemo_AnyEncount_Year_Prior = 1
				OR CA_PROC.Rad_AnyEncount_Year_Prior = 1) THEN 1 ELSE 0
		END AS CANCER_PROC_FLAG
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
	, MH_Dx_Pri_Any_Prior
	, MH_Dx_Pri_Year_Prior
	, MH_Dx_Exp_Any_Prior
	, MH_Dx_Exp_Year_Prior
	, SUD.Alcohol_Use_DO_Year_Prior
	, SUD.Alcohol_Use_DO_Any_Prior
	, SUD.Alcohol_Use_DO_Post_Date
	, SUD.Substance_Use_DO_Year_Prior
	, SUD.Substance_Use_DO_Any_Prior
	, SUD.Substance_Use_DO_Post_Date
	, SUD.Opioid_Use_DO_Year_Prior
	, SUD.Opioid_Use_DO_Any_Prior
	, SUD.Opioid_Use_DO_Post_Date
	, SUD.Cannabis_Use_DO_Year_Prior
	, SUD.Cannabis_Use_DO_Any_Prior
	, SUD.Cannabis_Use_DO_Post_Date
	, SUD.Cocaine_Use_DO_Year_Prior
	, SUD.Cocaine_Use_DO_Any_Prior
	, SUD.Cocaine_Use_DO_Post_Date
	, SUD.Hallucinogen_Use_DO_Year_Prior as Halluc_Use_DO_Year_Prior /*rename due to length*/
	, SUD.Hallucinogen_Use_DO_Any_Prior as Halluc_Use_DO_Any_Prior /*rename due to length*/
	, SUD.Hallucinogen_Use_DO_Post_Date as Halluc_Use_DO_Post_Date /*rename due to length*/
	, SUD.Inhalant_Use_DO_Year_Prior
	, SUD.Inhalant_Use_DO_Any_Prior
	, SUD.Inhalant_Use_DO_Post_Date
	, SUD.Other_Stim_Use_DO_Year_Prior
	, SUD.Other_Stim_Use_DO_Any_Prior
	, SUD.Other_Stim_Use_DO_Post_Date
	, SUD.SedHypAnx_Use_DO_Year_Prior
	, SUD.SedHypAnx_Use_DO_Any_Prior
	, SUD.SedHypAnx_Use_DO_Post_Date
	, HEPB.HepB_Dx_Year_Prior
	, HEPB.HepB_Dx_Any_Prior
	, HEPB.HepB_Dx_Post_Date
	, HEPC.HepC_Dx_Year_Prior
	, HEPC.HepC_Dx_Any_Prior
	, HEPC.HepC_Dx_Post_Date
	, HIV.HIV_Dx_Year_Prior
	, HIV.HIV_Dx_Any_Prior
	, HIV.HIV_Dx_Post_Date
	, case when HEPB.HepB_Dx_Year_Prior = 1 then 1
		when HEPC.HepC_Dx_Year_Prior = 1 then 1
		when HIV.HIV_Dx_Year_Prior = 1 then 1
		else 0
		end as ANY_STD_Year_Prior
	, BDZ.BDZ_3MO
    , BDZ.BDZ_Presc_3mo
   	, BDZ.BDZ_Disp_3mo
	, BUP.BUP_PRESC_PRE
	, BUP.BUP_PRESC_PRE_DATE
	, BUP.BUP_PRESC_POST
	, BUP.BUP_PRESC_POST_DATE
	, BUP.BUP_DISP_PRE
	, BUP.BUP_DISP_PRE_DATE
	, BUP.BUP_DISP_POST
	, BUP.BUP_DISP_POST_DATE
	, NALTREX.NALTREX_PRESC_PRE
	, NALTREX.NALTREX_PRESC_PRE_DATE
	, NALTREX.NALTREX_PRESC_POST
	, NALTREX.NALTREX_PRESC_POST_DATE
	, NALTREX.NALTREX_DISP_PRE
	, NALTREX.NALTREX_DISP_PRE_DATE
	, NALTREX.NALTREX_DISP_POST
	, NALTREX.NALTREX_DISP_POST_DATE
	, METHADONE.METHADONE_PRESC_PRE
	, METHADONE.METHADONE_PRESC_PRE_DATE
	, METHADONE.METHADONE_PRESC_POST
	, METHADONE.METHADONE_PRESC_POST_DATE
	, METHADONE.METHADONE_DISP_PRE
	, METHADONE.METHADONE_DISP_PRE_DATE
	, METHADONE.METHADONE_DISP_POST
	, METHADONE.METHADONE_DISP_POST_DATE
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
	, OD.OD_PRE_DATE
	, OD.OD_POST
	, OD.OD_POST_DATE
	, OD.ED_OD_PRE
	, OD.ED_OD_PRE_DATE
	, OD.ED_OD_POST
	, OD.ED_OD_POST_DATE
	, FATAL_OD.FATAL_OVERDOSE
	, SUIC.SUICIDE_PRE
	, SUIC.SUICIDE_PRE_DATE
	, SUIC.SUICIDE_POST
	, SUIC.SUICIDE_POST_DATE
	, SMOK.SMOKING
	, CHRON_OP.CHRONIC_OPIOID_DATE
	, CHRON_OP.CHRONIC_OPIOID
	, CHRON_OP.CHRONIC_OPIOID_CURRENT_PRIOR as CHRONIC_OPIOID_CURR_PRIOR /*rename due to length*/
	, CA_DX_CY.Cancer_AnyEncount_CY /*new*/
	, CA_DX_CY.Cancer_Inpt_Dx_CY /*new*/
	, CA_PROC_CY.Chemo_AnyEncount_CY /*new*/
	, CA_PROC_CY.Rad_AnyEncount_CY /*new*/
	, SUD.Cannabis_UD_Any_CY /*new*/
	, SUD.Cocaine_UD_Any_CY /*new*/
	, SUD.Other_Stim_UD_Any_CY /*new*/
	, SUD.Hallucinogen_UD_Any_CY /*new*/
	, SUD.Inhalant_UD_Any_CY /*new*/
	, SUD.SedHypAnx_UD_Any_CY /*new*/
	, SUD.Opioid_UD_Any_CY /*new*/
	, SUD.Alcohol_UD_Any_CY /*new*/
	, SUD.Substance_UD_Any_CY /*new*/
	, SUD.Opioid_UD_Any_everCY /*new*/
	, SUD.Alcohol_UD_Any_everCY /*new*/
	, SUD.Substance_UD_Any_everCY /*new*/
	, SUD.OUD_SUD_everCY /*new*/
	, HEPB.HepB_Dx_Any_CY /*new*/
	, HEPB.HepB_Dx_Any_everCY /*new*/
	, HEPC.HepC_Dx_Any_CY /*new*/
	, HEPC.HepC_Dx_Any_everCY /*new*/
	, MH_CY.MH_Dx_Pri_CY /*new*/
	, MH_CY.MH_Dx_Exp_CY /*new*/
	, HIV.HIV_Dx_Any_CY /*new*/
	, HIV.HIV_Dx_Any_everCY /*new*/
	, BUP_CY.BUP_PRESC_CY /*new*/
	, BUP_CY.BUP_DISP_CY /*new*/
	, BUP_CY.BUP_PRESC_everCY /*new*/
	, BUP_CY.BUP_DISP_everCY /*new*/
	, NALTREX_CY.NALTREX_PRESC_CY /*new*/
	, NALTREX_CY.NALTREX_DISP_CY /*new*/
	, NALTREX_CY.NALTREX_PRESC_everCY /*new*/
	, NALTREX_CY.NALTREX_DISP_everCY /*new*/
	, METH_CY.METHADONE_ANY_CY /*new*/
	, OD.OD_CY /*new*/
	, OD.ED_OD_CY /*new*/
	, max(BUP_CY.BUP_DISP_CY, BUP_CY.BUP_PRESC_CY, NALTREX_CY.NALTREX_DISP_CY, NALTREX_CY.NALTREX_PRESC_CY) as MAT_ANY_CY /*new*/
	, max(BUP_CY.BUP_DISP_everCY, BUP_CY.BUP_PRESC_everCY, NALTREX_CY.NALTREX_DISP_everCY, NALTREX_CY.NALTREX_PRESC_everCY) as MAT_ANY_everCY /*new*/
	, max(HIV.HIV_Dx_Any_CY, HEPB.HepB_Dx_Any_CY, HEPC.HepC_Dx_Any_CY) as HIV_HBV_HBC_CY /*new*/
	, max(HIV.HIV_Dx_Any_everCY, HEPB.HepB_Dx_Any_everCY, HEPC.HepC_Dx_Any_everCY) as HIV_HBV_HBC_everCY /*new*/
	, max(BUP_CY.BUP_DISP_CY, BUP_CY.BUP_PRESC_CY) as BUP_ANY_CY /*new*/
	, max(NALTREX_CY.NALTREX_DISP_CY, NALTREX_CY.NALTREX_PRESC_CY) as NALTREX_ANY_CY /*new*/
	, zip.state /*new*/
	, FATAL_OD.NONFATAL_OD_CY /*new*/
	, CHRON_OP.CHRONIC_OPIOID_CY  /*new*/
	, CHRON_OP.CHRONIC_OPIOID_everCY /*new*/
	, case when DEMO.PATID=ENC_EVENT.PATID and DEMO.EventYear=ENC_EVENT.EventYear and ENC_EVENT.EventYear is not null then 1 else 0 end as ANY_ENC_CY /*new*/
	, case when CA_DX_CY.Cancer_AnyEncount_CY=1 then 1 else 0 end as GL_A_DENOM_FOR_ST /*new*/
	, case when CA_PROC_CY.Chemo_AnyEncount_CY=1 or CA_PROC_CY.Rad_AnyEncount_CY=1 then 1 else 0 end as CANCER_PX_CURRENT_YEAR /*new*/
	, case when CA_DX_CY.Cancer_Inpt_Dx_CY=1 and calculated CANCER_PX_CURRENT_YEAR=1 then 1 else 0 end as GL_B_DENOM_FOR_ST /*new*/
  FROM dmlocal.patientevents as EVNTS
  LEFT JOIN dmlocal.patientdemo as DEMO
  ON DEMO.PATID = EVNTS.PATID AND DEMO.EventYear = EVNTS.EventYear
	left join dmlocal.encounter_events as PRIOR_YEAR_ENC
		on DEMO.PATID = PRIOR_YEAR_ENC.PATID and DEMO.EventYear - 1 = PRIOR_YEAR_ENC.EventYear
	left join dmlocal.first_diag as FIRST_DIAG
		on DEMO.PATID = FIRST_DIAG.PATID
	left join dmlocal.first_opioid as FIRST_OPIOID
		on DEMO.PATID = FIRST_OPIOID.PATID
	left join dmlocal.opioid_year_prior as OpioidInYearPrior
		on DEMO.PATID = OpioidInYearPrior.PATID and DEMO.EventYear = OpioidInYearPrior.EventYear
	left join dmlocal.ED_Visit_Years
		on DEMO.PATID = ED_Visit_Years.PATID and DEMO.EventYear = ED_Visit_Years.EventYear
	left join dmlocal.IP_Visit_Years
		on DEMO.PATID = IP_Visit_Years.PATID and DEMO.EventYear = IP_Visit_Years.EventYear
  LEFT JOIN dmlocal.cancer_dx_events as CA_DX
  ON DEMO.PATID = CA_DX.PATID AND DEMO.EventYear = CA_DX.EventYear
  LEFT JOIN dmlocal.cancer_proc_events as CA_PROC
  ON DEMO.PATID = CA_PROC.PATID AND DEMO.EventYear = CA_PROC.EventYear
  LEFT JOIN dmlocal.uds_events AS UDS
  ON DEMO.PATID = UDS.PATID AND DEMO.EventYear = UDS.EventYear
  LEFT JOIN dmlocal.mental_health_events as MH
  ON DEMO.PATID = MH.PATID AND DEMO.EventYear = MH.EventYear
  left join dmlocal.substance_use_do_events as SUD
  	on DEMO.PATID = SUD.PATID AND DEMO.EventYear = SUD.EventYear
	left join dmlocal.hepb_events as HEPB
		on DEMO.PATID = HEPB.PATID
			and DEMO.EventYear = HEPB.EventYear
	left join dmlocal.hepc_events as HEPC
		on DEMO.PATID = HEPC.PATID
			and DEMO.EventYear = HEPC.EventYear
	left join dmlocal.hiv_events as HIV
		on DEMO.PATID = HIV.PATID
			and DEMO.EventYear = HIV.EventYear
  LEFT JOIN dmlocal.BDZ_Events as BDZ
   ON DEMO.PATID = BDZ.PATID AND DEMO.EventYear = BDZ.EventYear
	left join dmlocal.bup_events as BUP
		on DEMO.PATID = BUP.PATID and DEMO.EventYear = BUP.EventYear
	left join dmlocal.naltrex_events as NALTREX
		on DEMO.PATID = NALTREX.PATID and DEMO.EventYear = NALTREX.EventYear
	left join dmlocal.methadone_events as METHADONE
		on DEMO.PATID = METHADONE.PATID and DEMO.EventYear = METHADONE.EventYear
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
	left join dmlocal.cancer_proc_events_cy as CA_PROC_CY
		on DEMO.PATID = CA_PROC_CY.PATID AND DEMO.EventYear = CA_PROC_CY.EventYear
	left join dmlocal.cancer_dx_events_cy as CA_DX_CY
		on DEMO.PATID = CA_DX_CY.PATID AND DEMO.EventYear = CA_DX_CY.EventYear
	left join dmlocal.mental_health_events_cy as MH_CY
		ON DEMO.PATID = MH_CY.PATID AND DEMO.EventYear = MH_CY.EventYear
	left join dmlocal.bup_events_cy as BUP_CY
		on DEMO.PATID = BUP_CY.PATID and DEMO.EventYear = BUP_CY.EventYear
	left join dmlocal.naltrex_events_cy as NALTREX_CY
		on DEMO.PATID = NALTREX_CY.PATID and DEMO.EventYear = NALTREX_CY.EventYear
	left join dmlocal.methadone_events_cy as METH_CY
		on DEMO.PATID = METH_CY.PATID and DEMO.EventYear = METH_CY.EventYear
	left join dmlocal.zipcode as ZIP
		on DEMO.FACILITY_LOCATION = ZIP.zip 
	left join dmlocal.encounter_events as ENC_EVENT
		on DEMO.PATID = ENC_EVENT.PATID and DEMO.EventYear = ENC_EVENT.EventYear
WHERE DEMO.AgeAsOfJuly1 >= 0  
  ;
RUN;
QUIT;
*;


*use data within PCORNET enrollment dates;
*if the number of observations do not diminish, should code for the XX_everCY here;
proc sql;
	create table dmlocal.opioid_flat_file as
	select a.*, b.ENR_START_DATE, b.ENR_END_DATE
	from dmlocal.opioid_flat_file_pre a
	left join
	(select * from indata.enrollment) b
	on a.patid=b.patid
	where a.eventyear >= year(b.NR_START_DATE) and a.eventyear <= year(b.ENR_END_DATE);
quit;


*need to check XX_CY and XX_everCY codes are being outputted correctly;
*potentially will need to create new tables to code for XX_everCY;
*Need to check if observatiosn were removed after enrollemnt query;
*Double check encounter variable ANY_ENC_CY makes sense;
*need to check if there are missing observations and need to change them to 0;




	
	
	
	
	
