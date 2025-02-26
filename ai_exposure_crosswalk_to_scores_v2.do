* Name: ai_exposure_crosswalk_to_scores_v2.do
* Author: Jacob Dominski
* Date Created: Febuary 24, 2025
* Last Updated:

********************************************************************************************************************
*************************************************** Housekeeping ***************************************************
********************************************************************************************************************

************************************************ Set Global paths **************************************************
global data_root = "/Users/jdomins2/Desktop/CPS_Work/Data"
global crosswalk_root = "/Users/jdomins2/Desktop/CPS_Work/Crosswalks"
global export_root = "/Users/jdomins2/Desktop/CPS_Work/Output"
global deflator_root = "/Users/jdomins2/Desktop/CPS_Work/Deflators"
global code_root = "/Users/jdomins2/Desktop/CPS_Work/Code"

****************************************** AI exposure data (O*Net level) ******************************************
use "$data_root/AI_Exposure/Llama_onetdata.dta", clear

rename onetsoccode onet_code
rename title onet_title
drop GenAI_per LLM_per preLLM_per LLM_perw preLLM_perw ChatGPTscore ChatGPTscorew relevance
tostring onet_code, replace

save "$data_root/AI_Exposure/ai_exposure_v1_cleaned.dta", replace


********************************************************************************************************************
****************************************************** Merging *****************************************************
********************************************************************************************************************

************************************************** Initial Merge ***************************************************
use "$crosswalk_root/onet_to_cps_crosswalk_cleaned.dta", clear

* Merge with AI Exposure Scores (ONET-Level)
merge m:1 onet_code using "$data_root/AI_Exposure/ai_exposure_v1_cleaned.dta"
drop if _merge == 1   // Drop unmatched ONET occupations since they have no AI score
drop _merge
drop if missing(GenAI_perw) // Drop ONET occupations with missing AI scores

save "$data_root/AI_Exposure/ai_exposure_v1_merge_1.dta", replace


********************************************************************************************************************
******************************************* Calculating ONET-Level Weights ******************************************
********************************************************************************************************************

use "$data_root/AI_Exposure/ai_exposure_v1_merge_1.dta", clear

* Calculate ONET-level weights within each CPS code
bysort soc_code cps_code (onet_code): gen num_valid_onet_codes = _N
gen onet_weight_valid = 1 / num_valid_onet_codes
gen onet_weighted_ai_score = GenAI_perw * onet_weight_valid

* Sum ONET-level scores within each CPS occupation (accounting for SOC category)
bysort cps_code soc_code (onet_code): gen soc_ai_score = sum(onet_weighted_ai_score)

* Keep only the last observation within each SOC-CPS group
bysort cps_code soc_code (onet_code): keep if _n == _N


save "$data_root/AI_Exposure/ai_exposure_v1_onet_level_cleaned.dta", replace


********************************************************************************************************************
******************************************* Calculating SOC-Level Weights ******************************************
********************************************************************************************************************

use "$data_root/AI_Exposure/ai_exposure_v1_onet_level_cleaned.dta", clear

* Correct SOC-level weights within each CPS category
bysort cps_code (soc_code): gen num_soc_codes_valid = _N
egen total_census_employment = total(tot_emp), by(cps_code)
gen soc_weight_valid = tot_emp / total_census_employment

save "$data_root/AI_Exposure/ai_exposure_v1_soc_level_cleaned.dta", replace


********************************************************************************************************************
****************************************** Creating Census-Level AI Scores *****************************************
********************************************************************************************************************

use "$data_root/AI_Exposure/ai_exposure_v1_soc_level_cleaned.dta", clear

* Calculate final Census-level AI score using SOC weights
gen soc_weighted_ai_score = soc_ai_score * soc_weight
bysort cps_code (soc_code): gen occ_ai_score = sum(soc_weighted_ai_score)

* Keep only one observation per CPS code (last observation in each category)
bysort cps_code (soc_code): keep if _n == _N

* Save the final dataset with CPS-level AI scores
save "$data_root/AI_Exposure/ai_exposure_v1_final.dta", replace


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

