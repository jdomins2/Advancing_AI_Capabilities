* Name: ai_exposure_crosswalk_to_scores_v2.do
* Author: Jacob Dominski
* Date Created: Febuary 24, 2025
* Last Updated: Febuary 26th, 2025

********************************************************************************************************************
*************************************************** Housekeeping ***************************************************
********************************************************************************************************************

************************************************ Set Global paths **************************************************

global data_root = "/Users/jdomins2/Desktop/CPS_Work/Data"
global crosswalk_root = "/Users/jdomins2/Desktop/CPS_Work/Crosswalks"
global export_root = "/Users/jdomins2/Desktop/CPS_Work/Output"
global deflator_root = "/Users/jdomins2/Desktop/CPS_Work/Deflators"
global code_root = "/Users/jdomins2/Desktop/CPS_Work/Code"

***************************************** Briefly Clean The Exposure Data ******************************************

use "$data_root/AI_Exposure/Llama_onetdata.dta", clear
rename onetsoccode onet_code
rename title onet_title
drop GenAI_per LLM_per preLLM_per LLM_perw preLLM_perw ChatGPTscore ChatGPTscorew relevance
tostring onet_code, replace
save "$data_root/AI_Exposure/ai_exposure_v1_cleaned.dta", replace

******************************************** Briefly Clean The CPS Data ********************************************
use "$data_root/CPS/monthly_cps_v1.dta", clear
*21,811,973 observations*
keep if year>=2020
*6,256,626 obs*
keep if age>=18
*4,944,587 obs*
keep if age<65
*3,649,860 obs*
drop if occ == 0
*2,790,143 obs*

*** Creating a time variable such that the time 0 corresponds with the introduction of ChatGPT (Nov 30, 2022) ***
gen time = ym(year, month) 
format time %tm 
br time 
gen ntime=time-755 

*** Restricting time to 25 months before the introduction of ChatGPT ***
keep if ntime >= -25
*ChatGPT first released to the public on November 30th, 2022 ~ December, 2022; December 2022 = 755*

*** Creating dummy for unemployed, experienced worker ***
gen Dunemp=0 if empstat~=.
replace Dunemp=1 if empstat==21 & Dunemp~=.

*** Creating dummy for unemployed, new worker ***
gen Dunemp_new=0 if empstat~=.
replace Dunemp_new=1 if empstat==22 & Dunemp_new~=.

*** Fixing hours worked ***
replace ahrsworkt=. if ahrsworkt>=999
tab ahrsworkt
replace ahrswork1=. if ahrswork1>=999
tab ahrswork1
replace uhrsworkt=. if uhrsworkt>=997
replace uhrswork1=. if uhrswork1>=997

*** Renaming my CPS code & converting it to string ***
rename occ cps_code
tostring cps_code, replace

save "$data_root/Cleaned/monthly_cps_cleaned_v1", replace
********************************************************************************************************************
**************************************** Merging Exposure Data w/ Crosswalk ****************************************
********************************************************************************************************************
use "$crosswalk_root/onet_to_cps_crosswalk_cleaned.dta", clear

*** Merge with AI Exposure Scores (ONET-Level) ***
merge m:1 onet_code using "$data_root/AI_Exposure/ai_exposure_v1_cleaned.dta"

*** Drop unmatched observations ***
drop if _merge == 1   
drop _merge

*** Drop obs missing AI scores ***
drop if missing(GenAI_perw)


********************************************************************************************************************
****************************************** Calculating ONET-Level Weights ******************************************
********************************************************************************************************************

*** Calculate ONET-level weights within each SOC-CPS pair ***
bysort soc_code cps_code (onet_code): gen num_valid_onet_codes = _N
gen onet_weight_valid = 1 / num_valid_onet_codes
gen onet_weighted_ai_score = GenAI_perw * onet_weight_valid

*** Sum ONET-level scores within each SOC-CPS occupation pair to get SOC level scores ***
bysort cps_code soc_code (onet_code): gen soc_ai_score = sum(onet_weighted_ai_score)

*** Keep only the last observation within each SOC-CPS group ***
bysort cps_code soc_code (onet_code): keep if _n == _N


********************************************************************************************************************
******************************************* Calculating SOC-Level Weights ******************************************
********************************************************************************************************************

*** Calculate SOC-level weights within each CPS category ***
bysort cps_code (soc_code): gen num_soc_codes_valid = _N
egen total_census_employment = total(tot_emp), by(cps_code)
gen soc_weight_valid = tot_emp / total_census_employment

*** Calculate final Census-level AI score using SOC-level weights ***
gen soc_weighted_ai_score = soc_ai_score * soc_weight_valid
bysort cps_code (soc_code): gen occ_ai_score = sum(soc_weighted_ai_score)

*** Keep only one observation per CPS code (last observation in each category) ***
bysort cps_code (soc_code): keep if _n == _N

********************************************************************************************************************
****************************************** Final Verification and Export *******************************************
********************************************************************************************************************

* Verify that we have the expected number of unique CPS codes
distinct cps_code

*Drop uneccesary variables
drop num_valid_onet_codes onet_weight_valid onet_weighted_ai_score
drop num_soc_codes_valid soc_weight_valid soc_weight
drop soc_ai_score soc_weighted_ai_score
drop soc_title_x soc_title_y num_occ_codes num_soc_codes
drop total_occ_employment soc_to_census_weighting_scenario
drop num_onet_codes onet_weight onet_weighting_scenario
drop total_census_employment 
drop GenAI_perw

save "$data_root/ai_exposure_v1_final.dta", replace

********************************************************************************************************************
******************************************* Merging w/ AI Exposure Data ********************************************
********************************************************************************************************************

use "$data_root/Cleaned/monthly_cps_cleaned_v1", clear
merge m:1 cps_code using "$export_root/ai_exposure_v1_final.dta"
drop if cps_code == "0"
drop if _merge == 1
save "$data_root/Cleaned/monthly_cps_w_ai_scores.dta", replace
