/* SELECT DISTINCT  <<FIELD_NAME>>, count(<<FIELDNAME>>) as freq  FROM <<TABLE_NAME>> */
/* group by <<FIELD_NAME>>                                                            */
/* order by freq desc;                                                                */

/* Profiling query from the dispensing table              */
/* Supply, Amount, Dose Dispensed and Dose Dispensed Unit */

proc sql;
create table dispensing_profilling as
SELECT DISTINCT  DISPENSE_SUP, count(DISPENSE_SUP) as freq1,
DISPENSE_AMT, count(DISPENSE_AMT) as freq2,
DISPENSE_DOSE_DISP, count(DISPENSE_DOSE_DISP) as freq3,
DISPENSE_DOSE_DISP_UNIT, count(DISPENSE_DOSE_DISP_UNIT) as freq4,
FROM DISPENSING, HARVEST
group by DATAMARTID 
order by freq desc;



/* Profiling query from the prescribing table            */
/* dose ordered, dose ordered unit, quantity, dose form, */
/* refills, days supply, frequency, 'as needed' flag,    */
/* route, basis                                          */              
   
proc sql;
create table prescribing_profilling as
SELECT DISTINCT  RX_DOSE_ORDERED, count(RX_DOSE_ORDERED) as freq1, 
RX_DOSE_ORDERED_UNIT, count(RX_DOSE_ORDERED_UNIT) as freq2 ,
RX_QUANTITY, count(RX_QUANTITY) as freq3, 
RX_DOSE_FORM, count(RX_DOSE_FORM) as freq4,  
RX_REFILLS, count(RX_REFILLS) as freq5,
RX_DAYS_SUPPLY, count(RX_DAYS_SUPPLY) as freq6, 
RX_FREQUENCY, count(RX_FREQUENCY) as freq7,
RX_PRN_FLAG, count(RX_PRN_FLAG) as freq8, 
RX_ROUTE, count(RX_ROUTE) as freq9,
RX_BASIS, count(RX_BASIS) as freq10
FROM one.PRESCRIBING, one.HARVEST
group by DATAMARTID 
quit;

