* Name: ai_exposure_aggregation_onet_level
* Author: Jacob Dominski
* Date Created: Febuary 25, 2025
* Last Updated: Feb

*******************************************************************************************************************
************************************************** Housekeeping ***************************************************
*******************************************************************************************************************

************************************************ Set Global paths *************************************************
global data_root = "/Users/jdomins2/Desktop/CPS_Work/Data"
global crosswalk_root = "/Users/jdomins2/Desktop/CPS_Work/Crosswalks"
global export_root = "/Users/jdomins2/Desktop/CPS_Work/Output"
global deflator_root = "/Users/jdomins2/Desktop/CPS_Work/Deflators"
global code_root = "/Users/jdomins2/Desktop/CPS_Work/Code"

********************************************************************************************************************
******************************************** Aggregating Open AI scores ********************************************
********************************************************************************************************************
import delimited "$data_root/AI_exposure/v2/Original/Task_Statements_output.csv", clear

merge 1:m taskid using "$data_root/AI_exposure/Tasks/Task_Ratings_for_merge.dta"
gen missing_task_rank = missing(DataValue)
bysort onetsoccode (missing_task_rank): gen total_missing = sum(missing_task_rank)
gen use_simple_avg = total_missing > 0
drop if _merge == 2
replace ScaleID = "RT" if missing_task_rank == 1
keep if ScaleID == "RT" 
drop missing_task_rank total_missing _merge
rename stage_1_percentage openai_stage_1_percentage
rename stage_2_percentage openai_stage_2_percentage
rename stage_3_percentage openai_stage_3_percentage
rename stage_4_percentage openai_stage_4_percentage
rename stage_5_percentage openai_stage_5_percentage

rename stage_1_explanation openai_stage_1_explanation
rename stage_2_explanation openai_stage_2_explanation
rename stage_3_explanation openai_stage_3_explanation
rename stage_4_explanation openai_stage_4_explanation
rename stage_5_explanation openai_stage_5_explanation

rename stage_1_confidence openai_stage_1_confidence
rename stage_2_confidence openai_stage_2_confidence
rename stage_3_confidence openai_stage_3_confidence
rename stage_4_confidence openai_stage_4_confidence
rename stage_5_confidence openai_stage_5_confidence

export delimited using "$data_root/AI_exposure/Tasks/onet_task_level_data.csv", replace
save "$data_root/AI_exposure/onet_task_level.dta", replace


gen high_confidence_stage1  = stage_1_confidence == "High"
gen medium_confidence_stage1 = stage_1_confidence == "Medium"
gen low_confidence_stage1  = stage_1_confidence == "Low"

gen high_confidence_stage2  = stage_2_confidence == "High"
gen medium_confidence_stage2 = stage_2_confidence == "Medium"
gen low_confidence_stage2  = stage_2_confidence == "Low"

gen high_confidence_stage3  = stage_3_confidence == "High"
gen medium_confidence_stage3 = stage_3_confidence == "Medium"
gen low_confidence_stage3  = stage_3_confidence == "Low"

gen high_confidence_stage4  = stage_4_confidence == "High"
gen medium_confidence_stage4 = stage_4_confidence == "Medium"
gen low_confidence_stage4  = stage_4_confidence == "Low"

gen high_confidence_stage5  = stage_5_confidence == "High"
gen medium_confidence_stage5 = stage_5_confidence == "Medium"
gen low_confidence_stage5  = stage_5_confidence == "Low"


gen weighted_exposure_openai_stage1 = stage_1_percentage * DataValue if use_simple_avg == 0
gen weighted_exposure_openai_stage2 = stage_2_percentage * DataValue if use_simple_avg == 0
gen weighted_exposure_openai_stage3 = stage_3_percentage * DataValue if use_simple_avg == 0
gen weighted_exposure_openai_stage4 = stage_4_percentage * DataValue if use_simple_avg == 0
gen weighted_exposure_openai_stage5 = stage_5_percentage * DataValue if use_simple_avg == 0

replace weighted_exposure_openai_stage1 = stage_1_percentage if use_simple_avg == 1
replace weighted_exposure_openai_stage2 = stage_2_percentage if use_simple_avg == 1
replace weighted_exposure_openai_stage3 = stage_3_percentage if use_simple_avg == 1
replace weighted_exposure_openai_stage4 = stage_4_percentage if use_simple_avg == 1
replace weighted_exposure_openai_stage5 = stage_5_percentage if use_simple_avg == 1

replace DataValue = 1 if use_simple_avg == 1

collapse (sum) weighted_exposure_openai_stage1 weighted_exposure_openai_stage2 weighted_exposure_openai_stage3 weighted_exposure_openai_stage4 weighted_exposure_openai_stage5 high_confidence_stage1 medium_confidence_stage1 low_confidence_stage1 high_confidence_stage2 medium_confidence_stage2 low_confidence_stage2 high_confidence_stage3 medium_confidence_stage3 low_confidence_stage3 high_confidence_stage4 medium_confidence_stage4 low_confidence_stage4 high_confidence_stage5 medium_confidence_stage5 low_confidence_stage5 DataValue, by(onetsoccode)

gen onet_openai_exposure_stage1 = weighted_exposure_openai_stage1 / DataValue
gen onet_openai_exposure_stage2 = weighted_exposure_openai_stage2 / DataValue
gen onet_openai_exposure_stage3 = weighted_exposure_openai_stage3 / DataValue
gen onet_openai_exposure_stage4 = weighted_exposure_openai_stage4 / DataValue
gen onet_openai_exposure_stage5 = weighted_exposure_openai_stage5 / DataValue

gen total_tasks_stage1 = high_confidence_stage1 + medium_confidence_stage1 + low_confidence_stage1
gen total_tasks_stage2 = high_confidence_stage2 + medium_confidence_stage2 + low_confidence_stage2
gen total_tasks_stage3 = high_confidence_stage3 + medium_confidence_stage3 + low_confidence_stage3
gen total_tasks_stage4 = high_confidence_stage4 + medium_confidence_stage4 + low_confidence_stage4
gen total_tasks_stage5 = high_confidence_stage5 + medium_confidence_stage5 + low_confidence_stage5

gen pct_high_conf_openai_s1 = high_confidence_stage1 / total_tasks_stage1
gen pct_medium_conf_openai_s1 = medium_confidence_stage1 / total_tasks_stage1
gen pct_low_conf_openai_s1 = low_confidence_stage1 / total_tasks_stage1

gen pct_high_conf_openai_s2 = high_confidence_stage2 / total_tasks_stage2
gen pct_medium_conf_openai_s2 = medium_confidence_stage2 / total_tasks_stage2
gen pct_low_conf_openai_s2 = low_confidence_stage2 / total_tasks_stage2

gen pct_high_conf_openai_s3 = high_confidence_stage3 / total_tasks_stage3
gen pct_medium_conf_openai_s3 = medium_confidence_stage3 / total_tasks_stage3
gen pct_low_conf_openai_s3 = low_confidence_stage3 / total_tasks_stage3

gen pct_high_conf_openai_s4 = high_confidence_stage4 / total_tasks_stage4
gen pct_medium_conf_openai_s4 = medium_confidence_stage4 / total_tasks_stage4
gen pct_low_conf_openai_s4 = low_confidence_stage4 / total_tasks_stage4

gen pct_high_conf_openai_s5 = high_confidence_stage5 / total_tasks_stage5
gen pct_medium_conf_openai_s5 = medium_confidence_stage5 / total_tasks_stage5
gen pct_low_conf_openai_s5 = low_confidence_stage5 / total_tasks_stage5

drop weighted_exposure_openai_stage1 weighted_exposure_openai_stage2 weighted_exposure_openai_stage3 weighted_exposure_openai_stage4 weighted_exposure_openai_stage5

drop high_confidence_stage1 medium_confidence_stage1 low_confidence_stage1 high_confidence_stage2 medium_confidence_stage2 low_confidence_stage2 high_confidence_stage3 medium_confidence_stage3 low_confidence_stage3 high_confidence_stage4 medium_confidence_stage4 low_confidence_stage4 high_confidence_stage5 medium_confidence_stage5 low_confidence_stage5 DataValue

drop total_tasks_stage1 total_tasks_stage2 total_tasks_stage3 total_tasks_stage4 total_tasks_stage5

save "$data_root/AI_exposure/v2/Working/onet_exposure_openai_v2.dta", replace

********************************************************************************************************************
******************************************** Aggregating Claude scores *********************************************
********************************************************************************************************************
import delimited "$data_root/AI_exposure/v2/Original/Task_Statements_Claude_output.csv", clear

merge 1:m taskid using "$data_root/AI_exposure/Tasks/Task_Ratings_for_merge.dta"
drop if _merge == 2
gen missing_task_rank = missing(DataValue)
bysort onetsoccode (missing_task_rank): gen total_missing = sum(missing_task_rank)
gen use_simple_avg = total_missing > 0
replace ScaleID = "RT" if missing_task_rank == 1
keep if ScaleID == "RT" 

drop missing_task_rank total_missing _merge


rename stage_1_percentage claude_stage_1_percentage
rename stage_2_percentage claude_stage_2_percentage
rename stage_3_percentage claude_stage_3_percentage
rename stage_4_percentage claude_stage_4_percentage
rename stage_5_percentage claude_stage_5_percentage

rename stage_1_explanation claude_stage_1_explanation
rename stage_2_explanation claude_stage_2_explanation
rename stage_3_explanation claude_stage_3_explanation
rename stage_4_explanation claude_stage_4_explanation
rename stage_5_explanation claude_stage_5_explanation

rename stage_1_confidence claude_stage_1_confidence
rename stage_2_confidence claude_stage_2_confidence
rename stage_3_confidence claude_stage_3_confidence
rename stage_4_confidence claude_stage_4_confidence
rename stage_5_confidence claude_stage_5_confidence

merge 1:1 taskid using "$data_root/AI_exposure/onet_task_level.dta"
drop _merge

export delimited using "$data_root/AI_exposure/Tasks/onet_task_level_data.csv", replace
save "$data_root/AI_exposure/onet_task_level.dta", replace

import delimited "$data_root/AI_exposure/Llama/Original/Llamma_GenAIoutput", clear varnames(1)
replace taskid = trim(taskid)  // Removes leading and trailing spaces
gen taskid_fixed = substr(taskid, 1, 10)  // Convert long string to a fixed length (10 is safe)
replace taskid = taskid_fixed
drop taskid_fixed
compress
drop if missing(taskid)
drop in 19282/19285


merge 1:m taskid using "$data_root/AI_exposure/Tasks/Task_Ratings_for_merge.dta"
drop if _merge == 2
gen missing_task_rank = missing(DataValue)
bysort onetsoccode (missing_task_rank): gen total_missing = sum(missing_task_rank)
gen use_simple_avg = total_missing > 0
replace ScaleID = "RT" if missing_task_rank == 1
keep if ScaleID == "RT" 

drop missing_task_rank total_missing _merge
rename label llama_stage_3_percentage
destring taskid, replace


merge 1:1 taskid using "$data_root/AI_exposure/onet_task_level.dta"
drop _merge

export delimited using "$data_root/AI_exposure/Tasks/onet_task_level_data.csv", replace
save "$data_root/AI_exposure/onet_task_level.dta", replace


import delimited "$data_root/AI_exposure/Llama/Original/Llamma_LLMoutput_clean.csv", clear varnames(1)
merge 1:m taskid using "$data_root/AI_exposure/Tasks/Task_Ratings_for_merge.dta"
drop if _merge == 2
gen missing_task_rank = missing(DataValue)
bysort onetsoccode (missing_task_rank): gen total_missing = sum(missing_task_rank)
gen use_simple_avg = total_missing > 0
replace ScaleID = "RT" if missing_task_rank == 1
keep if ScaleID == "RT" 
drop missing_task_rank total_missing _merge
rename label llama_stage_2_percentage

merge 1:1 taskid using "$data_root/AI_exposure/onet_task_level.dta"
drop _merge

export delimited using "$data_root/AI_exposure/Tasks/onet_task_level_data.csv", replace
save "$data_root/AI_exposure/onet_task_level.dta", replace

import delimited "$data_root/AI_exposure/Llama/Original/Llamma_preLLMoutput.csv", clear varnames(1)
drop if missing(taskid)
drop in 1551
drop in 1951
drop in 7290
drop in 8234
drop in 8341
drop in 13517
destring taskid, replace
merge 1:m taskid using "$data_root/AI_exposure/Tasks/Task_Ratings_for_merge.dta"

drop if _merge == 2
gen missing_task_rank = missing(DataValue)
bysort onetsoccode (missing_task_rank): gen total_missing = sum(missing_task_rank)
gen use_simple_avg = total_missing > 0
replace ScaleID = "RT" if missing_task_rank == 1
keep if ScaleID == "RT" 
drop missing_task_rank total_missing _merge
rename label llama_stage_1_percentage
drop incumbentsresponding

merge 1:1 taskid using "$data_root/AI_exposure/onet_task_level.dta"
drop _merge
drop ONETSOCCode Title ScaleName Category Date DomainSource task duplicate_count


export delimited using "$data_root/AI_exposure/Tasks/onet_task_level_data.csv", replace
save "$data_root/AI_exposure/onet_task_level.dta", replace

import delimited using "$data_root/AI_exposure/Tasks/onet_task_level_data.csv", clear

    
    replace llama_stage_3_percentage = subinstr(llama_stage_3_percentage, "%", "", .)

    * Convert "No Data" to missing
    replace llama_stage_3_percentage = "" if llama_stage_3_percentage == "No data"

    * Convert the cleaned values to numeric
    destring llama_stage_3_percentage, replace

list llama_stage_3_percentage if real(llama_stage_3_percentage) == . & llama_stage_3_percentage != "" , sepby(llama_stage_3_percentage)




gen high_confidence_stage1  = stage_1_confidence == "High"
gen medium_confidence_stage1 = stage_1_confidence == "Medium"
gen low_confidence_stage1  = stage_1_confidence == "Low"

gen high_confidence_stage2  = stage_2_confidence == "High"
gen medium_confidence_stage2 = stage_2_confidence == "Medium"
gen low_confidence_stage2  = stage_2_confidence == "Low"

gen high_confidence_stage3  = stage_3_confidence == "High"
gen medium_confidence_stage3 = stage_3_confidence == "Medium"
gen low_confidence_stage3  = stage_3_confidence == "Low"

gen high_confidence_stage4  = stage_4_confidence == "High"
gen medium_confidence_stage4 = stage_4_confidence == "Medium"
gen low_confidence_stage4  = stage_4_confidence == "Low"

gen high_confidence_stage5  = stage_5_confidence == "High"
gen medium_confidence_stage5 = stage_5_confidence == "Medium"
gen low_confidence_stage5  = stage_5_confidence == "Low"

gen weighted_exposure_claude_stage1 = stage_1_percentage * DataValue if use_simple_avg == 0
gen weighted_exposure_claude_stage2 = stage_2_percentage * DataValue if use_simple_avg == 0
gen weighted_exposure_claude_stage3 = stage_3_percentage * DataValue if use_simple_avg == 0
gen weighted_exposure_claude_stage4 = stage_4_percentage * DataValue if use_simple_avg == 0
gen weighted_exposure_claude_stage5 = stage_5_percentage * DataValue if use_simple_avg == 0

replace weighted_exposure_claude_stage1 = stage_1_percentage if use_simple_avg == 1
replace weighted_exposure_claude_stage2 = stage_2_percentage if use_simple_avg == 1
replace weighted_exposure_claude_stage3 = stage_3_percentage if use_simple_avg == 1
replace weighted_exposure_claude_stage4 = stage_4_percentage if use_simple_avg == 1
replace weighted_exposure_claude_stage5 = stage_5_percentage if use_simple_avg == 1

replace DataValue = 1 if use_simple_avg == 1

collapse (sum) weighted_exposure_claude_stage1 weighted_exposure_claude_stage2 weighted_exposure_claude_stage3 weighted_exposure_claude_stage4 weighted_exposure_claude_stage5 high_confidence_stage1 medium_confidence_stage1 low_confidence_stage1 high_confidence_stage2 medium_confidence_stage2 low_confidence_stage2 high_confidence_stage3 medium_confidence_stage3 low_confidence_stage3 high_confidence_stage4 medium_confidence_stage4 low_confidence_stage4 high_confidence_stage5 medium_confidence_stage5 low_confidence_stage5 DataValue, by(onetsoccode)

gen onet_claude_exposure_stage1 = weighted_exposure_claude_stage1 / DataValue
gen onet_claude_exposure_stage2 = weighted_exposure_claude_stage2 / DataValue
gen onet_claude_exposure_stage3 = weighted_exposure_claude_stage3 / DataValue
gen onet_claude_exposure_stage4 = weighted_exposure_claude_stage4 / DataValue
gen onet_claude_exposure_stage5 = weighted_exposure_claude_stage5 / DataValue


gen total_tasks_stage1 = high_confidence_stage1 + medium_confidence_stage1 + low_confidence_stage1
gen total_tasks_stage2 = high_confidence_stage2 + medium_confidence_stage2 + low_confidence_stage2
gen total_tasks_stage3 = high_confidence_stage3 + medium_confidence_stage3 + low_confidence_stage3
gen total_tasks_stage4 = high_confidence_stage4 + medium_confidence_stage4 + low_confidence_stage4
gen total_tasks_stage5 = high_confidence_stage5 + medium_confidence_stage5 + low_confidence_stage5

gen pct_high_conf_claude_s1 = high_confidence_stage1 / total_tasks_stage1
gen pct_medium_conf_claude_s1 = medium_confidence_stage1 / total_tasks_stage1
gen pct_low_conf_claude_s1 = low_confidence_stage1 / total_tasks_stage1

gen pct_high_conf_claude_s2 = high_confidence_stage2 / total_tasks_stage2
gen pct_medium_conf_claude_s2 = medium_confidence_stage2 / total_tasks_stage2
gen pct_low_conf_claude_s2 = low_confidence_stage2 / total_tasks_stage2

gen pct_high_conf_claude_s3 = high_confidence_stage3 / total_tasks_stage3
gen pct_medium_conf_claude_s3 = medium_confidence_stage3 / total_tasks_stage3
gen pct_low_conf_claude_s3 = low_confidence_stage3 / total_tasks_stage3

gen pct_high_conf_claude_s4 = high_confidence_stage4 / total_tasks_stage4
gen pct_medium_conf_claude_s4 = medium_confidence_stage4 / total_tasks_stage4
gen pct_low_conf_claude_s4 = low_confidence_stage4 / total_tasks_stage4

gen pct_high_conf_claude_s5 = high_confidence_stage5 / total_tasks_stage5
gen pct_medium_conf_claude_s5 = medium_confidence_stage5 / total_tasks_stage5
gen pct_low_conf_claude_s5 = low_confidence_stage5 / total_tasks_stage5

drop weighted_exposure_claude_stage1 weighted_exposure_claude_stage2 weighted_exposure_claude_stage3 weighted_exposure_claude_stage4 weighted_exposure_claude_stage5

drop high_confidence_stage1 medium_confidence_stage1 low_confidence_stage1 high_confidence_stage2 medium_confidence_stage2 low_confidence_stage2 high_confidence_stage3 medium_confidence_stage3 low_confidence_stage3 high_confidence_stage4 medium_confidence_stage4 low_confidence_stage4 high_confidence_stage5 medium_confidence_stage5 low_confidence_stage5 

drop total_tasks_stage1 total_tasks_stage2 total_tasks_stage3 total_tasks_stage4 total_tasks_stage5 DataValue

save "$data_root/AI_exposure/v2/Working/onet_exposure_claude_v2.dta", replace

********************************************************************************************************************
******************************************** Merging Claude and OpenAI *********************************************
********************************************************************************************************************

use "$data_root/AI_exposure/v2/Working/onet_exposure_claude_v2.dta", clear
merge 1:1 onetsoccode using "$data_root/AI_exposure/v2/Working/onet_exposure_openai_v2.dta"
drop _merge
save "$data_root/AI_exposure/v2/Working/onet_exposure_openai_plus_claude_v2.dta", replace


********************************************************************************************************************
******************************************** Cleaning Llama and merging ********************************************
********************************************************************************************************************
use "$data_root/AI_exposure/Llama/Original/Llama_onetdata.dta", clear
drop GenAI_per preLLM_per LLM_per ChatGPTscore
rename preLLM_perw onet_llama_exposure_stage1
rename LLM_perw onet_llama_exposure_stage2
rename GenAI_perw onet_llama_exposure_stage3
rename ChatGPTscorew onet_chatgpt_exposure_stage2_og
drop relevence

save "$data_root/AI_exposure/Llama/Working/onet_exposure_llama_v2.dta", replace

merge 1:1 onetsoccode using "$data_root/AI_exposure/v2/Working/onet_exposure_openai_plus_claude_v2.dta"

drop _merge

rename onetsoccode onet_code

save "$data_root/AI_exposure/v2/Working/onet_exposure_openai_claude_llama_v2.dta", replace
