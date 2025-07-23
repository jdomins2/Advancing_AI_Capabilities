* Name: ai_exposure_crosswalk_to_scores_v4.do
* Author: Jacob Dominski
* Date Created: Febuary 28th, 2025


********************************************************************************************************************
*************************************************** Housekeeping ***************************************************
********************************************************************************************************************

************************************************ Set Global paths **************************************************

global data_root = "/Users/jdomins2/Desktop/CPS_Work/Data"
global crosswalk_root = "/Users/jdomins2/Desktop/CPS_Work/Crosswalks"
global export_root = "/Users/jdomins2/Desktop/CPS_Work/Output"
global deflator_root = "/Users/jdomins2/Desktop/CPS_Work/Deflators"
global code_root = "/Users/jdomins2/Desktop/CPS_Work/Code"

use "$crosswalk_root/onet_to_cps_crosswalk_cleaned.dta", clear
duplicates tag onet_code soc_code cps_code, generate(tag_exact)

********************************************************************************************************************
**************************************** Merging Exposure Data w/ Crosswalk ****************************************
********************************************************************************************************************
use "$crosswalk_root/onet_to_cps_crosswalk_cleaned.dta", clear
duplicates tag onet_code soc_code cps_code, generate(tag_exact)


*** Merge with AI Exposure Scores (ONET-Level) ***
merge m:1 onet_code using "$data_root/AI_exposure/v2/Working/onet_exposure_openai_claude_llama_v2.dta"

*** Drop unmatched observations ***
drop if _merge == 1   
drop _merge


********************************************************************************************************************
****************************************** Calculating ONET-Level Weights ******************************************
********************************************************************************************************************

*** Calculate ONET-level weights within each SOC-CPS pair ***
bysort soc_code cps_code (onet_code): gen num_valid_onet_codes = _N
gen onet_weight_valid = 1 / num_valid_onet_codes

*** Calculate onet level weighted exposure scores for Claude and OpenAI ***
foreach model in openai claude {
    forvalues stage = 1/5 {
        gen onet_`model'_weighted_exp_s`stage' = onet_`model'_exposure_stage`stage' * onet_weight_valid
    }
}

*** Handle Llama separately since it only has 3 stages ***
forvalues stage = 1/3 {
    gen onet_llama_weighted_exp_s`stage' = onet_llama_exposure_stage`stage' * onet_weight_valid
}

*** Handle ChatGPT separately since it only has a stage 2 score ***
gen onet_chatgpt_weighted_exp_s2 = onet_chatgpt_exposure_stage2_og * onet_weight_valid

*** Calculate onet level weighted confidence percentages ***
foreach model in openai claude {
    forvalues stage = 1/5 {
        gen `model'_onet_w_pct_high_conf_s`stage' = pct_high_conf_`model'_s`stage' * onet_weight_valid
        gen `model'_onet_w_pct_medium_conf_s`stage' = pct_medium_conf_`model'_s`stage' * onet_weight_valid
        gen `model'_onet_w_pct_low_conf_s`stage' = pct_low_conf_`model'_s`stage' * onet_weight_valid
    }
}

*** Sum ONET-level scores within each SOC-CPS occupation pair to get SOC level scores ***
foreach model in openai claude {
    forvalues stage = 1/5 {
        bysort cps_code soc_code (onet_code): gen soc_`model'_exp_s`stage' = sum(onet_`model'_weighted_exp_s`stage')
    }
}

*** Handle Llama separately since it only has 3 stages ***
forvalues stage = 1/3 {
    bysort cps_code soc_code (onet_code): gen soc_llama_exp_s`stage' = sum(onet_llama_weighted_exp_s`stage')
}

*** Handle ChatGPT separately since it only has a stage 2 score ***
bysort cps_code soc_code (onet_code): gen soc_chatgpt_exp_s2 = sum(onet_chatgpt_weighted_exp_s2)

*** Sum ONET-level confidence percentages to get SOC-CPS confidence percentages ***
foreach model in openai claude {
    forvalues stage = 1/5 {
        bysort cps_code soc_code (onet_code): gen soc_`model'_pct_high_conf_s`stage' = sum(`model'_onet_w_pct_high_conf_s`stage')
        bysort cps_code soc_code (onet_code): gen soc_`model'_pct_medium_conf_s`stage' = sum(`model'_onet_w_pct_medium_conf_s`stage')
        bysort cps_code soc_code (onet_code): gen soc_`model'_pct_low_conf_s`stage' = sum(`model'_onet_w_pct_low_conf_s`stage')
    }
}

*** Keep only the last observation within each SOC-CPS group ***
bysort cps_code soc_code (onet_code): keep if _n == _N

*** Check ***
list cps_code soc_code soc_openai_exp_s1 soc_claude_exp_s1 soc_llama_exp_s1 if _n < 20
list cps_code soc_code soc_openai_pct_high_conf_s1 soc_claude_pct_high_conf_s1 if _n < 20

save "$data_root/Working/sol_level_scores_v3", replace

********************************************************************************************************************
******************************************* Calculating SOC-Level Weights ******************************************
********************************************************************************************************************

*** Calculate SOC-level weights within each CPS category ***
bysort cps_code (soc_code): gen num_soc_codes_valid = _N
egen total_census_employment = total(tot_emp), by(cps_code)
gen soc_weight_valid = tot_emp / total_census_employment
replace soc_weight_valid = 1 if onet_code == "45-3031.00"

*** Apply SOC-level weights to AI exposure scores ***

foreach model in openai claude {
    forvalues stage = 1/5 {
        gen cps_`model'_exp_s`stage' = soc_`model'_exp_s`stage' * soc_weight_valid
    }
}

*** Handle Llama separately (Stages 1-3) ***
forvalues stage = 1/3 {
    gen cps_llama_exp_s`stage' = soc_llama_exp_s`stage' * soc_weight_valid
}

*** Handle ChatGPT separately (Stage 2 only) ***
gen cps_chatgpt_exp_s2 = soc_chatgpt_exp_s2 * soc_weight_valid

*** Apply SOC-level weights to confidence percentages ***
foreach model in openai claude {
    forvalues stage = 1/5 {
        gen cps_`model'_pct_high_conf_s`stage' = soc_`model'_pct_high_conf_s`stage' * soc_weight_valid
        gen cps_`model'_pct_medium_conf_s`stage' = soc_`model'_pct_medium_conf_s`stage' * soc_weight_valid
        gen cps_`model'_pct_low_conf_s`stage' = soc_`model'_pct_low_conf_s`stage' * soc_weight_valid
    }
}

*** Sum SOC-level scores within each CPS category to get final CPS-level scores ***
foreach model in openai claude {
    forvalues stage = 1/5 {
        egen cps_`model'_final_exp_s`stage' = total(cps_`model'_exp_s`stage'), by(cps_code)
    }
}

*** Handle Llama separately (Stages 1-3) ***
forvalues stage = 1/3 {
    egen cps_llama_final_exp_s`stage' = total(cps_llama_exp_s`stage'), by(cps_code)
}

*** Handle ChatGPT separately (Stage 2 only) ***
egen cps_chatgpt_final_exp_s2 = total(cps_chatgpt_exp_s2), by(cps_code)

*** Sum confidence percentages ***
foreach model in openai claude {
    forvalues stage = 1/5 {
        egen `model'_final_pct_high_conf_s`stage' = total(cps_`model'_pct_high_conf_s`stage'), by(cps_code)
        egen `model'_final_pct_medium_conf_s`stage' = total(cps_`model'_pct_medium_conf_s`stage'), by(cps_code)
        egen `model'_final_pct_low_conf_s`stage' = total(cps_`model'_pct_low_conf_s`stage'), by(cps_code)
    }
}

bysort cps_code (soc_code): keep if _n == _N


********************************************************************************************************************
****************************************** Final Verification and Export *******************************************
********************************************************************************************************************

* Verify that we have the expected number of unique CPS codes
distinct cps_code

*Drop uneccesary variables
drop soc_title_x soc_title_y num_occ_codes num_soc_codes
drop total_occ_employment soc_to_census_weighting_scenario
drop num_onet_codes onet_weight onet_weighting_scenario
drop total_census_employment 
drop tot_emp 
drop onet_llama_exposure_stage3 onet_llama_exposure_stage2 onet_llama_exposure_stage1

drop title onet_claude_exposure_stage1 onet_claude_exposure_stage2 onet_claude_exposure_stage3 onet_claude_exposure_stage4 onet_claude_exposure_stage5

drop soc_weight onet_chatgpt_exposure_stage2_og relevance pct_high_conf_claude_s1 pct_high_conf_claude_s2 pct_high_conf_claude_s3 pct_high_conf_claude_s4 pct_high_conf_claude_s5 pct_medium_conf_claude_s1 pct_medium_conf_claude_s2 pct_medium_conf_claude_s3 pct_medium_conf_claude_s4 pct_medium_conf_claude_s5 

drop pct_low_conf_claude_s1 pct_low_conf_claude_s2 pct_low_conf_claude_s3 pct_low_conf_claude_s4 pct_low_conf_claude_s5 onet_openai_exposure_stage1 onet_openai_exposure_stage2 onet_openai_exposure_stage3 onet_openai_exposure_stage4 onet_openai_exposure_stage5

drop pct_high_conf_openai_s1 pct_high_conf_openai_s2 pct_high_conf_openai_s3 pct_high_conf_openai_s4 pct_high_conf_openai_s5 pct_medium_conf_openai_s1 pct_medium_conf_openai_s2 pct_medium_conf_openai_s3 pct_medium_conf_openai_s4 pct_medium_conf_openai_s5 pct_low_conf_openai_s5 pct_low_conf_openai_s4 pct_low_conf_openai_s3 pct_low_conf_openai_s2 pct_low_conf_openai_s1

drop num_valid_onet_codes onet_weight_valid onet_openai_weighted_exp_s1 onet_openai_weighted_exp_s2 onet_openai_weighted_exp_s3 onet_openai_weighted_exp_s4 onet_openai_weighted_exp_s5 onet_claude_weighted_exp_s1 onet_claude_weighted_exp_s2 onet_claude_weighted_exp_s3 onet_claude_weighted_exp_s4 onet_claude_weighted_exp_s5 onet_llama_weighted_exp_s1 onet_llama_weighted_exp_s2 onet_llama_weighted_exp_s3 onet_chatgpt_weighted_exp_s2 

drop openai_onet_w_pct_high_conf_s1 openai_onet_w_pct_high_conf_s2 openai_onet_w_pct_high_conf_s3 openai_onet_w_pct_high_conf_s4 openai_onet_w_pct_high_conf_s5 openai_onet_w_pct_medium_conf_s1 openai_onet_w_pct_medium_conf_s2 openai_onet_w_pct_medium_conf_s3 openai_onet_w_pct_medium_conf_s4 openai_onet_w_pct_medium_conf_s5 openai_onet_w_pct_low_conf_s1 openai_onet_w_pct_low_conf_s2 openai_onet_w_pct_low_conf_s3 openai_onet_w_pct_low_conf_s4 openai_onet_w_pct_low_conf_s5

drop claude_onet_w_pct_high_conf_s1 claude_onet_w_pct_high_conf_s2 claude_onet_w_pct_high_conf_s3 claude_onet_w_pct_high_conf_s4 claude_onet_w_pct_high_conf_s5 claude_onet_w_pct_medium_conf_s1 claude_onet_w_pct_medium_conf_s2 claude_onet_w_pct_medium_conf_s3 claude_onet_w_pct_medium_conf_s4 claude_onet_w_pct_medium_conf_s5 claude_onet_w_pct_low_conf_s1 claude_onet_w_pct_low_conf_s2 claude_onet_w_pct_low_conf_s3 claude_onet_w_pct_low_conf_s4 claude_onet_w_pct_low_conf_s5

drop soc_openai_exp_s1 soc_openai_exp_s2 soc_openai_exp_s3 soc_openai_exp_s4 soc_openai_exp_s5 soc_claude_exp_s1 soc_claude_exp_s2 soc_claude_exp_s3 soc_claude_exp_s4 soc_claude_exp_s5 soc_llama_exp_s1 soc_llama_exp_s2 soc_llama_exp_s3 soc_chatgpt_exp_s2 soc_openai_pct_high_conf_s1 soc_openai_pct_high_conf_s2 soc_openai_pct_high_conf_s3 soc_openai_pct_high_conf_s4 soc_openai_pct_high_conf_s5 soc_openai_pct_medium_conf_s1 

drop soc_openai_pct_medium_conf_s2 soc_openai_pct_medium_conf_s3 soc_openai_pct_medium_conf_s4 soc_openai_pct_medium_conf_s5 soc_openai_pct_low_conf_s1 soc_openai_pct_low_conf_s2 soc_openai_pct_low_conf_s3 soc_openai_pct_low_conf_s4 soc_openai_pct_low_conf_s5

drop soc_claude_pct_high_conf_s1 soc_claude_pct_high_conf_s2 soc_claude_pct_high_conf_s3 soc_claude_pct_high_conf_s4 soc_claude_pct_high_conf_s5 soc_claude_pct_medium_conf_s1 soc_claude_pct_medium_conf_s2 soc_claude_pct_medium_conf_s3 soc_claude_pct_medium_conf_s4 soc_claude_pct_medium_conf_s5 soc_claude_pct_low_conf_s1 soc_claude_pct_low_conf_s2 soc_claude_pct_low_conf_s3 soc_claude_pct_low_conf_s4 soc_claude_pct_low_conf_s5 num_soc_codes_valid soc_weight_valid

drop cps_openai_exp_s1 cps_openai_exp_s2 cps_openai_exp_s3 cps_openai_exp_s4 cps_openai_exp_s5 cps_claude_exp_s1 cps_claude_exp_s2 cps_claude_exp_s3 cps_claude_exp_s4 cps_claude_exp_s5 cps_llama_exp_s1 cps_llama_exp_s2 cps_llama_exp_s3 cps_chatgpt_exp_s2

drop cps_openai_pct_high_conf_s1 cps_openai_pct_high_conf_s2 cps_openai_pct_high_conf_s3 cps_openai_pct_high_conf_s4 cps_openai_pct_high_conf_s5 cps_openai_pct_medium_conf_s1 cps_openai_pct_medium_conf_s2 cps_openai_pct_medium_conf_s3 cps_openai_pct_medium_conf_s4 cps_openai_pct_medium_conf_s5 cps_openai_pct_low_conf_s1 cps_openai_pct_low_conf_s2 cps_openai_pct_low_conf_s3 cps_openai_pct_low_conf_s4 cps_openai_pct_low_conf_s5

drop cps_claude_pct_high_conf_s1 cps_claude_pct_high_conf_s2 cps_claude_pct_high_conf_s3 cps_claude_pct_high_conf_s4 cps_claude_pct_high_conf_s5 cps_claude_pct_medium_conf_s1 cps_claude_pct_medium_conf_s2 cps_claude_pct_medium_conf_s3 cps_claude_pct_medium_conf_s4 cps_claude_pct_medium_conf_s5 cps_claude_pct_low_conf_s1 cps_claude_pct_low_conf_s2 cps_claude_pct_low_conf_s3 cps_claude_pct_low_conf_s4 cps_claude_pct_low_conf_s5
 
destring cps_code, replace 
save "$data_root/Ai_Exposure/v2/Cleaned/occ_exposure_openAI_claude_llama_v2.dta", replace

********************************************************************************************************************
*********************************************** Merging w/ CPS Data ************************************************
********************************************************************************************************************


use "$data_root/CPS/monthly_cps_march25", clear
rename occ cps_code
drop if cps_code == 0
merge m:1 cps_code using "$data_root/Ai_Exposure/v2/Cleaned/occ_exposure_openAI_claude_llama_v2.dta"

preserve
keep if _merge == 1
gen byte tag = 0
bysort cps_code (month year): replace tag = 1 if _n == 1
keep if tag == 1
drop tag
list cps_code
restore

* 13 Unique CPS observations unmatched with AI exposure scores; These occupations have the CPS codes: 2006 2014, 2060, 2180, 2770, 2865, 4160, 4655, 4965, 5040, 7855, 9150, 9840. The first 12 correspond to occupations that end with ",all other," for which we don't expect to have exposure scores. The last is military for which we also don't have exposure scores.
co


drop if cps_code == 0
drop if _merge == 1
drop if _merge == 2
drop _merge
save "$data_root/Cleaned/monthly_cps_w_exp_march25.dta", replace

********************************************************************************************************************
*********************************************** Merging w/ ASEC Data ***********************************************
********************************************************************************************************************

use "$data_root/Cleaned/ASEC_cleaned_v1", clear
drop if cps_code == "0"
merge m:1 cps_code using "$data_root/Ai_Exposure/v2/Cleaned/occ_exposure_openAI_claude_llama_v2.dta"

*** Investigating unmatched obs ***
*** List distinct CPS codes for unmatched observations ***
preserve
keep if _merge == 1
duplicates drop cps_code, force
list cps_code
restore
*** The 13 unamtched ASEC occupations are all occupations that we would expect to be missing AI scores - 12 are "...,all other" while one is "armed forces"***
drop if _merge == 1
drop if _merge == 2
drop _merge
save "$data_root/Cleaned/ASEC_w_scores_v1.dta", replace


