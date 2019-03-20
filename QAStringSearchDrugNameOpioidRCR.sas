/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Friday, February 15, 2019     TIME: 11:20:20 AM
PROJECT: ProjectOpioidRCRv2
PROJECT PATH: /data/dart/2015/ord_matheny_201501042d/Programs/RCR_Opioid_AdHoc/ProjectOpioidRCRv2.egp
---------------------------------------- */

%macro _eg_hidenotesandsource;
	%global _egnotes;
	%global _egsource;
	
	%let _egnotes=%sysfunc(getoption(notes));
	options nonotes;
	%let _egsource=%sysfunc(getoption(source));
	options nosource;
%mend _eg_hidenotesandsource;


%macro _eg_restorenotesandsource;
	%global _egnotes;
	%global _egsource;
	
	options &_egnotes;
	options &_egsource;
%mend _eg_restorenotesandsource;


/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


ODS PROCTITLE;
OPTIONS DEV=ACTIVEX;
FILENAME EGSRX TEMP;
ODS tagsets.sasreport13(ID=EGSRX) FILE=EGSRX
    STYLE=HTMLBlue
    STYLESHEET=(URL="file:///C:/Program%20Files/SASHome/SASEnterpriseGuide/7.1/Styles/HTMLBlue.css")
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
    ENCODING=UTF8
    options(rolap="on")
;

/*   START OF NODE: DemographicSubsetv1   */
%_eg_hidenotesandsource;



%_eg_restorenotesandsource;

%let StudyStartDate = '2010-01-01'; *Inclusive;


%let StudyEndDate = '2018-01-01'; *Exclusive;


PROC SQL  OUTOBS=20000 stimer;

	CREATE TABLE DMLocal.DEMOGRAPHICSUBSET AS 
		SELECT  t2.PATID, 
			
			T2.BIRTH_DATE AS BIRTH_DATE_D  FORMAT = MMDDYY8.,
			T2.BIRTH_DATE,
			T2.SEX,
			T2.RACE,
			T2.HISPANIC
			,RANUNI(25)AS SAS_RAND
				
	FROM INDATA.DEMOGRAPHIC AS T2
	ORDER BY SAS_RAND;
	QUIT;

 QUIT;

%_eg_hidenotesandsource;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

%_eg_restorenotesandsource;


/*   START OF NODE: StringSearchPrescribingv3   */
%_eg_hidenotesandsource;



%_eg_restorenotesandsource;




PROC SQL /*INOBS=5000*/ stimer;
	CREATE TABLE DMLocal.STRING_SR_PRESCRIBING AS 
		SELECT  t3.PATID, 
			t3.ENCOUNTERID, 
			t3.RX_ORDER_DATE AS RX_ORDER_DATE_D  FORMAT = MMDDYY8., 
			YEAR(T3.RX_ORDER_DATE) AS RX_YEAR ,
			t3.RX_START_DATE, 
			t3.RX_FREQUENCY, 
			t3.RXNORM_CUI, 
			t3.RAW_RX_MED_NAME,
			T2.BIRTH_DATE_D  FORMAT = MMDDYY8.,
			T2.SEX,
			T2.RACE,
			T2.HISPANIC
		FROM DMLocal.DEMOGRAPHICSUBSET AS T2
JOIN indata.prescribing t3 
			ON T2.PATID = T3.PATID
		WHERE t3.RXNORM_CUI IS NULL
		and (
(upcase(t3.RAW_RX_MED_NAME)) like upcase('Abstral  %')/*1053648BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Actiq  %')/*215008BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Allfen CD %')/*798756BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Allfen CDX %')/*798760BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Ambifed CD %')/*798979BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Ambifed-G CD %')/*798975BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Arymo %')/*1871435BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Ascomp %')/*1372693BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Astramorph %')/*885779BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Avinza %')/*352452BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Biotussin %')/*995842BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Bromplex HD %')/*404905BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Brontex %')/*215768BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('BroveX CB %')/*804570BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Brovex PBC %')/*804585BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('B-Tuss %')/*284665BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Butorphanol %')/*1841IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Butorphic %')/*1310923BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase(' Codeine %')/*993764BN  Capital and */
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase(' Codeine %')/*215989BN Cheracol with */
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Cheratussin %')/*995869BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Cheratussin DAC %')/*215992BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Codar AR %')/*1113999BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Codar D %')/*1145969BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Codar GF %')/*1114027BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Codeine %')/*2670IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Codrix %')/*702747BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('ColdCough PD %')/*801156BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('ConZip %')/*1148479BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Darvon-N %')/*92328BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('De-Chlor G %')/*404976BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('De-Chlor HC %')/*352575BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('De-Chlor MR %')/*404977BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('De-Chlor NX %')/*404978BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Demerol %')/*282381BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('dihydrocodeine %')/*23088IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Dilaudid %')/*224913BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Dilaudid %')/*358355BN Cough */
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Diskets %')/*670009BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Dolophine %')/*202370BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Dolorex Solution %')/*857190BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Duragesic %')/*151678BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Duramorph %')/*203355BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Dvorah %')/*2105924BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Embeda %')/*859959BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Endocet %')/*216903BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Endodan %')/*848763BN Reformulated May 2009*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Exalgo %')/*902730BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Fentanyl %')/*4337IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Fentora %')/*668619BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase(' Codeine %')/*217126BN Fioricet with */
/*OR (upcase(t3.RAW_RX_MED_NAME)) like upcase(‘Codeine %') 217127BN Fiorinal with */
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Flowtuss %')/*1650977BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Guiatuss AC %')/*217453BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Histex AC %')/*1661320BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Hycet %')/*542941BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Hycofenix %')/*1651559BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Hydro GP %')/*352693BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Hydrocodone %')/*5489IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Hydromet %')/*151875BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Hydromorphone %')/*3423IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Hydron CP %')/*352699BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Hydron EX %')/*352700BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Hydron KGS %')/*543192BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Hydro-PC II %')/*352694BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Hy-KXP %')/*405132BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Hy-Phen %')/*217574BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Hysingla %')/*1595731BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Ibudone %')/*1372755BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Infumorph %')/*203358BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Ionsys %')/*1666832BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Kadian %')/*203240BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('KGS HC %')/*605104BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Lazanda %')/*1115547BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Levomethadyl %')/*237005IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Levorphanol %')/*6378IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Levorphanol %')/*6378IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Lorcet %')/*491666BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Lortab %')/*144254BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Lortuss EX %')/*1147705BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Mar-cof BP %')/*877459BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Mar-cof CG %')/*831953BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Maxifed CD %')/*798910BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Maxifed-G CD %')/*798954BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Maxiphen CDX %')/*798939BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('M-Clear WC %')/*795452BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('M-End Max D %')/*1190581BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('M-End PE %')/*830707BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Meperidine %')/*6754IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Methadone %')/*6813IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Methadose %')/*152751BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Mitigo %')/*2055303BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Morphabond %')/*1745876BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Morphine %')/*7052IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('MS Contin %')/*203354BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Mytussin AC %')/*218549BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Nalex AC %')/*802738BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Nalocet %')/*2045495BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Nariz HC %')/*657414BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Nazarin HC %')/*700758BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Ninjacof XG %')/*1595209BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Norco %')/*218772BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Nucofed %')/*218809BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Nucofed Expectorant %')/*93566BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Nucynta %')/*854137BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Obredon %')/*1598279BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Opana %')/*643147BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Opium %')/*7676IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Oxaydo %')/*1664443BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Oxecta %')/*1113310BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Oxycodone %')/*7804IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Oxycontin %')/*218986BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Oxyfast %')/*218987BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Oxymorphone %')/*7814IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Panlor %')/*1995531BN Reformulated Jan 2018  */
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Pentazocine %')/*8001IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Percocet %')/*42844BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Percodan %')/*848769BN Reformulated May 2009  */
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Phenylhistine DH %')/*219225BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Primlev %')/*1537111BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Prolex DH %')/*219437BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Propoxyphene %')/*8785IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Pseudodine C %')/*836627BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('P-V-Tussin %')/*219013BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Relasin HC %')/*647309BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Relcof C %')/*1086923BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Reprexain %')/*579458BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Rezira %')/*1114335BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Robafen AC %')/*219689BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Roxicet %')/*219739BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Roxicodone %')/*219740BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Roxybond %')/*1944530BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Ryzolt %')/*831433BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Simuc-HD %')/*607431BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase(' Codeine %')/*219980BN Soma Compound with */
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Statuss Green %')/*1242553BN Reformulated Jan 2012  */
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Sublimaze %')/*4336BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Subsys %')/*1237051BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Su-Tuss HD %')/*860527BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Synalgos-DC %')/*220143BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Talwin %')/*8002BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('tapentadol %')/*787390IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Torbugesic %')/*1489987BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Torphaject %')/*1947134BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Tramadol %')/*10689IN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Trezix %')/*746611BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Triacin C %')/*220422BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Triant-HC %')/*405367BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Troxyca %')/*1806702BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Tusnel C %')/*672059BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('TussiCaps %')/*730984BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Tussigon %')/*220542BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Tussionex %')/*544165BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Tuxarin %')/*2099281BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Tuzistra %')/*1652088BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase(' Codeine %')/*220586BN Tylenol with */
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Ultracet %')/*353062BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Ultram %')/*220606BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Ventuss %')/*220776BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Verdrocet %')/*1542976BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Vicodin %')/*128793BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Vicoprofen %')/*220826BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Vituz %')/*1372868BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Xartemis %')/*1491784BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Xodol %')/*540447BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Xolox %')/*832700BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Xtampza %')/*1790528BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Xylon %')/*1542983BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Z Tuss AC %')/*995129BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Zamicet %')/*804747BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Zodryl AC %')/*1372746BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Zodryl DAC %')/*1372725BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Zodryl DEC %')/*1372714BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Zohydro %')/*1442523BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Zotex C %')/*996581BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Zutripro %')/*1112221BN*/
OR (upcase(t3.RAW_RX_MED_NAME)) like upcase('Zydone %')/*221046BN*/
)


ORDER BY PATID, RX_ORDER_DATE;
QUIT;



/*PROC SQL /*INOBS=5000*/ /*stimer;
	CREATE TABLE DRNOC.STRING_NO_RESULTS_PRESCRIBING AS 
			select RS.RESULT_COUNT, 'RXNORM_CUI_NULL_ALL_ROWS' AS QA_RESULT 
			FROM (SELECT count(*) as RESULT_COUNT
			from DMLocal.STRING_SR_PRESCRIBING) AS rs
			WHERE RESULT_COUNT =0; 
QUIT;
*/

%_eg_hidenotesandsource;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

%_eg_restorenotesandsource;


/*   START OF NODE: StringGroupPrescribingv1   */
%_eg_hidenotesandsource;



%_eg_restorenotesandsource;


PROC SQL /*INOBS=5000*/ stimer;
	CREATE TABLE DMLocal.STRING_GROUP_PRESCRIBING AS 
		SELECT  t7.PATID, 
			
			T7.RX_YEAR ,
			MIN(t7.RX_ORDER_DATE_D) AS FIRSTSTRING_YEAR  FORMAT = MMDDYY8. 
		FROM DMLocal.STRING_SR_PRESCRIBING AS T7
		GROUP BY t7.PATID,
			T7.RX_YEAR ;
			 

QUIT;

%_eg_hidenotesandsource;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

%_eg_restorenotesandsource;


/*   START OF NODE: EncSearchEncounterv1   */
%_eg_hidenotesandsource;



%_eg_restorenotesandsource;




PROC SQL /*INOBS=5000*/ stimer;
	CREATE TABLE DMLocal.ENC_SR_ENCOUNTER AS 
		SELECT  t4.PATID,
 			t4.ENC_TYPE, 
			t4.ENCOUNTERID, 
			
			YEAR(t4.ADMIT_DATE) as ADM_YEAR  ,
			t4.ADMIT_DATE AS ADMIT_DATE_D  FORMAT = MMDDYY8.,
			T2.BIRTH_DATE_D  FORMAT = MMDDYY8.,
			T2.SEX,
			T2.RACE,
			T2.HISPANIC
		FROM DMLocal.DEMOGRAPHICSUBSET AS T2
JOIN indata.diagnosis t4 
			ON T2.PATID = T4.PATID
		WHERE T4.ENC_TYPE IN (
		'AV','EI','IP','OS','ED','OA'
		) 
        and t4.dx is not null
ORDER BY T4.PATID, T4.ADMIT_DATE;


	QUIT;


%_eg_hidenotesandsource;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

%_eg_restorenotesandsource;


/*   START OF NODE: EncGroupEncounterv1   */
%_eg_hidenotesandsource;



%_eg_restorenotesandsource;



proc sql STIMER;
create table DMLocal.GROUP_YEAR_ENCOUNTER AS  
Select T5.PATID,
	   T5.ADM_YEAR,
	   /*(year(t5.ADMIT_DATE_D)) as YEAR_ADMIT_DATE  FORMAT = YEAR4.,
	   min(T5.ADM_YEAR) as FIRSTENC_YEAR FORMAT = YEAR4.*/
	   MIN(t5.ADMIT_DATE_D) AS FIRSTENC_YEAR FORMAT = MMDDYY8.
FROM DMLocal.ENC_SR_ENCOUNTER AS T5
GROUP BY T5.PATID,
	   T5.ADM_YEAR;



QUIT;




%_eg_hidenotesandsource;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

%_eg_restorenotesandsource;


/*   START OF NODE: RxNormSearchPrescribingv1    */
%_eg_hidenotesandsource;



%_eg_restorenotesandsource;




PROC SQL /*INOBS=5000*/ stimer;
	CREATE TABLE DMLocal.RXNORM_SR_PRESCRIBING AS 
		SELECT  t3.PATID, 
			t3.ENCOUNTERID, 
			t3.RX_ORDER_DATE AS RX_ORDER_DATE_D  FORMAT = MMDDYY8., 
			year(T3.RX_ORDER_DATE) AS RX_YEAR ,
			t3.RX_START_DATE, 
			t3.RX_FREQUENCY, 
			t3.RXNORM_CUI, 
			t3.RAW_RX_MED_NAME,
			T2.BIRTH_DATE_D  FORMAT = MMDDYY8.,
			T2.SEX,
			T2.RACE,
			T2.HISPANIC
		FROM DMLocal.DEMOGRAPHICSUBSET AS T2
JOIN indata.prescribing t3 
			ON T2.PATID = T3.PATID
		WHERE t3.RXNORM_CUI IN (SELECT
		CODE FROM infolder.OPIOIDCUI
						)
			 

ORDER BY PATID, RX_ORDER_DATE;


 
	QUIT;


%_eg_hidenotesandsource;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

%_eg_restorenotesandsource;


/*   START OF NODE: RxNORMGroupPrescribingv1   */
%_eg_hidenotesandsource;



%_eg_restorenotesandsource;




PROC SQL /*INOBS=5000*/ stimer;
	CREATE TABLE DMLocal.RXNORM_GROUP_PRESCRIBING AS 
		SELECT  t7.PATID, 
			
			T7.RX_YEAR ,
			MIN(t7.RX_ORDER_DATE_D) AS FIRSTRXNORM_YEAR  FORMAT = MMDDYY8. 
		FROM DMLocal.RXNORM_SR_PRESCRIBING AS T7
		GROUP BY t7.PATID,
			T7.RX_YEAR ;
			 

QUIT;

%_eg_hidenotesandsource;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

%_eg_restorenotesandsource;


/*   START OF NODE: EncGroupRXNORMStringGroupv1   */
%_eg_hidenotesandsource;



%_eg_restorenotesandsource;


proc sql STIMER;
create table DMLocal.ENC_RXNORM_STRING_GROUP_YEAR AS  
Select T8.PATID,
	   T8.ADM_YEAR,
	   T8.FIRSTENC_YEAR FORMAT = MMDDYY8.,
	   T9.RX_YEAR AS RX_YEAR_R,
	   T10.RX_YEAR AS RX_YEAR_S,
	   T9.FIRSTRXNORM_YEAR,
	   T10.FIRSTSTRING_YEAR
FROM DMLocal.GROUP_YEAR_ENCOUNTER AS T8
LEFT JOIN DMLocal.RXNORM_GROUP_PRESCRIBING AS T9
ON T9.PATID = T8.PATID
AND T8.ADM_YEAR = T9.RX_YEAR
LEFT JOIN DMLocal.STRING_GROUP_PRESCRIBING AS T10
ON T10.PATID = T8.PATID
AND T10.RX_YEAR = T8.ADM_YEAR
AND T9.FIRSTRXNORM_YEAR IS NULL
 
;


QUIT;




%_eg_hidenotesandsource;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

%_eg_restorenotesandsource;


/*   START OF NODE: CountPtEventYrBySourcev1   */
%_eg_hidenotesandsource;


%_eg_restorenotesandsource;


proc sql STIMER;
create table DMLocal.COUNT_PT_EVENT_STRINGRXNORM_YEAR AS  

SELECT COUNT(ENC_RXNORM_STRING_GROUP_YEAR.RX_YEAR_S) AS STRING_EVENT_YR 
		,COUNT(ENC_RXNORM_STRING_GROUP_YEAR.RX_YEAR_R) AS RXNORM_EVENT_YR
		,COUNT(ENC_RXNORM_STRING_GROUP_YEAR.ADM_YEAR) AS ENC_EVENT_YR
		,COUNT(ENC_RXNORM_STRING_GROUP_YEAR.RX_YEAR_S) + COUNT(ENC_RXNORM_STRING_GROUP_YEAR.RX_YEAR_R) AS SUM_EVENT_YR 
		,(COUNT(ENC_RXNORM_STRING_GROUP_YEAR.RX_YEAR_S) + COUNT(ENC_RXNORM_STRING_GROUP_YEAR.RX_YEAR_R))/COUNT(ENC_RXNORM_STRING_GROUP_YEAR.ADM_YEAR) AS RATIO_STRINGRXNORM_ENC_YEARS
		,(COUNT(ENC_RXNORM_STRING_GROUP_YEAR.RX_YEAR_R))/COUNT(ENC_RXNORM_STRING_GROUP_YEAR.ADM_YEAR) AS RATIO_RXNORM_ENC_YEARS
FROM DMLocal.ENC_RXNORM_STRING_GROUP_YEAR;




		QUIT;



%_eg_hidenotesandsource;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

%_eg_restorenotesandsource;


/*   START OF NODE: NDCSearchDispensingv1  - Copy   */
%_eg_hidenotesandsource;


%_eg_restorenotesandsource;



PROC SQL /*INOBS=5000*/ stimer;
	CREATE TABLE DMLocal.NDC_DISPENSING AS 
		SELECT  t3.PATID, 
			t3.DISPENSE_DATE AS DISPENSE_DATE_D  FORMAT = MMDDYY8., 
			year(T3.DISPENSE_DATE) AS RX_YEAR ,
			t3.DISPENSE_SUP, 
			t3.DISPENSE_AMT, 
			T2.BIRTH_DATE_D  FORMAT = MMDDYY8.,
			T2.SEX,
			T2.RACE,
			T2.HISPANIC
		FROM DMLocal.DEMOGRAPHICSUBSET AS T2
JOIN indata.DISPENSING t3 
			ON T2.PATID = T3.PATID
		WHERE t3.NDC IN (SELECT
		CODE FROM infolder.OPIOIDNDC
						)
			 

ORDER BY PATID, DISPENSE_DATE;


 
	QUIT;


%_eg_hidenotesandsource;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

%_eg_restorenotesandsource;


/*   START OF NODE: NDCGroupDispensingv1    */
%_eg_hidenotesandsource;


%_eg_restorenotesandsource;



PROC SQL /*INOBS=5000*/ stimer;
	CREATE TABLE DMLocal.NDC_GROUP_DISPENSING AS 
		SELECT  t7.PATID, 
			
			T7.RX_YEAR ,
			MIN(t7.DISPENSE_DATE_D) AS FIRSTNDC_YEAR  FORMAT = MMDDYY8. 
		FROM DMLocal.NDC_DISPENSING AS T7
		GROUP BY t7.PATID,
			T7.RX_YEAR ;
			 

QUIT;

%_eg_hidenotesandsource;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

%_eg_restorenotesandsource;


/*   START OF NODE: EncGroupRXNORMNDCStringGroupv1    */
%_eg_hidenotesandsource;


%_eg_restorenotesandsource;


proc sql STIMER;
create table DMLocal.ENC_RXNORM_NDC_STRING_GROUP_YEAR AS  
Select T8.PATID,
	   T8.ADM_YEAR,
	   T8.FIRSTENC_YEAR FORMAT = MMDDYY8.,
	   T9.RX_YEAR AS RX_YEAR_R,
	   T10.RX_YEAR AS RX_YEAR_S,
	   T11.RX_YEAR AS RX_YEAR_N,
	   T9.FIRSTRXNORM_YEAR,
	   T10.FIRSTSTRING_YEAR,
	   T11.FIRSTNDC_YEAR,
	   CASE 
	   WHEN T9.FIRSTRXNORM_YEAR IS NULL AND T11.FIRSTNDC_YEAR IS NULL AND FIRSTSTRING_YEAR IS NOT NULL THEN 'STRING'
	   WHEN T9.FIRSTRXNORM_YEAR IS NOT NULL AND T11.FIRSTNDC_YEAR IS NOT NULL THEN 'BOTH'
	   WHEN T9.FIRSTRXNORM_YEAR IS NOT NULL AND T11.FIRSTNDC_YEAR IS NULL THEN 'RXNORM'
	   WHEN T9.FIRSTRXNORM_YEAR IS NULL AND T11.FIRSTNDC_YEAR IS NOT NULL THEN 'NDC'
	   ELSE 'NONE' 
	   END AS OPIOIDSOURCE
FROM DMLocal.GROUP_YEAR_ENCOUNTER AS T8
LEFT JOIN DMLocal.RXNORM_GROUP_PRESCRIBING AS T9
ON T9.PATID = T8.PATID
AND T8.ADM_YEAR = T9.RX_YEAR
LEFT JOIN DMLocal.NDC_GROUP_DISPENSING AS T11
ON T11.PATID = T8.PATID
AND T11.RX_YEAR = T8.ADM_YEAR
LEFT JOIN DMLocal.STRING_GROUP_PRESCRIBING AS T10
ON T10.PATID = T8.PATID
AND T10.RX_YEAR = T8.ADM_YEAR

;


QUIT;




%_eg_hidenotesandsource;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

%_eg_restorenotesandsource;


/*   START OF NODE: CountPtEventYrRXNORMNDCBStringySourcev1   */
%_eg_hidenotesandsource;


%_eg_restorenotesandsource;


proc sql STIMER;
create table DMLocal.COUNT_EVENT_CODED_YEAR AS  

SELECT COUNT(*)AS CODED,	1 AS JJ	
FROM DMLocal.ENC_RXNORM_NDC_STRING_GROUP_YEAR
WHERE OPIOIDSOURCE = 'BOTH' OR OPIOIDSOURCE = 'NDC' OR OPIOIDSOURCE = 'RXNORM';

proc sql STIMER;
create table DMLocal.COUNT_EVENT_UNCODED_YEAR AS 
SELECT COUNT(*)AS UNCODED, 1 AS JJ		
FROM DMLocal.ENC_RXNORM_NDC_STRING_GROUP_YEAR
WHERE OPIOIDSOURCE = 'STRING' ;

proc sql STIMER;
create table DMLocal.COUNT_EVENT_ENC_YEAR AS
SELECT COUNT(ENC_RXNORM_NDC_STRING_GROUP_YEAR.ADM_YEAR) AS ENC_EVENT_YR, 1 AS JJ
FROM DMLocal.ENC_RXNORM_NDC_STRING_GROUP_YEAR;

proc sql STIMER;
create table DMLocal.COUNT_COMBINED_YEAR AS 

SELECT C2.CODED, C3.UNCODED, C1.ENC_EVENT_YR, (C2.CODED/C1.ENC_EVENT_YR) AS RATIO_CODEDOPIOID_ENC_EVENT_YR,
((C2.CODED+C3.UNCODED)/C1.ENC_EVENT_YR) AS RATIO_CODED_UNCODE_OPIOID_ENC_YR
FROM DMLocal.COUNT_EVENT_ENC_YEAR AS C1
LEFT JOIN DMLocal.COUNT_EVENT_CODED_YEAR AS C2
ON C2.JJ = C1.JJ
LEFT JOIN DMLocal.COUNT_EVENT_UNCODED_YEAR AS C3
ON C3.JJ = C2.JJ;
QUIT;
proc sql STIMER;
create table drnoc.RatioCodedUncodedDrugName AS 

SELECT RATIO_CODEDOPIOID_ENC_EVENT_YR, RATIO_CODED_UNCODE_OPIOID_ENC_YR, (RATIO_CODED_UNCODE_OPIOID_ENC_YR-RATIO_CODEDOPIOID_ENC_EVENT_YR) As DiffStringCodeUncode
FROM DMLocal.COUNT_COMBINED_YEAR; 
QUIT;





%_eg_hidenotesandsource;

%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

%_eg_restorenotesandsource;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;

