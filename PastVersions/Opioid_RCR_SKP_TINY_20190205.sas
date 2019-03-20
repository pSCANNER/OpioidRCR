* Last updated 1/30/19;

** NEED TO DELETE COMMENTS AND PROC CONTENTS AND PRINT **;

/* SKP changes 1/7/2019:
	1. For ENCOUNTER_Events table, source changed from PCOR_ENCOUNTER to PCOR_DIAGNOSIS
	2. During creation of ENCOUNTER_Events table, all instances of ADMIT_TIME deleted, as this field
		is not present in the PCOR_DIAGNOSIS table
	3. Age in last line of Opioid_Flat_File creation changed to WHERE DEMO.AgeAsOfJuly1 >= 0
	4. Added Prevalence Numerator & Denominator, Guideline A Numerator and Denominator, and Guideline B Numerator and Denominator after
		Opioid_Flat_File segment of code.
*/

%let StudyStartDate = 18263; *2010-01-01 Inclusive;
%let StudyEndDate = 21185; *2018-01-01 Exclusive;
LIBNAME rcr "/data/dart/2015/ord_matheny_201501042d/Programs/RCR_Opioid_AdHoc/TransferDataSKP_TINY/"; run;
LIBNAME fval "/data/dart/2015/ord_matheny_201501042d/Programs/RCR_Opioid_AdHoc/FinalValueSets/"; run;
LIBNAME nfval "/data/dart/2015/ord_matheny_201501042d/Programs/RCR_Opioid_AdHoc/NonFinalValueSets/"; run;
LIBNAME tiny "/data/dart/2015/ord_matheny_201501042d/Data/Opioid_RCR_Profiling_2019_01/"; run;
quit;run;

/*
use ORD_Matheny_201501042D
GO

if object_id('TempDB..#PatFilter', 'U') is not NULL
	drop table #PatFilter;
GO

--select distinct top 50000 PATID
--into #PatFilter
--from [ORD_Matheny_201501042D].[Src].[PCOR_PATID_Crosswalk]
--where Sta3n = 626;
--GO

SELECT DISTINCT PATID
INTO #PatFilter
FROM Src.PCOR_DEMOGRAPHIC

declare @StudyStartDate		date	= '2010-01-01'	--inclusive
		, @StudyEndDate		date	= '2018-01-01'	--exclusive
*/

* Create SAS data file rcr.patfilter;
PROC DATASETS library=rcr;
  delete patfilter;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.patfilter AS
  SELECT DISTINCT PATID
    FROM tiny.demographic;
RUN;
QUIT;

proc contents data=rcr.patfilter; run;
proc print data=rcr.patfilter(firstobs=1 obs=100); run;

/*
data sqltemp.'#patfilter'n;
  set rcr.patfilter;
run;
*/

/*
if object_id('Parr.PRESCRIBING_Events', 'U') is not NULL
	drop table Parr.PRESCRIBING_Events;

select PATID, EventYear, [PRESCRIBINGID], [RX_ORDER_DATE], [RX_ORDER_TIME], [RXNORM_CUI]
INTO Parr.PRESCRIBING_Events
from (SELECT ROW_NUMBER() over(partition by P.PATID, YEAR(RX_ORDER_DATE) order by [RX_ORDER_DATE], [RX_ORDER_TIME]) as RowNum
		, PF.PATID, YEAR(RX_ORDER_DATE) AS EventYear, [PRESCRIBINGID], [RX_ORDER_DATE], [RX_ORDER_TIME], [RXNORM_CUI]
	FROM #PatFilter as PF
	join [Src].[PCOR_PRESCRIBING] as P
		on PF.PATID = P.PATID
	join [Parr].[Opiate_CUIs_Nonfinal] as M
		on P.[RXNORM_CUI] = M.[RXNORM_CUI_Code]
	where P.RX_ORDER_DATE >= @StudyStartDate
		and P.RX_ORDER_DATE < @StudyEndDate
	) as PE
WHERE PE.RowNum = 1

CREATE NONCLUSTERED INDEX [Parr_Presc_Index] ON [ORD_Matheny_201501042D].[Parr].[PRESCRIBING_Events]
(
	[PATID] ASC,
	[EventYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DefFG]
GO
ALTER TABLE [ORD_Matheny_201501042D].[Parr].[PRESCRIBING_Events] REBUILD PARTITION = ALL
WITH (DATA_COMPRESSION = PAGE);
GO

declare @StudyStartDate		date	= '2010-01-01'	--inclusive
		, @StudyEndDate		date	= '2018-01-01'	--exclusive
*/

* Create SAS data file rcr.prescribing_events;
PROC DATASETS library=rcr;
  delete prescribing_events;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.prescribing_select AS
  SELECT PATID, YEAR(RX_ORDER_DATE) as EventYear, PRESCRIBINGID, RX_ORDER_DATE, RX_ORDER_TIME, RXNORM_CUI
  FROM tiny.prescribing
  ORDER BY PATID, EventYear, RX_ORDER_DATE, RX_ORDER_TIME
  ;
RUN;
QUIT;

data rcr.prescribing_select;
  set rcr.prescribing_select;
  by PATID EventYear;
  Seq+1;
  if first.EventYear then Seq=1;
run;

data rcr.prescribing_select;
  set rcr.prescribing_select;
  where Seq=1;
run;

proc contents data=rcr.prescribing_select; run;
proc print data=rcr.prescribing_select(firstobs=1 obs=40); run;

PROC SQL inobs=max;
  CREATE TABLE rcr.prescribing_events AS
  SELECT PATID, EventYear, PRESCRIBINGID, RX_ORDER_DATE, RX_ORDER_TIME, RXNORM_CUI
  FROM (SELECT Seq, PF.PATID, EventYear, PRESCRIBINGID, RX_ORDER_DATE, RX_ORDER_TIME, RXNORM_CUI
	FROM rcr.patfilter as PF
	join rcr.prescribing_select as P
		on PF.PATID = P.PATID
	join nfval.opioidcui as M /* ERROR: no RXNORM_CUI_Code so substituted "Code", was Parr.Opiate_CUIs_Nonfinal */
		on P.RXNORM_CUI = M.Code
	WHERE P.RX_ORDER_DATE >= &StudyStartDate
		and P.RX_ORDER_DATE < &StudyEndDate
	) as PE;
  WHERE Seq=1;
RUN;
QUIT;

proc contents data=rcr.prescribing_events; run;
proc print data=rcr.prescribing_events(firstobs=1 obs=100); run;

/* Jason's suggestion 1/9/19
PROC SQL inobs=max;
  CREATE TABLE rcr.rank_prescribing AS
  select c1.PATID,
         c1.EventYear,
		 c1.PRESCRIBINGID,
		 c1.RX_ORDER_DATE,
		 c1.RX_ORDER_TIME,
		 c1.RXNORM_CUI,
		 (
		    select count(*)
			from rcr.test_prescribing c2
			where c2.PATID = c1.PATID
			and c2.EventYear >= c1.EventYear
		 ) as rankings
  from rcr.test_prescribing c1
  order by c1.PATID, c1.EventYear, c1.RX_ORDER_DATE, c1.RX_ORDER_TIME 
  ;
run;
quit;
*/

/*
if object_id('Parr.DISPENSING_Events', 'U') is not NULL
	drop table Parr.DISPENSING_Events;

select DE.PATID, EventYear, [DISPENSINGID], [DISPENSE_DATE], DE.[NDC]
into Parr.DISPENSING_Events
from (select ROW_NUMBER() over(partition by D.PATID, YEAR(D.DISPENSE_DATE) order by [DISPENSE_DATE]) as RowNum
		, D.PATID, YEAR(D.DISPENSE_DATE) AS EventYear, [DISPENSINGID], [DISPENSE_DATE], D.[NDC]
	FROM #PatFilter as PF
	join [Src].[PCOR_DISPENSING] as D
		on PF.PATID = D.PATID
	join [Parr].[Opiate_NDCs_Nonfinal] as M
		on D.[NDC] = M.[NDC]
	where D.DISPENSE_DATE >= @StudyStartDate
		and D.DISPENSE_DATE < @StudyEndDate
	) AS DE
	WHERE DE.RowNum = 1

CREATE NONCLUSTERED INDEX [Parr_Disp_Index] ON [ORD_Matheny_201501042D].[Parr].[DISPENSING_Events]
(
	[PATID] ASC,
	[EventYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DefFG]
GO
ALTER TABLE [ORD_Matheny_201501042D].[Parr].[DISPENSING_Events] REBUILD PARTITION = ALL
WITH (DATA_COMPRESSION = PAGE);
GO

declare @StudyStartDate		date	= '2010-01-01'	--inclusive
		, @StudyEndDate		date	= '2018-01-01'	--exclusive
*/

* Create SAS data file rcr.dispensing_events;
PROC DATASETS library=rcr;
  delete dispensing_events;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.dispensing_select AS
  SELECT PATID, YEAR(DISPENSE_DATE) as EventYear, DISPENSINGID, DISPENSE_DATE, NDC
  FROM tiny.dispensing
  ORDER BY PATID, EventYear, DISPENSE_DATE
  ;
RUN;
QUIT;

data rcr.dispensing_select;
  set rcr.dispensing_select;
  by PATID EventYear;
  Seq+1;
  if first.EventYear then Seq=1;
run;

data rcr.dispensing_select;
  set rcr.dispensing_select;
  where Seq=1;
run;

proc contents data=rcr.dispensing_select; run;
proc print data=rcr.dispensing_select(firstobs=1 obs=40); run;

PROC SQL inobs=max;
  CREATE TABLE rcr.dispensing_events AS
  SELECT DE.PATID, EventYear, DISPENSINGID, DISPENSE_DATE, DE.NDC
  FROM (select Seq, D.PATID, EventYear, DISPENSINGID, DISPENSE_DATE, D.NDC
	FROM rcr.patfilter as PF
	join rcr.dispensing_select as D
		on PF.PATID = D.PATID
	join nfval.opioidndc as M /* ERROR: no NDC so sub "Code", was Parr.Opiate_NDCs_Nonfinal */
		on D.NDC = M.Code
	where D.DISPENSE_DATE >= &StudyStartDate
		and D.DISPENSE_DATE < &StudyEndDate
	) AS DE
	WHERE Seq = 1;
RUN;
QUIT;

proc contents data=rcr.dispensing_events; run;
proc print data=rcr.dispensing_events(firstobs=1 obs=100); run;

/*
-- All instances of ADMIT_TIME removed by SKP on 1/7/2019
-- Source table changed from PCOR_ENCOUNTER to PCOR_DIAGNOSIS by SKP on 1/7/2019
if object_id('Parr.ENCOUNTER_Events', 'U') is not NULL
	drop table Parr.ENCOUNTER_Events;

select EE.PATID, EventYear, [ENCOUNTERID], [ADMIT_DATE], /*[ADMIT_TIME],*/ /*[ENC_TYPE]
into Parr.ENCOUNTER_Events
from 
	(
	SELECT ROW_NUMBER() over(partition by PF.PATID, YEAR(ADMIT_DATE) order by [ADMIT_DATE] /*, [ADMIT_TIME]*/ /*) as RowNum
		, PF.PATID, YEAR(ADMIT_DATE) AS EventYear, [ENCOUNTERID], [ADMIT_DATE], /*[ADMIT_TIME],*/ /*[ENC_TYPE]
	FROM #PatFilter as PF
	join [Src].[PCOR_DIAGNOSIS] as E  -- Changed by SKP on 1/7/2019
		on PF.PATID = E.PATID
	where E.[ENC_TYPE] in ('AV', 'IP', 'ED', 'EI', 'OS', 'OA')
		and E.ADMIT_DATE >= @StudyStartDate		
		and E.ADMIT_DATE < @StudyEndDate	
	) AS EE
WHERE EE.RowNum = 1

CREATE NONCLUSTERED INDEX [Parr_Enc_Index] ON [ORD_Matheny_201501042D].[Parr].[ENCOUNTER_Events]
(
	[PATID] ASC,
	[EventYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DefFG]
GO
ALTER TABLE [ORD_Matheny_201501042D].[Parr].[ENCOUNTER_Events] REBUILD PARTITION = ALL
WITH (DATA_COMPRESSION = PAGE);
GO
*/

* Create SAS data file rcr.encounter_events;
PROC DATASETS library=rcr;
  delete encounter_events;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.diagnosis_select AS
  SELECT PATID, YEAR(ADMIT_DATE) as EventYear, ENCOUNTERID, ADMIT_DATE, ENC_TYPE
  FROM tiny.diagnosis
  ORDER BY PATID, EventYear, ADMIT_DATE
  ;
RUN;
QUIT;

data rcr.diagnosis_select;
  set rcr.diagnosis_select;
  by PATID EventYear;
  Seq+1;
  if first.EventYear then Seq=1;
run;

data rcr.diagnosis_select;
  set rcr.diagnosis_select;
  where Seq=1;
run;

proc contents data=rcr.diagnosis_select; run;
proc print data=rcr.diagnosis_select(firstobs=1 obs=40); run;

PROC SQL inobs=max;
  CREATE TABLE rcr.encounter_events AS
  SELECT EE.PATID, EventYear, ENCOUNTERID, ADMIT_DATE, ENC_TYPE
  from (SELECT Seq, PF.PATID, EventYear, ENCOUNTERID, ADMIT_DATE, ENC_TYPE
	FROM rcr.patfilter as PF
	join rcr.diagnosis_select as E  
		on PF.PATID = E.PATID
	where E.ENC_TYPE in ('AV', 'IP', 'ED', 'EI', 'OS', 'OA')
		and E.ADMIT_DATE >= &StudyStartDate		
		and E.ADMIT_DATE < &StudyEndDate	
	) AS EE
  WHERE Seq = 1;
RUN;
QUIT;

proc contents data=rcr.encounter_events; run;
proc print data=rcr.encounter_events(firstobs=1 obs=100); run;

/* The rows of our FlatFile */ /*
if object_id('TempDB..#PatientYears', 'U') is not NULL
	drop table #PatientYears;
GO

select PATID, EventYear
into #PatientYears
from Parr.PRESCRIBING_Events
union
select PATID, EventYear
from Parr.DISPENSING_Events
union
select PATID, EventYear
from Parr.ENCOUNTER_Events
*/

* Create SAS data file rcr.patientyears;
PROC DATASETS library=rcr;
  delete patientyears;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.patientyears AS
  select PATID, EventYear
  from rcr.prescribing_events
  union
  select PATID, EventYear
  from rcr.dispensing_events
  union
  select PATID, EventYear
  from rcr.encounter_events;
RUN;
QUIT;

proc contents data=rcr.patientyears; run;
proc print data=rcr.patientyears(firstobs=1 obs=100); run;

/*
if object_id('Parr.PatientEvents', 'U') is not NULL
	drop table Parr.PatientEvents;

select PY.*
	, coalesce
	(
		case when P.[RX_ORDER_DATE] < D.[DISPENSE_DATE] 
			then P.[RX_ORDER_DATE] 
			else coalesce(D.[DISPENSE_DATE], P.[RX_ORDER_DATE]) 
		end
		, E.[ADMIT_DATE]
	) as IndexDate	--There might be a clearer/cleaner way to write this?
	, P.[PRESCRIBINGID], P.[RX_ORDER_DATE], P.[RX_ORDER_TIME], P.[RXNORM_CUI]
	, D.[DISPENSINGID], D.[DISPENSE_DATE], D.[NDC]
	, E.[ENCOUNTERID], E.[ADMIT_DATE], /*E.[ADMIT_TIME],*/ /*E.[ENC_TYPE]
into Parr.PatientEvents
from #PatientYears as PY
	left join Parr.PRESCRIBING_Events as P
		on PY.PATID = P.PATID
			and PY.EventYear = P.EventYear
	left join Parr.DISPENSING_Events as D
		on PY.PATID = D.PATID
			and PY.EventYear = D.EventYear
	left join Parr.ENCOUNTER_Events as E
		on PY.PATID = E.PATID
			and PY.EventYear = E.EventYear

CREATE NONCLUSTERED INDEX [Parr_PatEvent_Index] ON [ORD_Matheny_201501042D].[Parr].[PatientEvents]
(
	[PATID] ASC,
	[EventYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DefFG]
GO
ALTER TABLE [ORD_Matheny_201501042D].[Parr].[PatientEvents] REBUILD PARTITION = ALL
WITH (DATA_COMPRESSION = PAGE);
GO
*/

* Create SAS data file rcr.patientevents;
PROC DATASETS library=rcr;
  delete patientevents;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.patientevents AS
  SELECT PY.*
         , case when P.RX_ORDER_DATE < D.DISPENSE_DATE then P.RX_ORDER_DATE
				when D.DISPENSE_DATE is not null then D.DISPENSE_DATE
				when P.RX_ORDER_DATE is not null then P.RX_ORDER_DATE
				else E.ADMIT_DATE
				end as IndexDate
         , P.PRESCRIBINGID, P.RX_ORDER_DATE, P.RX_ORDER_TIME, P.RXNORM_CUI
	     , D.DISPENSINGID, D.DISPENSE_DATE, D.NDC
	     , E.ENCOUNTERID, E.ADMIT_DATE, E.ENC_TYPE
  FROM rcr.patientyears as PY
	left join rcr.prescribing_events as P
		on PY.PATID = P.PATID
			and PY.EventYear = P.EventYear
	left join rcr.dispensing_events as D
		on PY.PATID = D.PATID
			and PY.EventYear = D.EventYear
	left join rcr.encounter_events as E
		on PY.PATID = E.PATID
			and PY.EventYear = E.EventYear;
RUN;
QUIT;

proc contents data=rcr.patientevents; run;
proc print data=rcr.patientevents(firstobs=1 obs=100); run;


/* Demographic */ /*
if object_id('Parr.PatientDemo', 'U') is not NULL
	drop table Parr.PatientDemo;

select PY.PATID, PY.EventYear
	, D.[RACE], D.[SEX], D.[HISPANIC], D.[BIRTH_DATE]
	, datediff(year, D.[BIRTH_DATE], cast(PY.EventYEar as varchar(4)) + '-01-01')
		- case when month(D.[BIRTH_DATE]) < 7 then 0 else 1
		end as [AgeAsOfJuly1]
	, FL.FACILITY_LOCATION
into Parr.PatientDemo
from Parr.PatientEvents as PY
	INNER JOIN [Src].[PCOR_DEMOGRAPHIC] as D
		on PY.PATID = D.PATID
	LEFT JOIN 
	(
		SELECT PATID
			, EventYear
			, FACILITY_LOCATION
		FROM
			(SELECT E.PATID
				, YEAR(ADMIT_DATE) as [EventYear]
				, E.FACILITY_LOCATION
				, COUNT(*) as [Visits]
				, ROW_NUMBER() over(partition by E.PATID, YEAR(ADMIT_DATE) order by COUNT(*) DESC) as RowNum
			FROM #PatientYears as PY
				INNER JOIN Src.PCOR_ENCOUNTER as E
				ON PY.PATID = E.PATID AND PY.EventYear = YEAR(E.ADMIT_DATE)
			WHERE FACILITY_LOCATION IS NOT NULL 
			GROUP BY E.PATID, YEAR(ADMIT_DATE), E.FACILITY_LOCATION) as a
		WHERE RowNum = 1) as FL
	ON FL.PATID = PY.PATID AND FL.EventYear = PY.EventYear

CREATE NONCLUSTERED INDEX [Parr_PatDemo_Index] ON [ORD_Matheny_201501042D].[Parr].[PatientDemo]
(
	[PATID] ASC,
	[EventYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DefFG]
GO
ALTER TABLE [ORD_Matheny_201501042D].[Parr].[PatientDemo] REBUILD PARTITION = ALL
WITH (DATA_COMPRESSION = PAGE);
GO
*/

* Create SAS data file rcr.patientdemo;
PROC DATASETS library=rcr;
  delete patientdemo;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.encounter_select AS
  SELECT PATID, YEAR(ADMIT_DATE) as EventYear, count(*) as Count, ADMIT_DATE, FACILITY_LOCATION
  FROM tiny.encounter
  WHERE FACILITY_LOCATION IS NOT NULL
  GROUP BY PATID, EventYear, FACILITY_LOCATION
  ORDER BY PATID, EventYear, Count DESC, ADMIT_DATE DESC
  ;
RUN;
QUIT;

data rcr.encounter_select;
  set rcr.encounter_select;
  by PATID EventYear;
  RowNum+1;
  if first.EventYear then RowNum=1;
run;

data rcr.encounter_select;
  set rcr.encounter_select;
  where RowNum=1;
run;

proc contents data=rcr.encounter_select; run;
proc print data=rcr.encounter_select(firstobs=1 obs=100); run;

PROC SQL inobs=max;
  CREATE TABLE rcr.demographic_format AS
  SELECT PATID, RACE, SEX, HISPANIC, BIRTH_DATE, BIRTH_DATE as DOB format=YYMMDD10.
  FROM tiny.demographic
  ;
RUN;
QUIT;

proc contents data=rcr.demographic_format; run;
proc print data=rcr.demographic_format (firstobs=1 obs=40); run;

data rcr.patientevents_format;
  set rcr.patientevents;
  DAY1 = INPUT(PUT('01', 2.), DAY2.);
  MONTH1 = INPUT(PUT('01', 2.), MONTH.);
  Jan1EventYear = MDY(DAY1, MONTH1, EventYear);
  format Jan1EventYear YYMMDD10.;
run;

proc contents data=rcr.patientevents_format; run;
proc print data=rcr.patientevents_format (firstobs=1 obs=40); run;

PROC SQL inobs=max;
  CREATE TABLE rcr.patientdemo AS
  SELECT PY.PATID, PY.EventYear
	, D.RACE, D.SEX, D.HISPANIC, D.BIRTH_DATE
	, INTCK('year', D.DOB, PY.Jan1EventYear)     
		- case when month(D.DOB) < 7 then 0 else 1
		end as AgeAsOfJuly1
	, FL.FACILITY_LOCATION
  FROM rcr.patientevents_format as PY
	INNER JOIN rcr.demographic_format as D
		on PY.PATID = D.PATID
	LEFT JOIN 
  (
	SELECT PATID
		   , EventYear
		   , FACILITY_LOCATION
		   , RowNum
    FROM
	  (
        SELECT PATID
			   , EventYear
			   , FACILITY_LOCATION
			   , RowNum
	    FROM
		  (
            SELECT E.PATID
				   , YEAR(ADMIT_DATE) as EventYear
				   , E.FACILITY_LOCATION
				   , count(*) as Count
				   , RowNum
			FROM rcr.patientyears as PY
			  INNER JOIN rcr.encounter_select as E
			  ON PY.PATID = E.PATID AND PY.EventYear = YEAR(E.ADMIT_DATE)
			WHERE FACILITY_LOCATION IS NOT NULL 
			GROUP BY E.PATID, YEAR(ADMIT_DATE), E.FACILITY_LOCATION
          ) as FacLocCt
	  ) as MaxFacLocCt
        WHERE RowNum = 1
  ) as FL
	ON FL.PATID = PY.PATID AND FL.EventYear = PY.EventYear;
RUN;
QUIT;

proc contents data=rcr.patientdemo; run;
proc print data=rcr.patientdemo(firstobs=1 obs=100); run;

/*
--Distinct Code Types in Prelim Cancer Dx Value Set
--ICD9CM
--ICD10
--ICD10CM

--Distinct Code Types in PCOR_DIAGNOSIS
--09
--10

if object_id('Parr.Cancer_Dx_Events', 'U') is not NULL
	drop table Parr.Cancer_Dx_Events;

SELECT Ca.PATID
	, Ca.EventYear
	, MAX(Ca.Cancer_AnyEncount_Dx_Year_Prior) AS Cancer_AnyEncount_Dx_Year_Prior
	, MAX(Ca.Cancer_Inpt_Dx_Year_Prior) AS Cancer_Inpt_Dx_Year_Prior
INTO Parr.Cancer_Dx_Events
FROM
	(
		SELECT PE.PATID
		, PE.EventYear
		, CASE WHEN Ca.Code IS NOT NULL THEN 1 ELSE 0
			END AS Cancer_AnyEncount_Dx_Year_Prior
		, CASE WHEN Ca.Code IS NOT NULL AND Dx.ENC_TYPE = 'IP' THEN 1 ELSE 0
			END AS Cancer_Inpt_Dx_Year_Prior
		FROM Parr.PatientEvents as PE
		LEFT JOIN Src.PCOR_DIAGNOSIS as Dx
		ON PE.PATID = Dx.PATID
			AND Dx.ADMIT_DATE < PE.IndexDate
			AND Dx.ADMIT_DATE > DATEADD(DD, -365, PE.IndexDate)
			AND Dx.ENC_TYPE IN ('AV', 'IP', 'ED', 'EI', 'OS', 'OA')
		LEFT JOIN Parr.Cancer_Dx_Nonfinal as Ca -- Equivalent SAS Dataset is cancerdxnonfinal.sas7bdat
		ON Ca.Code = Dx.DX -- Column name for Ca.Code will need to be adjusted based on final value set
			-- Ca.[Code System] names will likely be different in final value set
			AND ((Ca.[Code System] = 'ICD9CM' AND Dx.DX_TYPE = '09')
			OR (Ca.[Code System] IN ('ICD10', 'ICD10CM') AND Dx.DX_TYPE = '10'))
	) as Ca
GROUP BY Ca.PATID, Ca.EventYear

CREATE NONCLUSTERED INDEX [Parr_Ca_Dx_Events_Index] ON [ORD_Matheny_201501042D].[Parr].[Cancer_Dx_Events]
(
	[PATID] ASC,
	[EventYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DefFG]
GO
ALTER TABLE [ORD_Matheny_201501042D].[Parr].[Cancer_Dx_Events] REBUILD PARTITION = ALL
WITH (DATA_COMPRESSION = PAGE);
GO
*/

* Create SAS data file rcr.cancer_dx_events;
PROC DATASETS library=rcr;
  delete cancer_dx_events;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.cancer_dx_events AS
  SELECT Ca.PATID
	, Ca.EventYear
	, MAX(Ca.Cancer_AnyEncount_Dx_Year_Prior) AS Cancer_AnyEncount_Dx_Year_Prior
	, MAX(Ca.Cancer_Inpt_Dx_Year_Prior) AS Cancer_Inpt_Dx_Year_Prior
  FROM
	(
		SELECT PE.PATID
		, PE.EventYear
		, CASE WHEN Ca.Code IS NOT NULL THEN 1 ELSE 0
			END AS Cancer_AnyEncount_Dx_Year_Prior
		, CASE WHEN Ca.Code IS NOT NULL AND Dx.ENC_TYPE = 'IP' THEN 1 ELSE 0
			END AS Cancer_Inpt_Dx_Year_Prior
		FROM rcr.patientevents as PE
		LEFT JOIN tiny.diagnosis as Dx
		ON PE.PATID = Dx.PATID
			AND Dx.ADMIT_DATE < PE.IndexDate
			AND Dx.ADMIT_DATE > INTNX('day', PE.IndexDate, -365, 'same')
			AND Dx.ENC_TYPE IN ('AV', 'IP', 'ED', 'EI', 'OS', 'OA')
		LEFT JOIN nfval.cancerdxnonfinal as Ca 
		ON Ca.Code = Dx.DX /* Column name for Ca.Code will need to be adjusted based on final value set */
		/* Ca.[Code System] names will likely be different in final value set */
			AND ((Ca.'Code System'n = 'ICD9CM' AND Dx.DX_TYPE = '09')
			OR (Ca.'Code System'n IN ('ICD10', 'ICD10CM') AND Dx.DX_TYPE = '10'))
	) as Ca
GROUP BY Ca.PATID, Ca.EventYear
  ;
RUN;
QUIT;

proc contents data=rcr.cancer_dx_events; run;
proc print data=rcr.cancer_dx_events(firstobs=1 obs=100); run;

/*
--Distinct Code Types in PCOR_PROCEDURES
--CH
--10
--09
--OT

if object_id('Parr.Cancer_Proc_Events', 'U') is not NULL
	drop table Parr.Cancer_Proc_Events;

SELECT Ca_Procs.PATID
	, Ca_Procs.EventYear
	, MAX(Ca_Procs.Chemo_AnyEncount_Year_Prior) AS Chemo_AnyEncount_Year_Prior
	, MAX(Ca_Procs.Rad_AnyEncount_Year_Prior) AS Rad_AnyEncount_Year_Prior
INTO Parr.Cancer_Proc_Events
FROM
	(
		SELECT PE.PATID
		, PE.EventYear
		, CASE WHEN Chemo.Code IS NOT NULL THEN 1 ELSE 0
			END AS Chemo_AnyEncount_Year_Prior
		, CASE WHEN Rad.Code IS NOT NULL THEN 1 ELSE 0
			END AS Rad_AnyEncount_Year_Prior
		FROM Parr.PatientEvents as PE
		LEFT JOIN Src.PCOR_PROCEDURES as Procs
		ON PE.PATID = Procs.PATID
			AND Procs.ADMIT_DATE < PE.IndexDate
			AND Procs.ADMIT_DATE > DATEADD(DD, -365, PE.IndexDate)
			AND Procs.ENC_TYPE IN ('AV', 'IP', 'ED', 'EI', 'OS', 'OA')
		LEFT JOIN Parr.Chemo_Nonfinal as Chemo --Equivalent SAS dataset is chemononfinal.sas7bdat
		ON Chemo.Code = Procs.PX -- Column name for Chemo.Code will need to be adjusted based on final value set
			-- Chemo.[Code System] names will likely be different in final value set
			AND ((Chemo.[Code System] = 'CPT/HCPCS' AND Procs.PX_TYPE = 'CH')
			OR (Chemo.[Code System] IN ('ICD10CM', 'ICD10PCS') AND Procs.PX_TYPE = '10')
			OR (Chemo.[Code System] = 'ICD9CM' AND Procs.PX_TYPE = '09'))
		LEFT JOIN Parr.Radiation_Nonfinal as Rad --Equivalent SAS dataset is radiationnonfinal.sas7bdat
		ON Rad.Code = Procs.PX -- Column name for Rad.Code will need to be adjusted based on final value set
			-- Rad.[Code System] names will likely be different in final value set
			AND ((Rad.[Code System] = 'CPT/HCPCS' AND Procs.PX_TYPE = 'CH')
			OR (Rad.[Code System] IN ('ICD10CM', 'ICD10PCS') AND Procs.PX_TYPE = '10')
			OR (Rad.[Code System] = 'ICD9CM' AND Procs.PX_TYPE = '09'))
	) as Ca_Procs
GROUP BY Ca_Procs.PATID, Ca_Procs.EventYear

CREATE NONCLUSTERED INDEX [Parr_Ca_Proc_Events_Index] ON [ORD_Matheny_201501042D].[Parr].[Cancer_Proc_Events]
(
	[PATID] ASC,
	[EventYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DefFG]
GO
ALTER TABLE [ORD_Matheny_201501042D].[Parr].[Cancer_Proc_Events] REBUILD PARTITION = ALL
WITH (DATA_COMPRESSION = PAGE);
GO
*/

* Create SAS data file rcr.cancer_proc_events;
PROC DATASETS library=rcr;
  delete cancer_proc_events;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.cancer_proc_events AS
  SELECT Ca_Procs.PATID
	, Ca_Procs.EventYear
	, MAX(Ca_Procs.Chemo_AnyEncount_Year_Prior) AS Chemo_AnyEncount_Year_Prior
	, MAX(Ca_Procs.Rad_AnyEncount_Year_Prior) AS Rad_AnyEncount_Year_Prior
  FROM
	(
		SELECT PE.PATID
		, PE.EventYear
		, CASE WHEN Chemo.Code IS NOT NULL THEN 1 ELSE 0
			END AS Chemo_AnyEncount_Year_Prior
		, CASE WHEN Rad.Code IS NOT NULL THEN 1 ELSE 0
			END AS Rad_AnyEncount_Year_Prior
		FROM rcr.patientevents as PE
		LEFT JOIN tiny.procedures as Procs
		ON PE.PATID = Procs.PATID
			AND Procs.ADMIT_DATE < PE.IndexDate
			AND Procs.ADMIT_DATE > INTNX('day', PE.IndexDate, -365, 'same')     
			AND Procs.ENC_TYPE IN ('AV', 'IP', 'ED', 'EI', 'OS', 'OA')
		LEFT JOIN nfval.chemononfinal as Chemo 
		ON Chemo.Code = Procs.PX /* Column name for Chemo.Code will need to be adjusted based on final value set */
			/* Chemo.[Code System] names will likely be different in final value set */
			AND ((Chemo.'Code System'n = 'CPT/HCPCS' AND Procs.PX_TYPE = 'CH')
			OR (Chemo.'Code System'n IN ('ICD10CM', 'ICD10PCS') AND Procs.PX_TYPE = '10')
			OR (Chemo.'Code System'n = 'ICD9CM' AND Procs.PX_TYPE = '09'))
		LEFT JOIN nfval.radiationnonfinal as Rad 
		ON Rad.Code = Procs.PX /* Column name for Rad.Code will need to be adjusted based on final value set */
			/* Rad.[Code System] names will likely be different in final value set */
			AND ((Rad.'Code System'n = 'CPT/HCPCS' AND Procs.PX_TYPE = 'CH')
			OR (Rad.'Code System'n IN ('ICD10CM', 'ICD10PCS') AND Procs.PX_TYPE = '10')
			OR (Rad.'Code System'n = 'ICD9CM' AND Procs.PX_TYPE = '09'))
	) as Ca_Procs
  GROUP BY Ca_Procs.PATID, Ca_Procs.EventYear
  ;
RUN;
QUIT;

proc contents data=rcr.cancer_proc_events; run;
proc print data=rcr.cancer_proc_events(firstobs=1 obs=100); run;

/*
if object_id('Parr.UDS_Events', 'U') is not NULL
	drop table Parr.UDS_Events;

SELECT PE.PATID
	, PE.EventYear
	, CASE WHEN UDS_LOINC.EventYear IS NOT NULL THEN 1 ELSE 0
		END AS UDS_LOINC
	, CASE WHEN (UDS_CPT1.EventYear IS NOT NULL OR UDS_CPT2.EventYear IS NOT NULL) THEN 1 ELSE 0
		END AS UDS_CPT
INTO Parr.UDS_Events
FROM Parr.PatientEvents as PE
LEFT JOIN
(
	SELECT PE.PATID
		, PE.EventYear
	FROM Parr.PatientEvents as PE
	INNER JOIN Src.PCOR_LAB_RESULT_CM as LAB_L 
	ON PE.PATID = LAB_L.PATID
	INNER JOIN Parr.UDS_Nonfinal AS UDS --Equivalent SAS dataset is udsnonfinal.sas7bdat
	ON UDS.Code = LAB_L.LAB_PX -- Column name for UDS.Code will need to be adjusted based on final value set
			-- UDS.[Code System] names will likely be different in final value set
	WHERE (UDS.[Code System] = 'LOINC' AND LAB_L.LAB_PX_TYPE = 'LC') 
		AND LAB_L.RESULT_DATE < PE.IndexDate
		AND LAB_L.RESULT_DATE > DATEADD(DD, -365, PE.IndexDate)
	GROUP BY PE.PATID, PE.EventYear) as UDS_LOINC
ON PE.PATID = UDS_LOINC.PATID AND PE.EventYear = UDS_LOINC.EventYear

LEFT JOIN

(
	SELECT PE.PATID
		, PE.EventYear
	FROM Parr.PatientEvents as PE
	INNER JOIN Src.PCOR_PROCEDURES as LAB_P
	ON PE.PATID = LAB_P.PATID
	INNER JOIN Parr.UDS_Nonfinal AS UDS --Equivalent SAS dataset is udsnonfinal.sas7bdat
	ON UDS.Code = LAB_P.PX -- Column name for UDS.Code will need to be adjusted based on final value set
			-- UDS.[Code System] names will likely be different in final value set
	WHERE (UDS.[Code System] = 'CPT/HCPCS' AND LAB_P.PX_TYPE = 'CH')
		AND LAB_P.ADMIT_DATE < PE.IndexDate
		AND LAB_P.ADMIT_DATE > DATEADD(DD, -365, PE.IndexDate)
	GROUP BY PE.PATID, PE.EventYear) as UDS_CPT1
ON PE.PATID = UDS_CPT1.PATID AND PE.EventYear = UDS_CPT1.EventYear

LEFT JOIN

(
	SELECT PE.PATID
		, PE.EventYear
	FROM Parr.PatientEvents as PE
	INNER JOIN Src.PCOR_LAB_RESULT_CM as LAB_L 
	ON PE.PATID = LAB_L.PATID
	INNER JOIN Parr.UDS_Nonfinal AS UDS --Equivalent SAS dataset is udsnonfinal.sas7bdat
	ON UDS.Code = LAB_L.LAB_PX -- Column name for UDS.Code will need to be adjusted based on final value set
			-- UDS.[Code System] names will likely be different in final value set
	WHERE (UDS.[Code System] = 'CPT/HCPCS' AND LAB_L.LAB_PX_TYPE = 'CH')
		AND LAB_L.RESULT_DATE < PE.IndexDate
		AND LAB_L.RESULT_DATE > DATEADD(DD, -365, PE.IndexDate)
	GROUP BY PE.PATID, PE.EventYear) as UDS_CPT2
ON PE.PATID = UDS_CPT2.PATID AND PE.EventYear = UDS_CPT2.EventYear

CREATE NONCLUSTERED INDEX [Parr_UDS_Events_Index] ON [ORD_Matheny_201501042D].[Parr].[UDS_Events] 
(
	[PATID] ASC,
	[EventYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DefFG]
GO
ALTER TABLE [ORD_Matheny_201501042D].[Parr].[UDS_Events]  REBUILD PARTITION = ALL
WITH (DATA_COMPRESSION = PAGE);
GO
*/

* Create SAS data file rcr.uds_events;
PROC DATASETS library=rcr;
  delete uds_events;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.uds_events AS
  SELECT PE.PATID
	, PE.EventYear
	, CASE WHEN UDS_LOINC.EventYear IS NOT NULL THEN 1 ELSE 0
		END AS UDS_LOINC
	, CASE WHEN (UDS_CPT1.EventYear IS NOT NULL OR UDS_CPT2.EventYear IS NOT NULL) THEN 1 ELSE 0
		END AS UDS_CPT
  FROM rcr.patientevents as PE
  LEFT JOIN
  (
	SELECT PE.PATID
		, PE.EventYear
	FROM rcr.patientevents as PE
	INNER JOIN tiny.lab_result_cm as LAB_L 
	ON PE.PATID = LAB_L.PATID
	INNER JOIN nfval.udsnonfinal AS UDS 
	ON UDS.Code = LAB_L.LAB_PX /* Column name for UDS.Code will need to be adjusted based on final value set */
			/* UDS.[Code System] names will likely be different in final value set */
	WHERE (UDS.'Code System'n = 'LOINC' AND LAB_L.LAB_PX_TYPE = 'LC') 
		AND LAB_L.RESULT_DATE < PE.IndexDate
		AND LAB_L.RESULT_DATE > INTNX('day', PE.IndexDate, -365, 'same')  
	GROUP BY PE.PATID, PE.EventYear) as UDS_LOINC
  ON PE.PATID = UDS_LOINC.PATID AND PE.EventYear = UDS_LOINC.EventYear

  LEFT JOIN

  (
	SELECT PE.PATID
		, PE.EventYear
	FROM rcr.patientevents as PE
	INNER JOIN tiny.procedures as LAB_P
	ON PE.PATID = LAB_P.PATID
	INNER JOIN nfval.udsnonfinal AS UDS 
	ON UDS.Code = LAB_P.PX /* Column name for UDS.Code will need to be adjusted based on final value set */
			/* UDS.[Code System] names will likely be different in final value set */
	WHERE (UDS.'Code System'n = 'CPT/HCPCS' AND LAB_P.PX_TYPE = 'CH')
		AND LAB_P.ADMIT_DATE < PE.IndexDate
		AND LAB_P.ADMIT_DATE > INTNX('day', PE.IndexDate, -365, 'same')  
	GROUP BY PE.PATID, PE.EventYear) as UDS_CPT1
  ON PE.PATID = UDS_CPT1.PATID AND PE.EventYear = UDS_CPT1.EventYear

  LEFT JOIN

  (
	SELECT PE.PATID
		, PE.EventYear
	FROM rcr.patientevents as PE
	INNER JOIN tiny.lab_result_cm as LAB_L 
	ON PE.PATID = LAB_L.PATID
	INNER JOIN nfval.udsnonfinal AS UDS 
	ON UDS.Code = LAB_L.LAB_PX /* Column name for UDS.Code will need to be adjusted based on final value set */
			/* UDS.[Code System] names will likely be different in final value set */
	WHERE (UDS.'Code System'n = 'CPT/HCPCS' AND LAB_L.LAB_PX_TYPE = 'CH')
		AND LAB_L.RESULT_DATE < PE.IndexDate
		AND LAB_L.RESULT_DATE > INTNX('day', PE.IndexDate, -365, 'same')  
	GROUP BY PE.PATID, PE.EventYear) as UDS_CPT2
  ON PE.PATID = UDS_CPT2.PATID AND PE.EventYear = UDS_CPT2.EventYear
  ;
RUN;
QUIT;

proc contents data=rcr.uds_events; run;
proc print data=rcr.uds_events(firstobs=1 obs=100); run;

/*
--ICD10CM
--ICD9CM
if object_id('Parr.Mental_Health_Events', 'U') is not NULL
	drop table Parr.Mental_Health_Events;
SELECT MH.PATID
	, MH.EventYear
	, MAX(MH.Mental_Health_Dx_Any_Prior) AS Mental_Health_Dx_Any_Prior
	, MAX(MH.Mental_Health_Dx_Year_Prior) AS Mental_Health_Dx_Year_Prior
INTO Parr.Mental_Health_Events
FROM
	(
		SELECT PE.PATID
		, PE.EventYear
		, CASE WHEN MH.Code IS NOT NULL THEN 1 ELSE 0
			END AS Mental_Health_Dx_Any_Prior
		, CASE WHEN (MH.Code IS NOT NULL AND Dx.ADMIT_DATE > DATEADD(DD, -365, PE.IndexDate)) THEN 1 ELSE 0
			END AS Mental_Health_Dx_Year_Prior
		FROM Parr.PatientEvents as PE
		LEFT JOIN Src.PCOR_DIAGNOSIS AS Dx
		ON PE.PATID = Dx.PATID
			AND Dx.ADMIT_DATE < PE.IndexDate
			AND Dx.ENC_TYPE IN ('AV', 'IP', 'ED', 'EI', 'OS', 'OA')
		LEFT JOIN Parr.Mental_Health_Dx_Nonfinal as MH --Equivalent SAS dataset is mentalhealthnonfinal.sas7bdat
		ON MH.Code = Dx.DX -- Column name for MH.Code will need to be adjusted based on final value set
			-- MH.[Code System] names will likely be different in final value set
			-- Following line may need to be changed based on final Value Set (currently has 'Primary' and 'Not Primary')
			AND MH.Recommendation = 'Primary'
			AND ((MH.[Code System] = 'ICD10CM' AND Dx.DX_TYPE = '10')
				OR (MH.[Code System] = 'ICD9CM' AND Dx.DX_TYPE = '09'))
	) as MH
GROUP BY MH.PATID, MH.EventYear
*/

* Create SAS data file rcr.mental_health_events;
PROC DATASETS library=rcr;
  delete mental_health_events;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.mental_health_events AS
  SELECT MH.PATID
	, MH.EventYear
	, MAX(MH.MH_Dx_Pri_Any_Prior) AS MH_Dx_Pri_Any_Prior
	, MAX(MH.MH_Dx_Pri_Year_Prior) AS MH_Dx_Pri_Year_Prior
	, MAX(MH.MH_Dx_Exp_Any_Prior) AS MH_Dx_Exp_Any_Prior
	, MAX(MH.MH_Dx_Exp_Year_Prior) AS MH_Dx_Exp_Year_Prior
  FROM
	(
		SELECT PE.PATID
		, PE.EventYear
		, CASE WHEN MH.Code IS NOT NULL AND MH.Code_Subset = 'Primary' THEN 1 ELSE 0
			END AS MH_Dx_Pri_Any_Prior
		, CASE WHEN (MH.Code IS NOT NULL AND MH.Code_Subset = 'Primary' AND Dx.ADMIT_DATE > INTNX('day', PE.IndexDate, -365, 'same')) THEN 1 ELSE 0
			END AS MH_Dx_Pri_Year_Prior
		, CASE WHEN MH.Code IS NOT NULL AND MH.Code_Subset = 'Exploratory' THEN 1 ELSE 0 
			END AS MH_Dx_Exp_Any_Prior
		, CASE WHEN (MH.Code IS NOT NULL AND MH.Code_Subset = 'Exploratory' AND Dx.ADMIT_DATE > INTNX('day', PE.IndexDate, -365, 'same')) THEN 1 ELSE 0
			END AS MH_Dx_Exp_Year_Prior
		FROM rcr.patientevents as PE
		LEFT JOIN tiny.diagnosis AS Dx
		ON PE.PATID = Dx.PATID
			AND Dx.ADMIT_DATE < PE.IndexDate
			AND Dx.ENC_TYPE IN ('AV', 'IP', 'ED', 'EI', 'OS', 'OA')
		LEFT JOIN fval.mentalhealth as MH 
		ON MH.Code = Dx.DX /* Column name for MH.Code will need to be adjusted based on final value set */
			/* MH.[Code System] names will likely be different in final value set */
			/* Following line may need to be changed based on final Value Set (currently has 'Primary' and 'Not Primary') */
			AND MH.Code_Subset = 'Primary'
			AND ((MH.DX_TYPE = '10' AND Dx.DX_TYPE = '10')
				OR (MH.DX_TYPE = '09' AND Dx.DX_TYPE = '09'))
	) as MH
  GROUP BY MH.PATID, MH.EventYear
  ;
RUN;
QUIT;

proc contents data=rcr.mental_health_events; run;
proc print data=rcr.mental_health_events(firstobs=1 obs=100); run;

/*
if object_id('Parr.BDZ_Events', 'U') is not NULL
	drop table Parr.BDZ_Events;

SELECT PE.PATID
	, PE.EventYear
	, CASE WHEN PRESC.EventYear IS NOT NULL THEN 1 ELSE 0
		END AS BDZ_Presc_3mo
	, CASE WHEN DISP.EventYear IS NOT NULL THEN 1 ELSE 0
		END AS BDZ_Disp_3mo
INTO Parr.BDZ_Events
FROM Parr.PatientEvents as PE
LEFT JOIN
	(
		SELECT PE.PATID
		, PE.EventYear
		FROM Parr.PatientEvents as PE
		INNER JOIN Src.PCOR_PRESCRIBING as PRESC
		ON PE.PATID = PRESC.PATID
		INNER JOIN Parr.BDZ_CUIs_Nonfinal as CUI  -- Placeholder table name (value set not available yet)
		ON CUI.Code = PRESC.RXNORM_CUI
		WHERE PRESC.RX_ORDER_DATE < DATEADD(MM, 3, PE.IndexDate)
			AND PRESC.RX_ORDER_DATE > DATEADD(MM, -3, PE.IndexDate)
		GROUP BY PE.PATID, PE.EventYear 
	) as PRESC
ON PE.PATID = PRESC.PATID AND PE.EventYear = PRESC.EventYear
LEFT JOIN
	(
		SELECT PE.PATID
		, PE.EventYear
		FROM Parr.PatientEvents as PE
		INNER JOIN Src.PCOR_DISPENSING as DISP
		ON PE.PATID = DISP.PATID
		INNER JOIN Parr.BDZ_NDCs_Nonfinal as NDC  -- Placeholder table name (value set not available yet)
		ON NDC.Code = DISP.NDC
		WHERE DISP.DISPENSE_DATE < DATEADD(MM, 3, PE.IndexDate)
			AND DISP.DISPENSE_DATE > DATEADD(MM, -3, PE.IndexDate)
		GROUP BY PE.PATID, PE.EventYear 
	) as DISP
ON PE.PATID = DISP.PATID AND PE.EventYear = DISP.EventYear
*/

* Create SAS data file rcr.bdz_events;
PROC DATASETS library=rcr;
  delete bdz_events;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.bdz_events AS
  SELECT PE.PATID
	, PE.EventYear
	, CASE WHEN PRESC.EventYear IS NOT NULL THEN 1 ELSE 0
		END AS BDZ_Presc_3mo
	, CASE WHEN DISP.EventYear IS NOT NULL THEN 1 ELSE 0
		END AS BDZ_Disp_3mo
  FROM rcr.patientevents as PE
  LEFT JOIN
	(
		SELECT PE.PATID
		, PE.EventYear
		FROM rcr.patientevents as PE
		INNER JOIN tiny.prescribing as PRESC
		ON PE.PATID = PRESC.PATID
		INNER JOIN nfval.bdzcuisnonfinal as CUI  /* Placeholder table name (value set not available yet) */
		ON CUI.Code = PRESC.RXNORM_CUI
		WHERE PRESC.RX_ORDER_DATE < INTNX('month', PE.IndexDate, 3, 'same')
			AND PRESC.RX_ORDER_DATE > INTNX('month', PE.IndexDate, -3, 'same')
		GROUP BY PE.PATID, PE.EventYear 
	) as PRESC
  ON PE.PATID = PRESC.PATID AND PE.EventYear = PRESC.EventYear
  LEFT JOIN
	(
		SELECT PE.PATID
		, PE.EventYear
		FROM rcr.patientevents as PE
		INNER JOIN tiny.dispensing as DISP
		ON PE.PATID = DISP.PATID
		INNER JOIN nfval.bdzndcsnonfinal as NDC  /* Placeholder table name (value set not available yet) */
		ON NDC.Code = DISP.NDC
		WHERE DISP.DISPENSE_DATE < INTNX('month', PE.IndexDate, 3, 'same')
			AND DISP.DISPENSE_DATE > INTNX('month', PE.IndexDate, -3, 'same')
		GROUP BY PE.PATID, PE.EventYear 
	) as DISP
  ON PE.PATID = DISP.PATID AND PE.EventYear = DISP.EventYear
  ;
RUN;
QUIT;

proc contents data=rcr.bdz_events; run;
proc print data=rcr.bdz_events(firstobs=1 obs=100); run;

/*
if object_id('Parr.Opioid_Flat_File', 'U') is not NULL
	drop table Parr.Opioid_Flat_File;

SELECT DEMO.*
	, EVNTS.[IndexDate]
    , EVNTS.[PRESCRIBINGID]
    , EVNTS.[RX_ORDER_DATE]
    , EVNTS.[RXNORM_CUI]
    , EVNTS.[DISPENSINGID]
    , EVNTS.[DISPENSE_DATE]
    , EVNTS.[NDC]
	, CASE
		WHEN (RX_ORDER_DATE IS NOT NULL OR DISPENSE_DATE IS NOT NULL) THEN 1 ELSE 0
		END AS OPIOID_FLAG
    , EVNTS.[ENCOUNTERID]
    , EVNTS.[ADMIT_DATE]
    , EVNTS.[ENC_TYPE]
	, CA_DX.Cancer_AnyEncount_Dx_Year_Prior
	, CA_DX.Cancer_Inpt_Dx_Year_Prior
	, CA_PROC.Chemo_AnyEncount_Year_Prior
	, CA_PROC.Rad_AnyEncount_Year_Prior
	, CASE
		WHEN (CA_PROC.Chemo_AnyEncount_Year_Prior = 1
				OR CA_PROC.Rad_AnyEncount_Year_Prior = 1) THEN 1 ELSE 0
		END AS CANCER_PROC_FLAG
	, UDS.UDS_LOINC
	, UDS.UDS_CPT
	, CASE	
		WHEN (UDS.UDS_LOINC = 1 OR UDS.UDS_CPT = 1) THEN 1 ELSE 0
		END AS UDS_FLAG
	, Mental_Health_Dx_Any_Prior
	, Mental_Health_Dx_Year_Prior
--	, BDZ_Presc_3mo
--	, BDZ_Disp_3mo
--	, CASE WHEN (BDZ_Presc_3mo IS NOT NULL OR BDZ_Disp_3mo IS NOT NULL) THEN 1 ELSE 0
--		END AS BDZ_3mo
INTO Parr.Opioid_Flat_File
FROM Parr.PatientDemo as DEMO
LEFT JOIN Parr.PatientEvents as EVNTS
ON DEMO.PATID = EVNTS.PATID AND DEMO.EventYear = EVNTS.EventYear
LEFT JOIN Parr.Cancer_Dx_Events as CA_DX
ON DEMO.PATID = CA_DX.PATID AND DEMO.EventYear = CA_DX.EventYear
LEFT JOIN Parr.Cancer_Proc_Events as CA_PROC
ON DEMO.PATID = CA_PROC.PATID AND DEMO.EventYear = CA_PROC.EventYear
LEFT JOIN Parr.UDS_Events AS UDS
ON DEMO.PATID = UDS.PATID AND DEMO.EventYear = UDS.EventYear
LEFT JOIN Parr.Mental_Health_Events as MH
ON DEMO.PATID = MH.PATID AND DEMO.EventYear = MH.EventYear
--LEFT JOIN Parr.BDZ_Events as BDZ
--ON DEMO.PATID = BDZ.PATID AND DEMO.EventYear = BDZ.EventYear
WHERE DEMO.AgeAsOfJuly1 >= 0  -- Changed by SKP from 18 to 0 on 1/7/2019

CREATE NONCLUSTERED INDEX [Parr_Opioid_Flat_Idx] ON [ORD_Matheny_201501042D].[Parr].[Opioid_Flat_File] 
(
	[PATID] ASC,
	[EventYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [DefFG]
GO
ALTER TABLE [ORD_Matheny_201501042D].[Parr].[Opioid_Flat_File]   REBUILD PARTITION = ALL
WITH (DATA_COMPRESSION = PAGE);
GO
*/

* Create SAS data file rcr.opioid_flat_file;
PROC DATASETS library=rcr;
  delete opioid_flat_file;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.opioid_flat_file AS
  SELECT DEMO.*
	, EVNTS.IndexDate
    , EVNTS.PRESCRIBINGID
    , EVNTS.RX_ORDER_DATE
    , EVNTS.RXNORM_CUI
    , EVNTS.DISPENSINGID
    , EVNTS.DISPENSE_DATE
    , EVNTS.NDC
	, CASE
		WHEN (RX_ORDER_DATE IS NOT NULL OR DISPENSE_DATE IS NOT NULL) THEN 1 ELSE 0
		END AS OPIOID_FLAG
    , EVNTS.ENCOUNTERID
    , EVNTS.ADMIT_DATE
    , EVNTS.ENC_TYPE
	, CA_DX.Cancer_AnyEncount_Dx_Year_Prior
	, CA_DX.Cancer_Inpt_Dx_Year_Prior
	, CA_PROC.Chemo_AnyEncount_Year_Prior
	, CA_PROC.Rad_AnyEncount_Year_Prior
	, CASE
		WHEN (CA_PROC.Chemo_AnyEncount_Year_Prior = 1
				OR CA_PROC.Rad_AnyEncount_Year_Prior = 1) THEN 1 ELSE 0
		END AS CANCER_PROC_FLAG
	, UDS.UDS_LOINC
	, UDS.UDS_CPT
	, CASE	
		WHEN (UDS.UDS_LOINC = 1 OR UDS.UDS_CPT = 1) THEN 1 ELSE 0
		END AS UDS_FLAG
	, MH_Dx_Pri_Any_Prior
	, MH_Dx_Pri_Year_Prior
	, MH_Dx_Exp_Any_Prior
	, MH_Dx_Exp_Year_Prior
  /* , BDZ_Presc_3mo */
  /* , BDZ_Disp_3mo */
  /* , CASE WHEN (BDZ_Presc_3mo IS NOT NULL OR BDZ_Disp_3mo IS NOT NULL) THEN 1 ELSE 0 */
  /* END AS BDZ_3mo */
  FROM rcr.patientdemo as DEMO
  LEFT JOIN rcr.patientevents as EVNTS
  ON DEMO.PATID = EVNTS.PATID AND DEMO.EventYear = EVNTS.EventYear
  LEFT JOIN rcr.cancer_dx_events as CA_DX
  ON DEMO.PATID = CA_DX.PATID AND DEMO.EventYear = CA_DX.EventYear
  LEFT JOIN rcr.cancer_proc_events as CA_PROC
  ON DEMO.PATID = CA_PROC.PATID AND DEMO.EventYear = CA_PROC.EventYear
  LEFT JOIN rcr.uds_events AS UDS
  ON DEMO.PATID = UDS.PATID AND DEMO.EventYear = UDS.EventYear
  LEFT JOIN rcr.mental_health_events as MH
  ON DEMO.PATID = MH.PATID AND DEMO.EventYear = MH.EventYear
  /* LEFT JOIN Parr.BDZ_Events as BDZ */
  /* ON DEMO.PATID = BDZ.PATID AND DEMO.EventYear = BDZ.EventYear */
  WHERE DEMO.AgeAsOfJuly1 >= 0  /* Changed by SKP from 18 to 0 on 1/7/2019 */
  ;
RUN;
QUIT;

proc contents data=rcr.opioid_flat_file; run;
proc print data=rcr.opioid_flat_file(firstobs=1 obs=100); run;

/*
-- Added by SKP on 1/7/2019
-- Prevalence Numerator
if object_id('TempDB..#PrevNum', 'U') is not NULL
	drop table #PrevNum;
GO

SELECT *
INTO #PrevNum
FROM Parr.Opioid_Flat_File
WHERE OPIOID_FLAG = 1 AND ADMIT_DATE IS NOT NULL
*/

* Create SAS data file rcr.prevnum;
PROC DATASETS library=rcr;
  delete prevnum;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.prevnum AS
  SELECT *
  FROM rcr.opioid_flat_file
  WHERE OPIOID_FLAG = 1 AND ADMIT_DATE IS NOT NULL
  ;
RUN;
QUIT;

proc contents data=rcr.prevnum; run;
proc print data=rcr.prevnum(firstobs=1 obs=100); run;

/*
-- Prevalence Denominator
if object_id('TempDB..#PrevDenom', 'U') is not NULL
	drop table #PrevDenom;
GO

SELECT *
INTO #PrevDenom
FROM Parr.Opioid_Flat_File 
WHERE ADMIT_DATE IS NOT NULL
*/

* Create SAS data file rcr.prevdenom;
PROC DATASETS library=rcr;
  delete prevdenom;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.prevdenom AS
  SELECT *
  FROM rcr.opioid_flat_file 
  WHERE ADMIT_DATE IS NOT NULL
  ;
RUN;
QUIT;

proc contents data=rcr.prevdenom; run;
proc print data=rcr.prevdenom(firstobs=1 obs=100); run;

/*
-- Guideline A Numerator
if object_id('TempDB..#GuidelineANum', 'U') is not NULL
	drop table #GuidelineANum;
GO

SELECT *
INTO #GuidelineANum
FROM Parr.Opioid_Flat_File
WHERE OPIOID_FLAG = 1 AND ADMIT_DATE IS NOT NULL AND Cancer_AnyEncount_Dx_Year_Prior = 0
*/

* Create SAS data file rcr.guidelineanum;
PROC DATASETS library=rcr;
  delete guidelineanum;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.guidelineanum AS
  SELECT *
  FROM rcr.opioid_flat_file
  WHERE OPIOID_FLAG = 1 AND ADMIT_DATE IS NOT NULL AND Cancer_AnyEncount_Dx_Year_Prior = 0
  ;
RUN;
QUIT;

proc contents data=rcr.guidelineanum; run;
proc print data=rcr.guidelineanum(firstobs=1 obs=100); run;

/*
-- Guideline A Denominator
if object_id('TempDB..#GuidelineADenom', 'U') is not NULL
	drop table #GuidelineADenom;
GO

SELECT *
INTO #GuidelineADenom
FROM Parr.Opioid_Flat_File
WHERE ADMIT_DATE IS NOT NULL AND Cancer_AnyEncount_Dx_Year_Prior = 0
*/

* Create SAS data file rcr.guidelineadenom;
PROC DATASETS library=rcr;
  delete guidelineadenom;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.guidelineadenom AS
  SELECT *
  FROM rcr.opioid_flat_file
  WHERE ADMIT_DATE IS NOT NULL AND Cancer_AnyEncount_Dx_Year_Prior = 0
  ;
RUN;
QUIT;

proc contents data=rcr.guidelineadenom; run;
proc print data=rcr.guidelineadenom(firstobs=1 obs=100); run;

/*
-- Guideline B Numerator
if object_id('TempDB..#GuidelineBNum', 'U') is not NULL
	drop table #GuidelineBNum;
GO

SELECT *
INTO #GuidelineBNum
FROM Parr.Opioid_Flat_File
WHERE OPIOID_FLAG = 1 AND ADMIT_DATE IS NOT NULL AND Cancer_Inpt_Dx_Year_Prior = 0
	AND Chemo_AnyEncount_Year_Prior = 0 and Rad_AnyEncount_Year_Prior = 0
*/

* Create SAS data file rcr.guidelinebnum;
PROC DATASETS library=rcr;
  delete guidelinebnum;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.guidelinebnum AS
  SELECT *
  FROM rcr.opioid_flat_file
  WHERE OPIOID_FLAG = 1 AND ADMIT_DATE IS NOT NULL AND Cancer_Inpt_Dx_Year_Prior = 0
	AND Chemo_AnyEncount_Year_Prior = 0 and Rad_AnyEncount_Year_Prior = 0
  ;
RUN;
QUIT;

proc contents data=rcr.guidelinebnum; run;
proc print data=rcr.guidelinebnum(firstobs=1 obs=100); run;

/*
-- Guideline B Denominator
if object_id('TempDB..#GuidelineBDenom', 'U') is not NULL
	drop table #GuidelineBDenom;
GO

SELECT *
INTO #GuidelineBDenom
FROM Parr.Opioid_Flat_File
WHERE ADMIT_DATE IS NOT NULL AND Cancer_Inpt_Dx_Year_Prior = 0
	AND Chemo_AnyEncount_Year_Prior = 0 and Rad_AnyEncount_Year_Prior = 0
*/

* Create SAS data file rcr.guidelinebdenom;
PROC DATASETS library=rcr;
  delete guidelinebdenom;
run;

PROC SQL inobs=max;
  CREATE TABLE rcr.guidelinebdenom AS
  SELECT *
  FROM rcr.opioid_flat_file
  WHERE ADMIT_DATE IS NOT NULL AND Cancer_Inpt_Dx_Year_Prior = 0
	AND Chemo_AnyEncount_Year_Prior = 0 and Rad_AnyEncount_Year_Prior = 0
  ;
RUN;
QUIT;

proc contents data=rcr.guidelinebdenom; run;
proc print data=rcr.guidelinebdenom(firstobs=1 obs=100); run;

/*
--if object_id('TempDB..#Examine', 'U') is not NULL
--	drop table #Examine;
--GO

--SELECT b.*
--	,  a.BIRTH_DATE
--	,  a.AgeAsOfJuly1 as [AGE]
--	,  a.RACE
--	,  a.HISPANIC
--	--,  d.PatientSSN
--	--,  d.PatientLastName
--	--,  d.PatientFirstName
--	, CASE
--		WHEN b.IndexDate = RX_ORDER_DATE OR b.IndexDate = DISPENSE_DATE THEN 1 ELSE 0
--		END AS OPIOID_QUALIFIER
--INTO #Examine
--FROM Parr.PatientDemo as a
--INNER JOIN Parr.PatientEvents as b
--ON a.PATID = b.PATID AND a.EventYear = b.EventYear
--INNER JOIN (SELECT DISTINCT a.PERSON_ID, b.PatientSSN, b.PatientLastName, b.PatientFirstName
--	FROM Src.OMOPV5_CohortCrosswalk as a
--	INNER JOIN Src.SPatient_SPatient as b
--	ON a.PatientICN = b.PatientICN) as d
--ON b.PATID = d.PERSON_ID
--ORDER BY a.PATID, a.EventYear
*/



