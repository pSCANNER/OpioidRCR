# OpioidRCR

Space for the PCORNet Rapid Cycle Research code (check ou this [toolkit](https://oig.hhs.gov/oei/reports/oei-02-17-00560.pdf)
### [Value Sets](/ValueSets)
* CDC Oral Opioids
* All Opioids
* Risk factors and outcomes- Exclusion criteria

### Replicating CDC Results
* [CDC SAS Code](https://www.cdc.gov/drugoverdose/data-files/SAScodetouseMMEconvsnfileSept2017.sas) to modify
* Crosswalks from CDC NDCs to RXNORM with same MMEs [here]
* TODO (if we decide): Crosswalks to average MMEs for less granular matches
* TO DECIDE How to impute MME and days supply when we don't have it (e.g. impute these based on CMS claims data)
* Table shells matching RX to provider zip code
* TODO SAS PROC SQL queries

### "Ad Hoc Queries" - Descriptive Statistics for deteriminants and outcomes from logic model
* Crosstabs for value sets over demographic and geographic variables
* High Dose (see [this SAS code](https://www.oig.hhs.gov/oei/reports/oei-02-17-00560.asp) from HHS - June 2018.)

### Regressions and Predictive Analyses
#### TODO: Specifications for Unit of analysis = zip code (one model)
* Get public data by zip code/county
#### TODO: Unit of analysis = person (one model per DMC)
* Specify Data Set: variables, any temporal conditions, and pivot logic from long to wide
* Specify Analytic Model(s): 
	* Predictors of guideline adherence (unit of analyis = provider)	
	* Predictors of high dose (unit of analysis = patient)
	* Predictors of outcomes (unit of analysis = patient)
