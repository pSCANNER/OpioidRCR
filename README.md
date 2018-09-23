# OpioidRCR

Space for the PCORNet Rapid Cycle Research code
### Value Sets
* CDC Oral Opioids
* All Opioids
* Risk factors and outcomes- Exclusion criteria

### Replicating CDC Results
* [CDC SAS Code](https://www.cdc.gov/drugoverdose/data-files/SAScodetouseMMEconvsnfileSept2017.sas)
* Crosswalks from CDC NDCs to RXNORM with same MMEs [here]
* TODO (if we decide): Crosswalks to average MMEs for less granular matches
* Table shells matching RX to provider zip code
* TODO SAS PROC SQL queries

### Descriptive Statistics for deteriminants and outcomes from logic model
* Crosstabs for value sets over demographic and geographic variables

### Regressions and Predictive Analyses
#### TODO: Specifications for Unit of analysis = zip code (one model)
* Get public data by zip code/county
#### TODO: Unit of analysis = person (one model per DMC)
* Specify Data Set: variables, any temporal conditions, and pivot logic from long to wide
* Specify Analytic Model(s): 
	* Predictors of guideline adherence (unit of analyis = provider)	
	* Predictors of high dose (unit of analysis = patient)
	* Predictors of outcomes (unit of analysis = patient)
