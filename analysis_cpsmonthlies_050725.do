* Name: analysis_cpsmonthlies_050725
* Author: Jacob Dominski
* Date Created: 


********************************************************************************************************************
*************************************************** Housekeeping ***************************************************
********************************************************************************************************************

************************************************ Set Global paths **************************************************

global data_root = "/Users/jdomins2/Desktop/CPS_Work/Data"
global export_root = "/Users/jdomins2/Desktop/CPS_Work/Output"



********************************************************************************************************************
***************************************************** Data Prep ****************************************************
********************************************************************************************************************

*********************************************  Merging CPS w/ Exposure *********************************************
use "$data_root/CPS/monthly_cps_march25", clear
***6,447,080 obs***

rename occ cps_code
drop if cps_code == 0
*** 3,197,314 obs ***

merge m:1 cps_code using "$data_root/Ai_Exposure/v2/Cleaned/occ_exposure_openAI_claude_llama_v3.dta"

preserve
keep if _merge == 1
gen byte tag = 0
bysort cps_code (month year): replace tag = 1 if _n == 1
keep if tag == 1
drop tag
list cps_code
restore

* 13 Unique CPS observations unmatched with AI exposure scores; These occupations have the CPS codes: 2006 2014, 2060, 2180, 2770, 2865, 4160, 4655, 4965, 5040, 7855, 9150, 9840. The first 12 correspond to occupations that end with ",all other," for which we don't expect to have exposure scores. The last is military for which we also don't have exposure scores.

drop if _merge == 1
*** 3,156,236 obs ***

drop if _merge == 2
*** 3,156,235 obs ***

drop _merge
save "$data_root/Cleaned/monthly_cps_w_exp_march25.dta", replace

******************************************* Cleaning at Individual Level *******************************************

use "$data_root/Cleaned/monthly_cps_w_exp_march25.dta", clear

keep if age>=18
***3,104,978 obs***

keep if age<65
***2,839,085 obs***

* Creating time
gen time = ym(year, month) 
format time %tm 
br time 
gen ntime=time-755 


gen Dunemp = .
replace Dunemp = 1 if empstat == 21
replace Dunemp = 0 if empstat == 10 | empstat == 12  // employed (at work or not at work)


* Rename Exposure
rename cps_openai_final_exp_s* openai*
rename cps_claude_final_exp_s* claude*
rename cps_llama_final_exp_s* llama*
rename cps_chatgpt_final_exp_s2 chat2

* Create Dummies
gen Dfem=0
replace Dfem=1 if sex==2

* Age
gen agegroup=1
replace agegroup=2 if age>30 & age<=50
replace agegroup=3 if age>50
tab agegroup, gen(Dage)

* Race
gen race_white = (race == 100)
gen race_black = (race == 200)
gen race_asian = (race == 651)
gen race_native = (race == 300) 
gen race_pacific = (race == 652) 
gen race_mixed_other = (race > 700) // All other multi-race categories


* Dummy for Post ChatGPT 
gen Post=0
replace Post=1 if time>=754

* Check
* GPT3.5 Nov 30,2022 (Dec 2022=754)
* GPT4 March 14, 2023 (756 1/23 757 758 3/23)
* GPTstore Jan. 2024 (759 760 761(June) 762 763 764 (Sep) 765 766 767 (Dec 2023))
* GPT4o May 13, 2024
br time ntime Post

* Create Continous Treatment (Exposure)
gen chatgptexp=openai1
replace chatgptexp=openai2 if ntime>=0
replace chatgptexp=openai3 if ntime>=4
replace chatgptexp=openai4 if ntime>=24

gen claudeexp=claude1
replace claudeexp=claude2 if ntime>=0
replace claudeexp=claude3 if ntime>=4
replace claudeexp=claude4 if ntime>=24

* Continuous Treatment Interaction Terms
foreach var in openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5{
	gen Postx`var'= Post * `var'
}

* Exposure Quartiles for OpenAI and Claude Exposure Scores
foreach var in openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5{
	xtile q_`var' = `var', nquantiles(4)
}

* Exposure Quartile Dummies
foreach var in openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5 {
	tab q_`var', gen(Dq`var')
}

* Renaming Quartile Dummies
foreach var in openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5{
	rename Dq`var'1 DQ1_`var'
	rename Dq`var'2 DQ2_`var'
	rename Dq`var'3 DQ3_`var'
	rename Dq`var'4 DQ4_`var'
}

* Creating Quartile-based Interaction Terms
foreach var in openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5 {
    forvalues num = 1/4 {
gen PostxDQ`num'_`var'= Post*DQ`num'_`var'
	}
}

* Checking Unemployment Statistics by Exposure Score
tab empstat
tabstat openai1 openai3, by(empstat) stats(n mean min max)


* Fixing Duration Unemployed & Creating a Log Version
replace durunemp=. if durunemp>=999
gen logdurunemp=log(durunemp+1)

* Fixing Work Hours Last Week & Creating a Log Version
tab ahrsworkt
replace ahrsworkt=. if ahrsworkt>=999
tab ahrswork1
replace ahrswork1=. if ahrswork1>=999
replace ahrswork2=. if ahrswork2>=999
replace uhrsworkt=. if uhrsworkt>=997
replace uhrswork1=. if uhrswork1>=997
replace uhrswork2=. if uhrswork2>=997

gen logahrswork1=log(ahrswork1+1)

* Creating a Full Time Dummy
gen Fulltime = .
replace Fulltime = 1 if empstat == 10 & wkstat == 11   // at work & full-time
replace Fulltime = 0 if empstat == 10 & wkstat != 99 & wkstat != 11   // at work & not full-time


* Creating Quartile and Time Interaction Terms
foreach var in openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5 {
    forvalues num = 1/4 {
gen ntimexDQ`num'_`var'= ntime*DQ`num'_`var'
	}
}

* Creating Continuous Time and Treatment Interaction Terms
foreach var in openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5{
	gen ntimex`var'= ntime * `var'
}


* Creating Unemployment Rate
gen demployed = 0
replace demployed = 1 if empstat == 10 | empstat == 12
gen dlabforce = 1
replace dlabforce = 0 if empstat == 31 | empstat == 32 | empstat == 33 | empstat == 34 | empstat == 35 | empstat ==36

preserve
collapse (sum) emp_count=demployed labor_force_count=dlabforce, by(year month cps_code)
save "$data_root/Working/monthly_emp_labforce_by_occ.dta", replace
restore

merge m:1 year month cps_code using "$data_root/Working/monthly_emp_labforce_by_occ.dta"
drop _merge
gen unemp_rate = 1 - (emp_count / labor_force_count) if labor_force_count > 0

* Checking Hours Worked
gen hrs_work_check = ahrswork1 + ahrswork2
count if hrs_work_check != ahrsworkt & !missing(ahrswork2)
drop hrs_work_check

* Creating Other Job Dummy
gen other_job = .
replace other_job = 0 if empstat == 10 | empstat == 12  // Employed: at work or not at work
replace other_job = 1 if (ahrswork2 > 0 & !missing(ahrswork2)) | (uhrswork2 > 0 & !missing(uhrswork2)) & (empstat == 10 | empstat == 12)

tab actsame
replace actsame = . if actsame > 98
gen new_wrk_acts = 0 if !missing(actsame)
replace new_wrk_acts = 1 if actsame == 2 

gen d_south = (statefip == 10 | statefip == 11 | statefip == 12 | statefip == 13 | statefip == 24 | statefip == 37 | statefip == 45 | statefip == 51 | statefip == 54 | statefip == 1 | statefip == 21 | statefip == 28 | statefip == 47 | statefip == 5 | statefip == 22 | statefip == 40 | statefip == 48)
gen d_midwest = (statefip == 17 | statefip == 18 | statefip == 26 | statefip == 39 | statefip == 55 | statefip == 19 | statefip == 20 | statefip == 27 | statefip == 29 | statefip == 31 | statefip == 38 | statefip == 46)
gen d_northeast = (statefip == 9 | statefip == 23 | statefip == 25 | statefip == 33 | statefip == 44 | statefip == 50 | statefip == 34 | statefip == 36 | statefip == 42)
gen d_west = (statefip == 4 | statefip == 8 | statefip == 16 | statefip == 30 | statefip == 32 | statefip == 35 | statefip == 49 | statefip == 56 | statefip == 2 | statefip == 6 | statefip == 15 | statefip == 41 | statefip == 53)


save "$data_root/Cleaned/cps_for_analysis_march25.dta", replace

******************************************* Cleaning at Occupation Level *******************************************
use "$data_root/Cleaned/cps_for_analysis_march25.dta", clear


*Creating Occupation, Month Level Outcome Variables
collapse (sum) demployed Dunemp dlabforce ///
         (mean) ahrswork1 ahrsworkt ntime openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5 chatgptexp claudeexp unemp_rate other_job new_wrk_acts ahrswork2 Fulltime, ///
         by(year month cps_code)

*Confirming everything is going well w/ how I calculate unemp. rates
gen unemp_rate_new = Dunemp / dlabforce
list if unemp_rate_new != unemp_rate
gen log_emp = log(demployed)
save "$data_root/Cleaned/cps_by_occ_march25.dta", replace


use "$data_root/Cleaned/cps_for_analysis_march25.dta", clear
*Creating Occupation-Month Level Controls
sort cps_code year month

* Generate total count of workers per occupation-month
bysort year month cps_code: gen total_workers = _N
sum total_workers, det

* Compute Proportion of Women 
bysort year month cps_code: egen num_fem = total(Dfem)
gen prop_fem = num_fem / total_workers
sum prop_fem, det

* Compute Education Shares
gen educ_q1 = (educ <= 72) // Less than high school
gen educ_q2 = (educ >= 73 & educ <= 110) // HS Degree & Some College
gen educ_q3 = (educ == 111) // College degree
gen educ_q4 = (educ >= 123)
sum educ_q1 educ_q2 educ_q3 educ_q4, det

bysort year month cps_code: egen num_educ_q1 = total(educ_q1)
bysort year month cps_code: egen num_educ_q2 = total(educ_q2)
bysort year month cps_code: egen num_educ_q3 = total(educ_q3)
bysort year month cps_code: egen num_educ_q4 = total(educ_q4)

gen prop_educ_q1 = num_educ_q1 / total_workers
gen prop_educ_q2 = num_educ_q2 / total_workers
gen prop_educ_q3 = num_educ_q3 / total_workers
gen prop_educ_q4 = num_educ_q4 / total_workers

sum prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4, det

* Compute Age Group Shares 
gen age_30less = (agegroup == 1)
gen age_30to50 = (agegroup == 2) 
gen age_50plus = (agegroup == 3) 
sum age_30less age_30to50 age_50plus, det

bysort year month cps_code: egen num_age_30less = total(age_30less)
bysort year month cps_code: egen num_age_30to50 = total(age_30to50)
bysort year month cps_code: egen num_age_50plus = total(age_50plus)

gen prop_age_30less = num_age_30less / total_workers
gen prop_age_30to50 = num_age_30to50 / total_workers
gen prop_age_50plus = num_age_50plus / total_workers
sum prop_age_30less prop_age_30to50 prop_age_50plus, det

* Compute Race Shares 
bysort year month cps_code: egen num_white = total(race_white)
bysort year month cps_code: egen num_black = total(race_black)
bysort year month cps_code: egen num_asian = total(race_asian)
bysort year month cps_code: egen num_native = total(race_native)
bysort year month cps_code: egen num_pacific = total(race_pacific)
bysort year month cps_code: egen num_mixed_other = total(race_mixed_other)

gen prop_white = num_white / total_workers
gen prop_black = num_black / total_workers
gen prop_asian = num_asian / total_workers
gen prop_native = num_native / total_workers
gen prop_pacific = num_pacific / total_workers
gen prop_mixed_other = num_mixed_other / total_workers
sum prop_white prop_black prop_asian prop_native prop_pacific prop_mixed_other, det

* Keep One Observation per Occupation-Month
collapse (mean) prop_fem prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 ///
         prop_age_30less prop_age_30to50 prop_age_50plus ///
         prop_white prop_black prop_asian prop_native prop_pacific prop_mixed_other, by(year month cps_code)
save "$data_root/Working/cps_controls.dta", replace

* Compute State Shares
use "$data_root/Cleaned/cps_for_analysis_march25.dta", clear

* Count the number of workers in each state within each occupation-month
bysort year month cps_code state: gen workers_in_state = _N

* Compute total workers in the occupation-month
bysort year month cps_code: gen total_occupation_workers = _N

* Compute the proportion of workers in each state
gen prop_state = workers_in_state / total_occupation_workers

* Aggregate to ensure unique state proportions per occupation-month
collapse (mean) prop_state, by(year month cps_code state)


* Reshape to create separate variables for each state
reshape wide prop_state, i(year month cps_code) j(statefip)


*Fixing missing values in state proportions
foreach i of numlist 1/56 {
    quietly capture confirm variable prop_state`i'
    if _rc == 0 {
        replace prop_state`i' = 0 if missing(prop_state`i')
    }
}



egen prop_northeast = rowtotal(prop_state9 prop_state23 prop_state25 prop_state33 prop_state44 prop_state50 prop_state34 prop_state36 prop_state42)
egen prop_midwest = rowtotal(prop_state17 prop_state18 prop_state26 prop_state39 prop_state55 prop_state19 prop_state20 prop_state27 prop_state29 prop_state31 prop_state38 prop_state46)
egen prop_south = rowtotal(prop_state10 prop_state11 prop_state12 prop_state13 prop_state24 prop_state37 prop_state45 prop_state51 prop_state54 prop_state1 prop_state21 prop_state28 prop_state47 prop_state5 prop_state22 prop_state40 prop_state48)
egen prop_west = rowtotal(prop_state4 prop_state8 prop_state16 prop_state30 prop_state32 prop_state35 prop_state49 prop_state56 prop_state2 prop_state6 prop_state15 prop_state41 prop_state53)

save "$data_root/Working/state_occ_emp_shares.dta", replace


merge 1:1 year month cps_code using "$data_root/Working/cps_controls.dta"
drop _merge
save "$data_root/Working/cps_controls.dta", replace

merge 1:1 year month cps_code using "$data_root/Cleaned/cps_by_occ_march25.dta"
drop _merge
rename Fulltime fulltime
save "$data_root/Cleaned/monthly_cps_by_occ_march25.dta", replace

use "$data_root/Cleaned/cps_for_analysis_march25.dta", clear
gen count = 1
collapse (sum) count, by(year month cps_code)
rename count n_obs
merge 1:1 year month cps_code using "$data_root/Cleaned/monthly_cps_by_occ_march25.dta"
save "$data_root/Cleaned/monthly_cps_by_occ_march25.dta", replace

********************************************************************************************************************
*************************************** Creating Averages for 3 Month Periods **************************************
********************************************************************************************************************

********************************************* P1 (Jan 2022 - March 2022) *******************************************

use "$data_root/Cleaned/monthly_cps_by_occ_march25.dta", clear

* Keep P1 (Jan - March 2022)
keep if (year == 2022 & (month == 1 | month == 2 | month == 3))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime, ///
by(cps_code)

gen log_emp = log(demployed)


* Rename variables to specify they are from P1
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime {
    rename `var' `var'_p1
}

* Save the P1 dataset
save "$data_root/Working/p1.dta", replace

********************************************* P2 (Jan 2023 - March 2023) *******************************************

use "$data_root/Cleaned/monthly_cps_by_occ_march25.dta", clear

* Keep P2 (Jan - March 2023)
keep if (year == 2023 & (month == 1 | month == 2 | month == 3))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5 ///
prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime, ///
by(cps_code)

gen log_emp = log(demployed)


* Rename variables to specify they are from P2
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime {
    rename `var' `var'_p2
}

* Save the P2 dataset
save "$data_root/Working/p2.dta", replace

********************************************* P3 (Jan 2024 - March 2024) *******************************************

use "$data_root/Cleaned/monthly_cps_by_occ_march25.dta", clear

* Keep P3 (Jan - March 2024)
keep if (year == 2024 & (month == 1 | month == 2 | month == 3))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime, ///
by(cps_code)

gen log_emp = log(demployed)


* Rename variables to specify they are from P3
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime {
    rename `var' `var'_p3
}

* Save the P3 dataset 
save "$data_root/Working/p3.dta", replace

********************************************* P4 (Jan 2025 - March 2025) *******************************************

use "$data_root/Cleaned/monthly_cps_by_occ_march25.dta", clear

* Keep P4 (Jan - March 2025)
keep if (year == 2025 & (month == 1 | month == 2 | month == 3))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime, ///
by(cps_code)

gen log_emp = log(demployed)


* Rename variables to specify they are from P4
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest  /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime {
    rename `var' `var'_p4
}

* Save the P4 dataset
save "$data_root/Working/p4.dta", replace

****************************************************** Merging ***************************************************
merge 1:1 cps_code using "$data_root/Working/p1.dta"
list cps_code if _merge == 1
*** Adhesive bonding machine operators and tenders are unmatched (code: 8850); no obs. in P1

drop _merge
merge 1:1 cps_code using "$data_root/Working/p2.dta"
drop _merge
merge 1:1 cps_code using "$data_root/Working/p3.dta"
list cps_code if _merge == 1
drop _merge
*** Animal control workers (code: 3900) and etchers and engravers (code: 8910) are unmatched; no obs in P3

save "$data_root/Working/P1_P4_ld_march2025.dta", replace

*********************************************** Computing Differences *********************************************
use "$data_root/Working/P1_P4_ld_march2025.dta", clear

* Exposure Differences
foreach model in openai claude {
	gen d_`model'_S2_S1 = `model'2 - `model'1
	gen d_`model'_S3_S1 = `model'3 - `model'1
	gen d_`model'_S4_S1 = `model'4 - `model'1
	gen d_`model'_S5_S1 = `model'5 - `model'1
	gen d_`model'_S3_S2 = `model'3 - `model'2
	gen d_`model'_S4_S2 = `model'4 - `model'2
	gen d_`model'_S5_S2 = `model'5 - `model'2
	gen d_`model'_S4_S3 = `model'4 - `model'3
	gen d_`model'_S5_S3 = `model'5 - `model'3
	gen d_`model'_S5_S4 = `model'5 - `model'4
}

* Creating P2 - P1 Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime {
	gen d_`var'_P2_P1 = `var'_p2 - `var'_p1
}

* Creating P3 - P1 Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime {
	gen d_`var'_P3_P1 = `var'_p3 - `var'_p1
}

* Creating P4 - P1 Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime {
	gen d_`var'_P4_P1 = `var'_p4 - `var'_p1
}

* Creating P3 - P2 Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime {
	gen d_`var'_P3_P2 = `var'_p3 - `var'_p2
}


* Creating P4 - P2 Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime {
	gen d_`var'_P4_P2 = `var'_p4 - `var'_p2
}

* Creating P4 - P3 Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime {
	gen d_`var'_P4_P3 = `var'_p4 - `var'_p3
}

foreach var in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	foreach stage in P2_P1 P3_P1 P4_P1 P3_P2 P4_P2 P4_P3 {
		replace `var'_`stage' = `var'_`stage' * 100
	}
}


save "$data_root/Cleaned/P1_P4_ld_march2025.dta", replace

* Checking key outcomes 
sum d_log_emp_P2_P1 d_log_emp_P3_P1 d_log_emp_P4_P1 d_log_emp_P3_P2 d_log_emp_P4_P2 d_log_emp_P4_P3, det
sum d_unemp_rate_P2_P1 d_unemp_rate_P3_P1 d_unemp_rate_P4_P1 d_unemp_rate_P3_P2 d_unemp_rate_P4_P2 d_unemp_rate_P4_P3, det

*********************************************** Creating Weights *********************************************
use "$data_root/Cleaned/cps_for_analysis_march25.dta", clear

* P1
keep if (year == 2022 & (month == 1 | month == 2 | month == 3))
gen count = 1
collapse (sum) count, by (cps_code month)
gen tag = 1

preserve
collapse (sum) tag, by(cps_code)
count if tag == 3
list cps_code tag if tag < 3
restore
*** Missing months for 7030, 8250, 8910, and 8940 


list cps_code month count if cps_code == 7030
insobs 1
replace cps_code = 7030 if missing(cps_code)
replace month = 2 if cps_code == 7030 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8250
insobs 1
replace cps_code = 8250 if missing(cps_code)
replace month = 2 if cps_code == 8250 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8910
insobs 1
replace cps_code = 8910 if missing(cps_code)
replace month = 3 if cps_code == 8910 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8940
insobs 1
replace cps_code = 8940 if missing(cps_code)
replace month = 1 if cps_code == 8940 & missing(count)
replace count = 0 if missing(count)
insobs 1
replace cps_code = 8940 if missing(cps_code)
replace month = 3 if cps_code == 8940 & missing(count)
replace count = 0 if missing(count)

drop tag
gen tag = 1
preserve
collapse (sum) tag, by(cps_code)
count if tag == 3
list cps_code tag if tag < 3
restore

collapse (mean) count, by (cps_code)
rename count freq_wt_P1
save "$data_root/Working/p1_wt.dta", replace


* P2
use "$data_root/Cleaned/cps_for_analysis_march25.dta", clear
keep if (year == 2023 & (month == 1 | month == 2 | month == 3))
gen count = 1
collapse (sum) count, by (cps_code month)
gen tag = 1

preserve
collapse (sum) tag, by(cps_code)
count if tag == 3
list cps_code tag if tag < 3
restore
*** Missing months for 425, 2631, 2740, 8025, and 8730

list cps_code month count if cps_code == 425
insobs 1
replace cps_code = 425 if missing(cps_code)
replace month = 2 if cps_code == 425 & missing(count)
replace count = 0 if missing(count)
insobs 1
replace cps_code = 425 if missing(cps_code)
replace month = 3 if cps_code == 425 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 2631
insobs 1
replace cps_code = 2631 if missing(cps_code)
replace month = 1 if cps_code == 2631 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 2740
insobs 1
replace cps_code = 2740 if missing(cps_code)
replace month = 2 if cps_code == 2740 & missing(count)
replace count = 0 if missing(count)
insobs 1
replace cps_code = 2740 if missing(cps_code)
replace month = 3 if cps_code == 2740 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8025
insobs 1
replace cps_code = 8025 if missing(cps_code)
replace month = 2 if cps_code == 8025 & missing(count)
replace count = 0 if missing(count)
insobs 1
replace cps_code = 8025 if missing(cps_code)
replace month = 3 if cps_code == 8025 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8730
insobs 1
replace cps_code = 8730 if missing(cps_code)
replace month = 3 if cps_code == 8730 & missing(count)
replace count = 0 if missing(count)

drop tag
gen tag = 1
preserve
collapse (sum) tag, by(cps_code)
count if tag == 3
list cps_code tag if tag < 3
restore

collapse (mean) count, by (cps_code)
rename count freq_wt_P2
save "$data_root/Working/p2_wt.dta", replace

* P3
use "$data_root/Cleaned/cps_for_analysis_march25.dta", clear
keep if (year == 2024 & (month == 1 | month == 2 | month == 3))
gen count = 1
collapse (sum) count, by (cps_code month)
gen tag = 1

preserve
collapse (sum) tag, by(cps_code)
count if tag == 3
list cps_code tag if tag < 3
restore
*** Missing months for 510, 1710, 1821, 3801, 5020, and 8930

list cps_code month count if cps_code == 510
insobs 1
replace cps_code = 510 if missing(cps_code)
replace month = 3 if cps_code == 510 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 1710
insobs 1
replace cps_code = 1710 if missing(cps_code)
replace month = 3 if cps_code == 1710 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 1821
insobs 1
replace cps_code = 1821 if missing(cps_code)
replace month = 3 if cps_code == 1821 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 3801
insobs 1
replace cps_code = 3801 if missing(cps_code)
replace month = 2 if cps_code == 3801 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 5020
insobs 1
replace cps_code = 5020 if missing(cps_code)
replace month = 1 if cps_code == 5020 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8930
insobs 1
replace cps_code = 8930 if missing(cps_code)
replace month = 3 if cps_code == 8930 & missing(count)
replace count = 0 if missing(count)

drop tag
gen tag = 1
preserve
collapse (sum) tag, by(cps_code)
count if tag == 3
list cps_code tag if tag < 3
restore

collapse (mean) count, by (cps_code)
rename count freq_wt_P3
save "$data_root/Working/p3_wt.dta", replace

* P4
use "$data_root/Cleaned/cps_for_analysis_march25.dta", clear
keep if (year == 2025 & (month == 1 | month == 2 | month == 3))
gen count = 1
collapse (sum) count, by (cps_code month)
gen tag = 1

preserve
collapse (sum) tag, by(cps_code)
count if tag == 3
list cps_code tag if tag < 3
restore
*** Missing months for 1710, 2740, 3120, 3900, 4461, 8025 and 8256

list cps_code month count if cps_code == 1710
insobs 1
replace cps_code = 1710 if missing(cps_code)
replace month = 3 if cps_code == 1710 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 2740
insobs 1
replace cps_code = 2740 if missing(cps_code)
replace month = 2 if cps_code == 2740 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 3120
insobs 1
replace cps_code = 3120 if missing(cps_code)
replace month = 2 if cps_code == 3120 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 3900
insobs 1
replace cps_code = 3900 if missing(cps_code)
replace month = 1 if cps_code == 3900 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 4461
insobs 1
replace cps_code = 4461 if missing(cps_code)
replace month = 1 if cps_code == 4461 & missing(count)
replace count = 0 if missing(count)
insobs 1
replace cps_code = 4461 if missing(cps_code)
replace month = 2 if cps_code == 4461 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8025
insobs 1
replace cps_code = 8025 if missing(cps_code)
replace month = 1 if cps_code == 8025 & missing(count)
replace count = 0 if missing(count)
insobs 1
replace cps_code = 8025 if missing(cps_code)
replace month = 2 if cps_code == 8025 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8256
insobs 1
replace cps_code = 8256 if missing(cps_code)
replace month = 1 if cps_code == 8256 & missing(count)
replace count = 0 if missing(count)

drop tag
gen tag = 1
preserve
collapse (sum) tag, by(cps_code)
count if tag == 3
list cps_code tag if tag < 3
restore

collapse (mean) count, by (cps_code)
rename count freq_wt_P4
save "$data_root/Working/p4_wt.dta", replace

* Merging
merge 1:1 cps_code using "$data_root/Working/p1_wt.dta"
list cps_code if _merge == 1
*** Adhesive bonding machine operators and tenders are unmatched (code: 8850); no obs. in P1

drop _merge
merge 1:1 cps_code using "$data_root/Working/p2_wt.dta"
drop _merge
merge 1:1 cps_code using "$data_root/Working/p3_wt.dta"
list cps_code if _merge == 1
drop _merge
*** Animal control workers (code: 3900) and etchers and engravers (code: 8910) are unmatched; no obs in P3

merge 1:1 cps_code using "$data_root/Cleaned/P1_P4_ld_march2025.dta"
drop _merge


* Merging W/ Routine Measures
merge 1:1 cps_code using "$data_root/Working/soc_AA_routine.dta"
list cps_code if _merge == 1
drop _merge

*** We are missing 15 unique CPS occupations (1021, 2755, 3401, 3402, 3515, 3725, 3946, 4840, 60, 6115, 705, 845, 9121, 9141, 9142); these occupations do not have work activity data. 

save "$data_root/Cleaned/P1_P4_ld_march2025.dta", replace


********************************************************************************************************************
*************************************** Creating Averages for 6 Month Periods **************************************
********************************************************************************************************************


********************************************* P1 (Oct 2021 - March 2022) *******************************************

use "$data_root/Cleaned/monthly_cps_by_occ_march25.dta", clear

* Keep P1 (Oct 2021 - March 2022)
keep if ((year == 2022 & (month == 1 | month == 2 | month == 3)) | (year == 2021 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime, ///
by(cps_code)

gen log_emp = log(demployed)


* Rename variables to specify they are from P1
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime {
    rename `var' `var'_p1
}

* Save the P1 dataset
save "$data_root/Working/p1_6M.dta", replace

********************************************* P2 (Oct 2022 - March 2023) *******************************************

use "$data_root/Cleaned/monthly_cps_by_occ_march25.dta", clear

* Keep P2 (Oct 2022 - March 2023)
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5 ///
prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime, ///
by(cps_code)

gen log_emp = log(demployed)


* Rename variables to specify they are from P2
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime {
    rename `var' `var'_p2
}

* Save the P2 dataset
save "$data_root/Working/p2_6M.dta", replace

********************************************* P3 (Oct 2023 - March 2024) *******************************************

use "$data_root/Cleaned/monthly_cps_by_occ_march25.dta", clear

* Keep P3 (Oct 2023 - March 2024)
keep if ((year == 2024 & (month == 1 | month == 2 | month == 3)) | (year == 2023 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime, ///
by(cps_code)

gen log_emp = log(demployed)


* Rename variables to specify they are from P3
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime {
    rename `var' `var'_p3
}

* Save the P3 dataset 
save "$data_root/Working/p3_6M.dta", replace

********************************************* P4 (Oct 2024 - March 2025) *******************************************

use "$data_root/Cleaned/monthly_cps_by_occ_march25.dta", clear

* Keep P4 (Oct 2024 - March 2025)
keep if ((year == 2025 & (month == 1 | month == 2 | month == 3)) | (year == 2024 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime, ///
by(cps_code)

gen log_emp = log(demployed)


* Rename variables to specify they are from P4
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest  /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime {
    rename `var' `var'_p4
}

* Save the P4 dataset
save "$data_root/Working/p4_6M.dta", replace

****************************************************** Merging ***************************************************
merge 1:1 cps_code using "$data_root/Working/p1_6M.dta"
list cps_code if _merge == 1
*** Adhesive bonding machine operators and tenders are unmatched (code: 8850); no obs. in P1

drop _merge
merge 1:1 cps_code using "$data_root/Working/p2_6M.dta"
drop _merge
merge 1:1 cps_code using "$data_root/Working/p3_6M.dta"
list cps_code if _merge == 1
drop _merge
*** Animal control workers (code: 3900) and etchers and engravers (code: 8910) are unmatched; no obs in P3

save "$data_root/Working/P1_P4_ld_march2025_6M.dta", replace

*********************************************** Computing Differences *********************************************
use "$data_root/Working/P1_P4_ld_march2025_6M.dta", clear

* Exposure Differences
foreach model in openai claude {
	gen d_`model'_S2_S1 = `model'2 - `model'1
	gen d_`model'_S3_S1 = `model'3 - `model'1
	gen d_`model'_S4_S1 = `model'4 - `model'1
	gen d_`model'_S5_S1 = `model'5 - `model'1
	gen d_`model'_S3_S2 = `model'3 - `model'2
	gen d_`model'_S4_S2 = `model'4 - `model'2
	gen d_`model'_S5_S2 = `model'5 - `model'2
	gen d_`model'_S4_S3 = `model'4 - `model'3
	gen d_`model'_S5_S3 = `model'5 - `model'3
	gen d_`model'_S5_S4 = `model'5 - `model'4
}

* Creating P2 - P1 Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime {
	gen d_`var'_P2_P1 = `var'_p2 - `var'_p1
}

* Creating P3 - P1 Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime {
	gen d_`var'_P3_P1 = `var'_p3 - `var'_p1
}

* Creating P4 - P1 Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime {
	gen d_`var'_P4_P1 = `var'_p4 - `var'_p1
}

* Creating P3 - P2 Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime {
	gen d_`var'_P3_P2 = `var'_p3 - `var'_p2
}


* Creating P4 - P2 Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime {
	gen d_`var'_P4_P2 = `var'_p4 - `var'_p2
}

* Creating P4 - P3 Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime {
	gen d_`var'_P4_P3 = `var'_p4 - `var'_p3
}

foreach var in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	foreach stage in P2_P1 P3_P1 P4_P1 P3_P2 P4_P2 P4_P3 {
		replace `var'_`stage' = `var'_`stage' * 100
	}
}


save "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", replace

* Checking key outcomes 
sum d_log_emp_P2_P1 d_log_emp_P3_P1 d_log_emp_P4_P1 d_log_emp_P3_P2 d_log_emp_P4_P2 d_log_emp_P4_P3, det
sum d_unemp_rate_P2_P1 d_unemp_rate_P3_P1 d_unemp_rate_P4_P1 d_unemp_rate_P3_P2 d_unemp_rate_P4_P2 d_unemp_rate_P4_P3, det

*********************************************** Creating Weights *********************************************
use "$data_root/Cleaned/cps_for_analysis_march25.dta", clear

* P1
keep if ((year == 2022 & (month == 1 | month == 2 | month == 3)) | (year == 2021 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (cps_code month)
gen tag = 1

preserve
collapse (sum) tag, by(cps_code)
count if tag == 6
list cps_code tag if tag < 6
restore
*** Missing months for 3120, 5010 7030, 8250, 8850 8910, and 8940 

list cps_code month count if cps_code == 3120
insobs 1
replace cps_code = 3120 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 5010
insobs 1
replace cps_code = 5010 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 7030
insobs 1
replace cps_code = 7030 if missing(cps_code)
replace month = 2 if cps_code == 7030 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8250
insobs 1
replace cps_code = 8250 if missing(cps_code)
replace month = 2 if cps_code == 8250 & missing(count)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8850
insobs 3
replace cps_code = 8850 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8910
insobs 3
replace cps_code = 8910 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8940
insobs 2
replace cps_code = 8940 if missing(cps_code)
replace count = 0 if missing(count)

drop tag
gen tag = 1
preserve
collapse (sum) tag, by(cps_code)
count if tag == 6
list cps_code tag if tag < 6
restore

collapse (mean) count, by (cps_code)
rename count freq_wt_P1
save "$data_root/Working/p1_6M_wt.dta", replace


* P2
use "$data_root/Cleaned/cps_for_analysis_march25.dta", clear
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (cps_code month)
gen tag = 1

preserve
collapse (sum) tag, by(cps_code)
count if tag == 6
list cps_code tag if tag < 6
restore
*** Missing months for 425, 510, 2631, 2740, 5910, 8025, 8256, 8335, 8730, 8910, and 9110

list cps_code month count if cps_code == 425
insobs 2
replace cps_code = 425 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 510
insobs 1
replace cps_code = 510 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 2631
insobs 1
replace cps_code = 2631 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 2740
insobs 2
replace cps_code = 2740 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 5910
insobs 1
replace cps_code = 5910 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8025
insobs 2
replace cps_code = 8025 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8256
insobs 1
replace cps_code = 8256 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8335
insobs 2
replace cps_code = 8335 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8730
insobs 1
replace cps_code = 8730 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8910
insobs 3
replace cps_code = 8910 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 9110
insobs 1
replace cps_code = 9110 if missing(cps_code)
replace count = 0 if missing(count)

drop tag
gen tag = 1
preserve
collapse (sum) tag, by(cps_code)
count if tag == 6
list cps_code tag if tag < 6
restore

collapse (mean) count, by (cps_code)
rename count freq_wt_P2
save "$data_root/Working/p2_6M_wt.dta", replace

* P3
use "$data_root/Cleaned/cps_for_analysis_march25.dta", clear
keep if ((year == 2024 & (month == 1 | month == 2 | month == 3)) | (year == 2023 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (cps_code month)
gen tag = 1

preserve
collapse (sum) tag, by(cps_code)
count if tag == 6
list cps_code tag if tag < 6
restore
*** Missing months for 510, 1710, 1821, 3801, 3900, 5020, 5910, 8250, 8910, and 8930

list cps_code month count if cps_code == 510
insobs 1
replace cps_code = 510 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 1710
insobs 1
replace cps_code = 1710 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 1821
insobs 1
replace cps_code = 1821 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 3801
insobs 1
replace cps_code = 3801 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 3900
insobs 4
replace cps_code = 3900 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 5020
insobs 2
replace cps_code = 5020 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 5910
insobs 1
replace cps_code = 5910 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8250
insobs 1
replace cps_code = 8250 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8910
insobs 5
replace cps_code = 8910 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8930
insobs 1
replace cps_code = 8930 if missing(cps_code)
replace count = 0 if missing(count)

drop tag
gen tag = 1
preserve
collapse (sum) tag, by(cps_code)
count if tag == 6
list cps_code tag if tag < 6
restore

collapse (mean) count, by (cps_code)
rename count freq_wt_P3
save "$data_root/Working/p3_6M_wt.dta", replace

* P4
use "$data_root/Cleaned/cps_for_analysis_march25.dta", clear
keep if ((year == 2025 & (month == 1 | month == 2 | month == 3)) | (year == 2024 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (cps_code month)
gen tag = 1

preserve
collapse (sum) tag, by(cps_code)
count if tag == 6
list cps_code tag if tag < 6
restore
*** Missing months for 1710, 2740, 3120, 3210, 3900, 4461, 7610, 7730, 8025, 8256, 8456, 8910

list cps_code month count if cps_code == 1710
insobs 1
replace cps_code = 1710 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 2740
insobs 1
replace cps_code = 2740 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 3120
insobs 1
replace cps_code = 3120 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 3210
insobs 1
replace cps_code = 3210 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 3900
insobs 2
replace cps_code = 3900 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 4461
insobs 2
replace cps_code = 4461 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 7610
insobs 1
replace cps_code = 7610 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 7730
insobs 1
replace cps_code = 7730 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8025
insobs 2
replace cps_code = 8025 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8256
insobs 1
replace cps_code = 8256 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8465
insobs 1
replace cps_code = 8465 if missing(cps_code)
replace count = 0 if missing(count)

list cps_code month count if cps_code == 8910
insobs 1
replace cps_code = 8910 if missing(cps_code)
replace count = 0 if missing(count)

drop tag
gen tag = 1
preserve
collapse (sum) tag, by(cps_code)
count if tag == 6
list cps_code tag if tag < 6
list cps_code tag if tag > 6
restore

collapse (mean) count, by (cps_code)
rename count freq_wt_P4
save "$data_root/Working/p4_6M_wt.dta", replace

* Merging
merge 1:1 cps_code using "$data_root/Working/p1_6M_wt.dta"
list cps_code if _merge == 1
drop _merge
merge 1:1 cps_code using "$data_root/Working/p2_6M_wt.dta"
drop _merge
merge 1:1 cps_code using "$data_root/Working/p3_6M_wt.dta"
drop _merge
merge 1:1 cps_code using "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta"
drop _merge


* Merging W/ Routine Measures
merge 1:1 cps_code using "$data_root/Working/soc_AA_routine.dta"
list cps_code if _merge == 1
drop _merge


*** We are missing 15 unique CPS occupations (1021, 2755, 3401, 3402, 3515, 3725, 3946, 4840, 60, 6115, 705, 845, 9121, 9141, 9142); these occupations do not have work activity data. 

* Creating Quartiles for Routine Task Indices
foreach var in NR_CA NR_CI RC RM NRMP {
	xtile q_`var' = `var', nquantiles(4)
	tab q_`var', gen(Dq`var')
	rename Dq`var'1 DQ1_`var'
	rename Dq`var'2 DQ2_`var'
	rename Dq`var'3 DQ3_`var'
	rename Dq`var'4 DQ4_`var'
}

* Creating Routine Task Dummy Interaction Terms
foreach var in NR_CA NR_CI RC RM NRMP {
	foreach model in openai claude {
		foreach stage in S3_S1 S2_S1 {
			gen DQ4`var'_x_`model'_`stage' = DQ4_`var' * d_`model'_`stage'
		}
	}
}

* Creating Index Interaction Terms
gen NR_CA_x_OA_3_1 = NR_CA * d_openai_S3_S1
gen NR_CA_x_C_3_1 = NR_CA * d_claude_S3_S1
gen NR_CI_x_OA_3_1 = NR_CI * d_openai_S3_S1
gen NR_CI_x_C_3_1 = NR_CI * d_claude_S3_S1
gen RC_x_OA_3_1 = RC * d_openai_S3_S1
gen RC_x_C_3_1 = RC * d_claude_S3_S1
gen RM_x_OA_3_1 = RM * d_openai_S3_S1
gen RM_x_C_3_1 = RM * d_claude_S3_S1
gen NRMP_x_OA_3_1 = NRMP * d_openai_S3_S1
gen NRMP_x_C_3_1 = NRMP * d_claude_S3_S1

gen NR_CA_x_OA_2_1 = NR_CA * d_openai_S2_S1
gen NR_CA_x_C_2_1 = NR_CA * d_claude_S2_S1
gen NR_CI_x_OA_2_1 = NR_CI * d_openai_S2_S1
gen NR_CI_x_C_2_1 = NR_CI * d_claude_S2_S1
gen RC_x_OA_2_1 = RC * d_openai_S2_S1
gen RC_x_C_2_1 = RC * d_claude_S2_S1
gen RM_x_OA_2_1 = RM * d_openai_S2_S1
gen RM_x_C_2_1 = RM * d_claude_S2_S1
gen NRMP_x_OA_2_1 = NRMP * d_openai_S2_S1
gen NRMP_x_C_2_1 = NRMP * d_claude_S2_S1

save "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", replace



********************************************************************************************************************
******************************************* Estimations (3-Month Period) *******************************************
********************************************************************************************************************

********************************************** P2 - P1 = β (S2 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P2_P1 d_unemp_rate_P2_P1 d_ahrswork1_P2_P1 d_ahrswork2_P2_P1 d_ahrsworkt_P2_P1 d_other_job_P2_P1 d_fulltime_P2_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P2_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P2-P1_S2-S1_A.txt", keep(d_openai_S2_S1) replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P2-P1_S2-S1_A.txt", keep(d_openai_S2_S1) append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P2-P1_S2-S1_A.txt", keep(d_claude_S2_S1) append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P2_P1 d_unemp_rate_P2_P1 d_ahrswork1_P2_P1 d_ahrswork2_P2_P1 d_ahrsworkt_P2_P1 d_other_job_P2_P1 d_fulltime_P2_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P2_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P2-P1_S2-S1_B.txt", keep(d_openai_S2_S1) replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P2-P1_S2-S1_B.txt", keep(d_openai_S2_S1) append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P2-P1_S2-S1_B.txt", keep(d_claude_S2_S1) append
}

********************************************** P3 - P2 = β (S3 - S2) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S3-S2_A.txt", keep(d_openai_S3_S2) replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S3-S2_A.txt", keep(d_openai_S3_S2) append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S3-S2_A.txt", keep(d_claude_S3_S2) append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S3-S2_B.txt", keep(d_openai_S3_S2) replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S3-S2_B.txt", keep(d_openai_S3_S2) append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S3-S2_B.txt", keep(d_claude_S3_S2) append
}


********************************************** P4 - P3 = β (S4 - S3) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S4_S3 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4-S3_A.txt", keep(d_openai_S4_S3) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4-S3_A.txt", keep(d_openai_S4_S3) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S3 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4-S3_A.txt", keep(d_claude_S4_S3) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S4_S3 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4-S3_B.txt", keep(d_openai_S4_S3) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4-S3_B.txt", keep(d_openai_S4_S3) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S3 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4-S3_B.txt", keep(d_claude_S4_S3) nocons append
}

********************************************** P3 - P1 = β (S3 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P3_P1 d_unemp_rate_P3_P1 d_ahrswork1_P3_P1 d_ahrswork2_P3_P1 d_ahrsworkt_P3_P1 d_other_job_P3_P1 d_fulltime_P3_P1
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S1_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S1_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S1_A.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P3_P1 d_unemp_rate_P3_P1 d_ahrswork1_P3_P1 d_ahrswork2_P3_P1 d_ahrsworkt_P3_P1 d_other_job_P3_P1 d_fulltime_P3_P1
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S1_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S1_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S1_B.txt", keep(d_claude_S3_S1) nocons append
}

********************************************** P3 - P1 = β (S3 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P3_P1 d_unemp_rate_P3_P1 d_ahrswork1_P3_P1 d_ahrswork2_P3_P1 d_ahrsworkt_P3_P1 d_other_job_P3_P1 d_fulltime_P3_P1
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S1_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S1_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S1_A.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P3_P1 d_unemp_rate_P3_P1 d_ahrswork1_P3_P1 d_ahrswork2_P3_P1 d_ahrsworkt_P3_P1 d_other_job_P3_P1 d_fulltime_P3_P1
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S1_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S1_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S1_B.txt", keep(d_claude_S3_S1) nocons append
}

********************************************** P4 - P1 = β (S4 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S4_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S1_A.txt", keep(d_openai_S4_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S1_A.txt", keep(d_openai_S4_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S1_A.txt", keep(d_claude_S4_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S4_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S1_B.txt", keep(d_openai_S4_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S1_B.txt", keep(d_openai_S4_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S1_B.txt", keep(d_claude_S4_S1) nocons append
}

********************************************** P4 - P1 = β (S4 - S2) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S4_S2 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S2_A.txt", keep(d_openai_S4_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S2_A.txt", keep(d_openai_S4_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S2 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S2_A.txt", keep(d_claude_S4_S2) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S4_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S2_B.txt", keep(d_openai_S4_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S2_B.txt", keep(d_openai_S4_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S2_B.txt", keep(d_claude_S4_S2) nocons append
}

********************************************** P4 - P2 = β (S4 - S2) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S4_S2 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S2_A.txt", keep(d_openai_S4_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S2_A.txt", keep(d_openai_S4_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S2 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S2_A.txt", keep(d_claude_S4_S2) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S4_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S2_B.txt", keep(d_openai_S4_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S2_B.txt", keep(d_openai_S4_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S2_B.txt", keep(d_claude_S4_S2) nocons append
}

********************************************** P4 - P2 = β (S4 - S3) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S4_S3 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S3_A.txt", keep(d_openai_S4_S3) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S3_A.txt", keep(d_openai_S4_S3) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S3 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S3_A.txt", keep(d_claude_S4_S3) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S3_B.txt", keep(d_openai_S4_S3) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S3_B.txt", keep(d_openai_S4_S3) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S3 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S3_B.txt", keep(d_claude_S4_S3) nocons append
}


********************************************** P3 - P2 = β (S3 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S3-S1_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S3-S1_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S3-S1_A.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S3-S1_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S3-S1_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S3-S1_B.txt", keep(d_claude_S3_S1) nocons append
}

********************************************** P3 - P2 = β (S2 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S2-S1_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S2-S1_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S2-S1_A.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S2-S1_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S2-S1_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P3-P2_S2-S1_B.txt", keep(d_claude_S2_S1) nocons append
}


********************************************** P3 - P1 = β (S2 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P3_P1 d_unemp_rate_P3_P1 d_ahrswork1_P3_P1 d_ahrswork2_P3_P1 d_ahrsworkt_P3_P1 d_other_job_P3_P1 d_fulltime_P3_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S2-S1_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S2-S1_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S2-S1_A.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P3_P1 d_unemp_rate_P3_P1 d_ahrswork1_P3_P1 d_ahrswork2_P3_P1 d_ahrsworkt_P3_P1 d_other_job_P3_P1 d_fulltime_P3_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S2-S1_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S2-S1_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S2-S1_B.txt", keep(d_claude_S2_S1) nocons append
}

********************************************** P4 - P3 = β (S3 - S2) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S3-S2_A.txt", keep(d_openai_S3_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S3-S2_A.txt", keep(d_openai_S3_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S3-S2_A.txt", keep(d_claude_S3_S2) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S3-S2_B.txt", keep(d_openai_S3_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S3-S2_B.txt", keep(d_openai_S3_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S3-S2_B.txt", keep(d_claude_S3_S2) nocons append
}

********************************************** P4 - P3 = β (S2 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S2_S1_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S2_S1_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S2_S1_A.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S2_S1_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S2_S1_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S2_S1_B.txt", keep(d_claude_S2_S1) nocons append
}

********************************************** P4 - P2 = β (S2 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S2-S1_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S2-S1_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S2-S1_A.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S2-S1_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S2-S1_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S2-S1_B.txt", keep(d_claude_S2_S1) nocons append
}

********************************************** P4 - P2 = β (S3 - S2) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S3-S2_A.txt", keep(d_openai_S3_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S3-S2_A.txt", keep(d_openai_S3_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S3-S2_A.txt", keep(d_claude_S3_S2) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S3-S2_B.txt", keep(d_openai_S3_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S3-S2_B.txt", keep(d_openai_S3_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S3-S2_B.txt", keep(d_claude_S3_S2) nocons append
}

********************************************** P4 - P1 = β (S2 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S2-S1_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S2-S1_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S2-S1_A.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S2-S1_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S2-S1_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S2-S1_B.txt", keep(d_claude_S2_S1) nocons append
}

********************************************** P4 - P1 = β (S3 - S2) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S3-S2_A.txt", keep(d_openai_S3_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S3-S2_A.txt", keep(d_openai_S3_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S3-S2_A.txt", keep(d_claude_S3_S2) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S3-S2_B.txt", keep(d_openai_S3_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S3-S2_B.txt", keep(d_openai_S3_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S3-S2_B.txt", keep(d_claude_S3_S2) nocons append
}

********************************************** P4 - P3 = β (S3 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S3_S1_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S3_S1_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S3_S1_A.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S3_S1_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S3_S1_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S3_S1_B.txt", keep(d_claude_S3_S1) nocons append
}


********************************************** P4 - P2 = β (S3 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S3-S1_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S3-S1_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S3-S1_A.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S3-S1_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S3-S1_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S3-S1_B.txt", keep(d_claude_S3_S1) nocons append
}


********************************************** P4 - P1 = β (S3 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S3-S1_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S3-S1_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S3-S1_A.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S3-S1_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S3-S1_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S3-S1_B.txt", keep(d_claude_S3_S1) nocons append
}

********************************************** P3 - P1 = β (S3 - S2) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P3_P1 d_unemp_rate_P3_P1 d_ahrswork1_P3_P1 d_ahrswork2_P3_P1 d_ahrsworkt_P3_P1 d_other_job_P3_P1 d_fulltime_P3_P1
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S2_A.txt", keep(d_openai_S3_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S2_A.txt", keep(d_openai_S3_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S2_A.txt", keep(d_claude_S3_S2) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P3_P1 d_unemp_rate_P3_P1 d_ahrswork1_P3_P1 d_ahrswork2_P3_P1 d_ahrsworkt_P3_P1 d_other_job_P3_P1 d_fulltime_P3_P1
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S2_B.txt", keep(d_openai_S3_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S2_B.txt", keep(d_openai_S3_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P3-P1_S3-S2_B.txt", keep(d_claude_S3_S2) nocons append
}


********************************************** P4 - P1 = β (S4 - S3) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S4_S3 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S3_A.txt", keep(d_openai_S4_S3) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S3_A.txt", keep(d_openai_S4_S3) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S3 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S3_A.txt", keep(d_claude_S4_S3) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S4_S3 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S3_B.txt", keep(d_openai_S4_S3) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S3_B.txt", keep(d_openai_S4_S3) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S3 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P1_S4-S3_B.txt", keep(d_claude_S4_S3) nocons append
}


********************************************** P4 - P2 = β (S4 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S4_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S1_A.txt", keep(d_openai_S4_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S1_A.txt", keep(d_openai_S4_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S1_A.txt", keep(d_claude_S4_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S4_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S1_B.txt", keep(d_openai_S4_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S1_B.txt", keep(d_openai_S4_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P2_S4-S1_B.txt", keep(d_claude_S4_S1) nocons append
}

********************************************** P4 - P3 = β (S4 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S4_S1 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4_S1_A.txt", keep(d_openai_S4_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4_S1_A.txt", keep(d_openai_S4_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S1 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4_S1_A.txt", keep(d_claude_S4_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S4_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4_S1_B.txt", keep(d_openai_S4_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4_S1_B.txt", keep(d_openai_S4_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4_S1_B.txt", keep(d_claude_S4_S1) nocons append
}

********************************************** P4 - P3 = β (S4 - S2) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S4_S2 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4_S2_A.txt", keep(d_openai_S4_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4_S2_A.txt", keep(d_openai_S4_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S2 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4_S2_A.txt", keep(d_claude_S4_S2) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S4_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4_S2_B.txt", keep(d_openai_S4_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4_S2_B.txt", keep(d_openai_S4_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_08_25/P4-P3_S4_S2_B.txt", keep(d_claude_S4_S2) nocons append
}

********************************************************************************************************************
******************************************* Estimations (6-Month Period) *******************************************
********************************************************************************************************************

********************************************** P3 - P2 = β (S2 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/05_09_25/P3-P2_S2-S1_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P3-P2_S2-S1_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P3-P2_S2-S1_A.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/05_09_25/P3-P2_S2-S1_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P3-P2_S2-S1_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P3-P2_S2-S1_B.txt", keep(d_claude_S2_S1) nocons append
}


********************************************** P3 - P1 = β (S2 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P1 d_unemp_rate_P3_P1 d_ahrswork1_P3_P1 d_ahrswork2_P3_P1 d_ahrsworkt_P3_P1 d_other_job_P3_P1 d_fulltime_P3_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P1" {
        outreg2 using "$export_root/May/txt/05_09_25/P3-P1_S2-S1_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P3-P1_S2-S1_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P3-P1_S2-S1_A.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P1 d_unemp_rate_P3_P1 d_ahrswork1_P3_P1 d_ahrswork2_P3_P1 d_ahrsworkt_P3_P1 d_other_job_P3_P1 d_fulltime_P3_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P1" {
        outreg2 using "$export_root/May/txt/05_09_25/P3-P1_S2-S1_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P3-P1_S2-S1_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P3-P1_S2-S1_B.txt", keep(d_claude_S2_S1) nocons append
}

********************************************** P4 - P3 = β (S3 - S2) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S3-S2_A.txt", keep(d_openai_S3_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S3-S2_A.txt", keep(d_openai_S3_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S3-S2_A.txt", keep(d_claude_S3_S2) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S3-S2_B.txt", keep(d_openai_S3_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S3-S2_B.txt", keep(d_openai_S3_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S3-S2_B.txt", keep(d_claude_S3_S2) nocons append
}

********************************************** P4 - P3 = β (S2 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S2_S1_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S2_S1_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S2_S1_A.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S2_S1_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S2_S1_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S2_S1_B.txt", keep(d_claude_S2_S1) nocons append
}

********************************************** P4 - P2 = β (S2 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S2-S1_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S2-S1_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S2-S1_A.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S2-S1_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S2-S1_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S2-S1_B.txt", keep(d_claude_S2_S1) nocons append
}

********************************************** P4 - P2 = β (S3 - S2) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S3-S2_A.txt", keep(d_openai_S3_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S3-S2_A.txt", keep(d_openai_S3_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S3-S2_A.txt", keep(d_claude_S3_S2) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S3-S2_B.txt", keep(d_openai_S3_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S3-S2_B.txt", keep(d_openai_S3_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S3-S2_B.txt", keep(d_claude_S3_S2) nocons append
}

********************************************** P4 - P1 = β (S2 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S2-S1_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S2-S1_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S2-S1_A.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S2-S1_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S2-S1_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S2-S1_B.txt", keep(d_claude_S2_S1) nocons append
}

********************************************** P4 - P1 = β (S3 - S2) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S3-S2_A.txt", keep(d_openai_S3_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S3-S2_A.txt", keep(d_openai_S3_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S3-S2_A.txt", keep(d_claude_S3_S2) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S3-S2_B.txt", keep(d_openai_S3_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S3-S2_B.txt", keep(d_openai_S3_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S2 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S3-S2_B.txt", keep(d_claude_S3_S2) nocons append
}

********************************************** P4 - P3 = β (S3 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S3_S1_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S3_S1_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S3_S1_A.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S3_S1_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S3_S1_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P3_S3_S1_B.txt", keep(d_claude_S3_S1) nocons append
}


********************************************** P4 - P2 = β (S3 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S3-S1_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S3-S1_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S3-S1_A.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S3-S1_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S3-S1_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P2_S3-S1_B.txt", keep(d_claude_S3_S1) nocons append
}


********************************************** P4 - P1 = β (S3 - S1) ***********************************************

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S3-S1_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S3-S1_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S3-S1_A.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P1 d_unemp_rate_P4_P1 d_ahrswork1_P4_P1 d_ahrswork2_P4_P1 d_ahrsworkt_P4_P1 d_other_job_P4_P1 d_fulltime_P4_P1
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P1" {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S3-S1_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S3-S1_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_09_25/P4-P1_S3-S1_B.txt", keep(d_claude_S3_S1) nocons append
}

********************************************************************************************************************
*******************************************Adding Task Indicex Interactions ****************************************
********************************************************************************************************************

********************************************** P4 - P2 = β (S3 - S1) ***********************************************

* NR_CA
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S3-S1_A.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S3-S1_A.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CA_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S3-S1_A.txt", keep(d_claude_S3_S1 NR_CA NR_CA_x_C_3_1) nocons append
}

* NR_CI
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S3-S1_B.txt", keep(d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S3-S1_B.txt", keep(d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CI NR_CI_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S3-S1_B.txt", keep(d_claude_S3_S1 NR_CI NR_CI_x_C_3_1) nocons append
}

* RC
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 RC RC_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S3-S1_C.txt", keep(d_openai_S3_S1 RC RC_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S3-S1_C.txt", keep(d_openai_S3_S1 RC RC_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 RC RC_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S3-S1_C.txt", keep(d_claude_S3_S1 RC RC_x_C_3_1) nocons append
}

* RM
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 RM RM_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S3-S1_D.txt", keep(d_openai_S3_S1 RM RM_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S3-S1_D.txt", keep(d_openai_S3_S1 RM RM_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 RM RM_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S3-S1_D.txt", keep(d_claude_S3_S1 RM RM_x_C_3_1) nocons append
}

* NRMP
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NRMP NRMP_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S3-S1_E.txt", keep(d_openai_S3_S1 NRMP NRMP_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S3-S1_E.txt", keep(d_openai_S3_S1 NRMP NRMP_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NRMP NRMP_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S3-S1_E.txt", keep(d_claude_S3_S1 NRMP NRMP_x_C_3_1) nocons append
}

********************************************** P3 - P2 = β (S2 - S1) ***********************************************

* NR_CA
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CA_x_OA_2_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P2_S2-S1_A.txt", keep(d_openai_S2_S1 NR_CA NR_CA_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P2_S2-S1_A.txt", keep(d_openai_S2_S1 NR_CA NR_CA_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CA_x_C_2_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P3-P2_S2-S1_A.txt", keep(d_claude_S2_S1 NR_CA NR_CA_x_C_2_1) nocons append
}

* NR_CI
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CI NR_CI_x_OA_2_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P2_S2-S1_B.txt", keep(d_openai_S2_S1 NR_CI NR_CI_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P2_S2-S1_B.txt", keep(d_openai_S2_S1 NR_CI NR_CI_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CI NR_CI_x_C_2_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P3-P2_S2-S1_B.txt", keep(d_claude_S2_S1 NR_CI NR_CI_x_C_2_1) nocons append
}

* RC
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 RC RC_x_OA_2_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P2_S2-S1_C.txt", keep(d_openai_S2_S1 RC RC_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P2_S2-S1_C.txt", keep(d_openai_S2_S1 RC RC_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 RC RC_x_C_2_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P3-P2_S2-S1_C.txt", keep(d_claude_S2_S1 RC RC_x_C_2_1) nocons append
}

* RM
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 RM RM_x_OA_2_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P2_S2-S1_D.txt", keep(d_openai_S2_S1 RM RM_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P2_S2-S1_D.txt", keep(d_openai_S2_S1 RM RM_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 RM RM_x_C_2_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P3-P2_S2-S1_D.txt", keep(d_claude_S2_S1 RM RM_x_C_2_1) nocons append
}

* NRMP
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NRMP NRMP_x_OA_2_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P2_S2-S1_E.txt", keep(d_openai_S2_S1 NRMP NRMP_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P2_S2-S1_E.txt", keep(d_openai_S2_S1 NRMP NRMP_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NRMP NRMP_x_C_2_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P3-P2_S2-S1_E.txt", keep(d_claude_S2_S1 NRMP NRMP_x_C_2_1) nocons append
}

********************************************** P2 - P1 = β (S2 - S1) ***********************************************

* NR_CA
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P2_P1 d_unemp_rate_P2_P1 d_ahrswork1_P2_P1 d_ahrswork2_P2_P1 d_ahrsworkt_P2_P1 d_other_job_P2_P1 d_fulltime_P2_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CA_x_OA_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P2_P1" {
        outreg2 using "$export_root/May/txt/05_12_25/P2-P1_S2-S1_A.txt", keep(d_openai_S2_S1 NR_CA NR_CA_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P2-P1_S2-S1_A.txt", keep(d_openai_S2_S1 NR_CA NR_CA_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CA_x_C_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P2-P1_S2-S1_A.txt", keep(d_claude_S2_S1 NR_CA NR_CA_x_C_2_1) nocons append
}

* NR_CI
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P2_P1 d_unemp_rate_P2_P1 d_ahrswork1_P2_P1 d_ahrswork2_P2_P1 d_ahrsworkt_P2_P1 d_other_job_P2_P1 d_fulltime_P2_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CI NR_CI_x_OA_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P2_P1" {
        outreg2 using "$export_root/May/txt/05_12_25/P2-P1_S2-S1_B.txt", keep(d_openai_S2_S1 NR_CI NR_CI_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P2-P1_S2-S1_B.txt", keep(d_openai_S2_S1 NR_CI NR_CI_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CI NR_CI_x_C_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P2-P1_S2-S1_B.txt", keep(d_claude_S2_S1 NR_CI NR_CI_x_C_2_1) nocons append
}

* RC
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P2_P1 d_unemp_rate_P2_P1 d_ahrswork1_P2_P1 d_ahrswork2_P2_P1 d_ahrsworkt_P2_P1 d_other_job_P2_P1 d_fulltime_P2_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 RC RC_x_OA_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P2_P1" {
        outreg2 using "$export_root/May/txt/05_12_25/P2-P1_S2-S1_C.txt", keep(d_openai_S2_S1 RC RC_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P2-P1_S2-S1_C.txt", keep(d_openai_S2_S1 RC RC_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 RC RC_x_C_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P2-P1_S2-S1_C.txt", keep(d_claude_S2_S1 RC RC_x_C_2_1) nocons append
}

* RM
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P2_P1 d_unemp_rate_P2_P1 d_ahrswork1_P2_P1 d_ahrswork2_P2_P1 d_ahrsworkt_P2_P1 d_other_job_P2_P1 d_fulltime_P2_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 RM RM_x_OA_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P2_P1" {
        outreg2 using "$export_root/May/txt/05_12_25/P2-P1_S2-S1_D.txt", keep(d_openai_S2_S1 RM RM_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P2-P1_S2-S1_D.txt", keep(d_openai_S2_S1 RM RM_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 RM RM_x_C_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P2-P1_S2-S1_D.txt", keep(d_claude_S2_S1 RM RM_x_C_2_1) nocons append
}

* NRMP
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P2_P1 d_unemp_rate_P2_P1 d_ahrswork1_P2_P1 d_ahrswork2_P2_P1 d_ahrsworkt_P2_P1 d_other_job_P2_P1 d_fulltime_P2_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NRMP NRMP_x_OA_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P2_P1" {
        outreg2 using "$export_root/May/txt/05_12_25/P2-P1_S2-S1_E.txt", keep(d_openai_S2_S1 NRMP NRMP_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P2-P1_S2-S1_E.txt", keep(d_openai_S2_S1 NRMP NRMP_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NRMP NRMP_x_C_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P2-P1_S2-S1_E.txt", keep(d_claude_S2_S1 NRMP NRMP_x_C_2_1) nocons append
}


********************************************** P3 - P1 = β (S2 - S1) ***********************************************

* NR_CA
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P1 d_unemp_rate_P3_P1 d_ahrswork1_P3_P1 d_ahrswork2_P3_P1 d_ahrsworkt_P3_P1 d_other_job_P3_P1 d_fulltime_P3_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CA_x_OA_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P1" {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P1_S2-S1_A.txt", keep(d_openai_S2_S1 NR_CA NR_CA_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P1_S2-S1_A.txt", keep(d_openai_S2_S1 NR_CA NR_CA_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CA_x_C_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P3-P1_S2-S1_A.txt", keep(d_claude_S2_S1 NR_CA NR_CA_x_C_2_1) nocons append
}

* NR_CI
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P1 d_unemp_rate_P3_P1 d_ahrswork1_P3_P1 d_ahrswork2_P3_P1 d_ahrsworkt_P3_P1 d_other_job_P3_P1 d_fulltime_P3_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CI NR_CI_x_OA_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P1" {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P1_S2-S1_B.txt", keep(d_openai_S2_S1 NR_CI NR_CI_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P1_S2-S1_B.txt", keep(d_openai_S2_S1 NR_CI NR_CI_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CI NR_CI_x_C_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P3-P1_S2-S1_B.txt", keep(d_claude_S2_S1 NR_CI NR_CI_x_C_2_1) nocons append
}

* RC
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P1 d_unemp_rate_P3_P1 d_ahrswork1_P3_P1 d_ahrswork2_P3_P1 d_ahrsworkt_P3_P1 d_other_job_P3_P1 d_fulltime_P3_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 RC RC_x_OA_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P1" {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P1_S2-S1_C.txt", keep(d_openai_S2_S1 RC RC_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P1_S2-S1_C.txt", keep(d_openai_S2_S1 RC RC_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 RC RC_x_C_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P3-P1_S2-S1_C.txt", keep(d_claude_S2_S1 RC RC_x_C_2_1) nocons append
}

* RM
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P1 d_unemp_rate_P3_P1 d_ahrswork1_P3_P1 d_ahrswork2_P3_P1 d_ahrsworkt_P3_P1 d_other_job_P3_P1 d_fulltime_P3_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 RM RM_x_OA_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P1" {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P1_S2-S1_D.txt", keep(d_openai_S2_S1 RM RM_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P1_S2-S1_D.txt", keep(d_openai_S2_S1 RM RM_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 RM RM_x_C_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P3-P1_S2-S1_D.txt", keep(d_claude_S2_S1 RM RM_x_C_2_1) nocons append
}

* NRMP
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P1 d_unemp_rate_P3_P1 d_ahrswork1_P3_P1 d_ahrswork2_P3_P1 d_ahrsworkt_P3_P1 d_other_job_P3_P1 d_fulltime_P3_P1
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NRMP NRMP_x_OA_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P1" {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P1_S2-S1_E.txt", keep(d_openai_S2_S1 NRMP NRMP_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P3-P1_S2-S1_E.txt", keep(d_openai_S2_S1 NRMP NRMP_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NRMP NRMP_x_C_2_1 prop_age_30to50_p1 prop_age_50plus_p1 prop_black_p1 ///
        prop_asian_p1 prop_native_p1 prop_mixed_other_p1 prop_pacific_p1 ///
        prop_educ_q1_p1 prop_educ_q2_p1 prop_educ_q3_p1 prop_midwest_p1 ///
        prop_northeast_p1 prop_west_p1 prop_fem_p1 [aweight = freq_wt_P1], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P3-P1_S2-S1_E.txt", keep(d_claude_S2_S1 NRMP NRMP_x_C_2_1) nocons append
}

********************************************** P4 - P2 = β (S2 - S1) ***********************************************

* NR_CA
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CA_x_OA_2_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S2-S1_A.txt", keep(d_openai_S2_S1 NR_CA NR_CA_x_OA_2_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S2-S1_A.txt", keep(d_openai_S2_S1 NR_CA NR_CA_x_OA_2_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CA_x_C_2_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_12_25/P4-P2_S2-S1_A.txt", keep(d_claude_S2_S1 NR_CA NR_CA_x_C_2_1) nocons append
}


********************************************************************************************************************
****************************************** Analysis for Presentation (5/12) ****************************************
********************************************************************************************************************

**************************************** P4 - P2 = β (S2 - S1) - All occs. *****************************************

* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1  [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_A.txt", keep(d_claude_S2_S1) nocons append
}



* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_B.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_C.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_C.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_C.txt", keep(d_claude_S2_S1) nocons append
}

****************************** P4 - P2 = β (S2 - S1) - > 10 avg. monthly P2 obs.  *********************************

* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G10_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G10_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G10_A.txt", keep(d_claude_S2_S1) nocons append
}



* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G10_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G10_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G10_B.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G10_C.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G10_C.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G10_C.txt", keep(d_claude_S2_S1) nocons append
}

****************************** P4 - P2 = β (S2 - S1) - > 20 avg. monthly P2 obs.  *********************************

* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G20_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G20_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G20_A.txt", keep(d_claude_S2_S1) nocons append
}



* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G20_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G20_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G20_B.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G20_C.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G20_C.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G20_C.txt", keep(d_claude_S2_S1) nocons append
}


**************************************** P4 - P2 = β (S3 - S1) - All occs. *****************************************

* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1  [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_A.txt", keep(d_claude_S3_S1) nocons append
}



* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_C.txt", keep(d_claude_S3_S1) nocons append
}

****************************** P4 - P2 = β (S3 - S1) - > 10 avg. monthly P2 obs.  *********************************

* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G10_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G10_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G10_A.txt", keep(d_claude_S3_S1) nocons append
}



* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G10_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G10_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G10_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G10_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G10_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G10_C.txt", keep(d_claude_S3_S1) nocons append
}

****************************** P4 - P2 = β (S3 - S1) - > 20 avg. monthly P2 obs.  *********************************

* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_A.txt", keep(d_claude_S3_S1) nocons append
}



* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_C.txt", keep(d_claude_S3_S1) nocons append
}

********************************** P4 - P3 = β (S3 - S1) - > 10 monthly obs ***********************************

* W/ Baseline Model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if freq_wt_P3 >= 10 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G10_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G10_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if freq_wt_P3 >= 10 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G10_A.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 if freq_wt_P3 >= 10 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G10_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G10_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 if freq_wt_P3 >= 10 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G10_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Task Index and Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 if freq_wt_P3 >= 10 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G10_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G10_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 if freq_wt_P3 >= 10 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G10_C.txt", keep(d_claude_S3_S1) nocons append
}

********************************** P4 - P3 = β (S3 - S1) - > 20 monthly obs ***********************************

* W/ Baseline Model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if freq_wt_P3 >= 20 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G20_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G20_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if freq_wt_P3 >= 20 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G20_A.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 if freq_wt_P3 >= 20 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G20_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G20_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 if freq_wt_P3 >= 20 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G20_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Task Index and Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P3 d_unemp_rate_P4_P3 d_ahrswork1_P4_P3 d_ahrswork2_P4_P3 d_ahrsworkt_P4_P3 d_other_job_P4_P3 d_fulltime_P4_P3
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 if freq_wt_P3 >= 20 [aweight = freq_wt_P3], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P3" {
        outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G20_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G20_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p3 prop_age_50plus_p3 prop_black_p3 ///
        prop_asian_p3 prop_native_p3 prop_mixed_other_p3 prop_pacific_p3 ///
        prop_educ_q1_p3 prop_educ_q2_p3 prop_educ_q3_p3 prop_midwest_p3 ///
        prop_northeast_p3 prop_west_p3 prop_fem_p3 if freq_wt_P3 >= 20 [aweight = freq_wt_P3], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P3_S3_S1_G20_C.txt", keep(d_claude_S3_S1) nocons append
}

****************************** P3 - P2 = β (S3 - S1) - > 10 avg. monthly P2 obs.  *********************************

* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G10_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G10_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G10_A.txt", keep(d_claude_S3_S1) nocons append
}



* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G10_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G10_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G10_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G10_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G10_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G10_C.txt", keep(d_claude_S3_S1) nocons append
}

****************************** P3 - P2 = β (S3 - S1) - > 20 avg. monthly P2 obs.  *********************************

* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G20_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G20_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G20_A.txt", keep(d_claude_S3_S1) nocons append
}


* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G20_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G20_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G20_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P3_P2 d_unemp_rate_P3_P2 d_ahrswork1_P3_P2 d_ahrswork2_P3_P2 d_ahrsworkt_P3_P2 d_other_job_P3_P2 d_fulltime_P3_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P3_P2" {
        outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G20_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G20_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P3-P2_S3-S1_G20_C.txt", keep(d_claude_S3_S1) nocons append
}

**************************** P4 - P2 = β (S3 - S1) (Interaction Terms) *******************************

* NR_CA (No controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCA_G10_A.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCA_G10_A.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CA_x_C_3_1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCA_G10_A", keep(d_claude_S3_S1 NR_CA NR_CA_x_C_3_1) nocons append
}

* NR_CA (Controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCA_G10_B.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCA_G10_B.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CA_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCA_G10_B.txt", keep(d_claude_S3_S1 NR_CA NR_CA_x_C_3_1) nocons append
}

* NR_CA (No controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCA_G20_A.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCA_G20_A.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CA_x_C_3_1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCA_G20_A", keep(d_claude_S3_S1 NR_CA NR_CA_x_C_3_1) nocons append
}

* NR_CA (Controls, G > 20 )
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCA_G20_B.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCA_G20_B.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CA_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCA_G20_B.txt", keep(d_claude_S3_S1 NR_CA NR_CA_x_C_3_1) nocons append
}

* NR_CI (No controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCI_G10_A.txt", keep(d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCI_G10_A.txt", keep(d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CI NR_CI_x_C_3_1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCI_G10_A", keep(d_claude_S3_S1 NR_CI NR_CI_x_C_3_1) nocons append
}

* NR_CI (Controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCI_G10_B.txt", keep(d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCI_G10_B.txt", keep(d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CI NR_CI_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCI_G10_B.txt", keep(d_claude_S3_S1 NR_CI NR_CI_x_C_3_1) nocons append
}

* NR_CI (No controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCI_G20_A.txt", keep(d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCI_G20_A.txt", keep(d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CI NR_CI_x_C_3_1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCI_G20_A", keep(d_claude_S3_S1 NR_CI NR_CI_x_C_3_1) nocons append
}

* NR_CI (Controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCI_G20_B.txt", keep(d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCI_G20_B.txt", keep(d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CI NR_CI_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRCI_G20_B.txt", keep(d_claude_S3_S1 NR_CI NR_CI_x_C_3_1) nocons append
}

* RC (No controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 RC RC_x_OA_3_1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RC_G10_A.txt", keep(d_openai_S3_S1 RC RC_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RC_G10_A.txt", keep(d_openai_S3_S1 RC RC_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 RC RC_x_C_3_1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RC_G10_A", keep(d_claude_S3_S1 RC RC_x_C_3_1) nocons append
}

* RC (Controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 RC RC_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RC_G10_B.txt", keep(d_openai_S3_S1 RC RC_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RC_G10_B.txt", keep(d_openai_S3_S1 RC RC_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 RC RC_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RC_G10_B.txt", keep(d_claude_S3_S1 RC RC_x_C_3_1) nocons append
}

* RC (No controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 RC RC_x_OA_3_1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RC_G20_A.txt", keep(d_openai_S3_S1 RC RC_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RC_G20_A.txt", keep(d_openai_S3_S1 RC RC_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 RC RC_x_C_3_1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RC_G20_A", keep(d_claude_S3_S1 RC RC_x_C_3_1) nocons append
}

* RC (Controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 RC RC_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RC_G20_B.txt", keep(d_openai_S3_S1 RC RC_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RC_G20_B.txt", keep(d_openai_S3_S1 RC RC_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 RC RC_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RC_G20_B.txt", keep(d_claude_S3_S1 RC RC_x_C_3_1) nocons append
}

* RM (No controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 RM RM_x_OA_3_1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RM_G10_A.txt", keep(d_openai_S3_S1 RM RM_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RM_G10_A.txt", keep(d_openai_S3_S1 RM RM_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 RM RM_x_C_3_1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RM_G10_A", keep(d_claude_S3_S1 RM RM_x_C_3_1) nocons append
}

* RM (Controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 RM RM_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RM_G10_B.txt", keep(d_openai_S3_S1 RM RM_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RM_G10_B.txt", keep(d_openai_S3_S1 RM RM_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 RM RM_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RM_G10_B.txt", keep(d_claude_S3_S1 RM RM_x_C_3_1) nocons append
}

* RM (No controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 RM RM_x_OA_3_1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RM_G20_A.txt", keep(d_openai_S3_S1 RM RM_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RM_G20_A.txt", keep(d_openai_S3_S1 RM RM_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 RM RM_x_C_3_1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RM_G20_A", keep(d_claude_S3_S1 RM RM_x_C_3_1) nocons append
}

* RM (Controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 RM RM_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RM_G20_B.txt", keep(d_openai_S3_S1 RM RM_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RM_G20_B.txt", keep(d_openai_S3_S1 RM RM_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 RM RM_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_RM_G20_B.txt", keep(d_claude_S3_S1 RM RM_x_C_3_1) nocons append
}


* NRMP (No controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NRMP NRMP_x_OA_3_1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRMP_G10_A.txt", keep(d_openai_S3_S1 NRMP NRMP_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRMP_G10_A.txt", keep(d_openai_S3_S1 NRMP NRMP_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NRMP NRMP_x_C_3_1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRMP_G10_A", keep(d_claude_S3_S1 NRMP NRMP_x_C_3_1) nocons append
}

* NRMP (Controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NRMP NRMP_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRMP_G10_B.txt", keep(d_openai_S3_S1 NRMP NRMP_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRMP_G10_B.txt", keep(d_openai_S3_S1 NRMP NRMP_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NRMP NRMP_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRMP_G10_B.txt", keep(d_claude_S3_S1 NRMP NRMP_x_C_3_1) nocons append
}

* NRMP (No controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NRMP NRMP_x_OA_3_1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRMP_G20_A.txt", keep(d_openai_S3_S1 NRMP NRMP_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRMP_G20_A.txt", keep(d_openai_S3_S1 NRMP NRMP_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NRMP NRMP_x_C_3_1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRMP_G20_A", keep(d_claude_S3_S1 NRMP NRMP_x_C_3_1) nocons append
}

* NRMP (Controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NRMP NRMP_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRMP_G20_B.txt", keep(d_openai_S3_S1 NRMP NRMP_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRMP_G20_B.txt", keep(d_openai_S3_S1 NRMP NRMP_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NRMP NRMP_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_NRMP_G20_B.txt", keep(d_claude_S3_S1 NRMP NRMP_x_C_3_1) nocons append
}

* All indices (No controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1 NR_CI NR_CI_x_OA_3_1 RC RC_x_OA_3_1 RM RM_x_OA_3_1 NRMP NRMP_x_OA_3_1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_ALL_G10_A.txt", nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_ALL_G10_A.txt", nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CA_x_C_3_1 NR_CI NR_CI_x_C_3_1 RC RC_x_C_3_1 RM RM_x_C_3_1 NRMP NRMP_x_C_3_1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_ALL_G10_A.txt", nocons append
}

* ALl indices (Controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1 NR_CI NR_CI_x_OA_3_1 RC RC_x_OA_3_1 RM RM_x_OA_3_1 NRMP NRMP_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_ALL_G10_B.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1 NR_CI NR_CI_x_OA_3_1 RC RC_x_OA_3_1 RM RM_x_OA_3_1 NRMP NRMP_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_ALL_G10_B.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1 NR_CI NR_CI_x_OA_3_1 RC RC_x_OA_3_1 RM RM_x_OA_3_1 NRMP NRMP_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CA_x_C_3_1 NR_CI NR_CI_x_C_3_1 RC RC_x_C_3_1 RM RM_x_C_3_1 NRMP NRMP_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_ALL_G10_B.txt", keep(d_claude_S3_S1 NR_CA NR_CA_x_C_3_1 NR_CI NR_CI_x_C_3_1 RC RC_x_C_3_1 RM RM_x_C_3_1 NRMP NRMP_x_C_3_1) nocons append
}

* All indices (No controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1 NR_CI NR_CI_x_OA_3_1 RC RC_x_OA_3_1 RM RM_x_OA_3_1 NRMP NRMP_x_OA_3_1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_ALL_G20_A.txt", nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_ALL_G20_A.txt", nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CA_x_C_3_1 NR_CI NR_CI_x_C_3_1 RC RC_x_C_3_1 RM RM_x_C_3_1 NRMP NRMP_x_C_3_1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_ALL_G20_A.txt", nocons append
}

* ALl indices (Controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1 NR_CI NR_CI_x_OA_3_1 RC RC_x_OA_3_1 RM RM_x_OA_3_1 NRMP NRMP_x_OA_3_1 prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_ALL_G20_B.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1 NR_CI NR_CI_x_OA_3_1 RC RC_x_OA_3_1 RM RM_x_OA_3_1 NRMP NRMP_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_ALL_G20_B.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1 NR_CI NR_CI_x_OA_3_1 RC RC_x_OA_3_1 RM RM_x_OA_3_1 NRMP NRMP_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CA_x_C_3_1 NR_CI NR_CI_x_C_3_1 RC RC_x_C_3_1 RM RM_x_C_3_1 NRMP NRMP_x_C_3_1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4P2_S3S1_ALL_G20_B.txt", keep(d_claude_S3_S1 NR_CA NR_CA_x_C_3_1 NR_CI NR_CI_x_C_3_1 RC RC_x_C_3_1 RM RM_x_C_3_1 NRMP NRMP_x_C_3_1) nocons append
}

********************************************************************************************************************
******************************************** Residuals for Scatters (5/13) *****************************************
********************************************************************************************************************

************************************************** Adding Titles ***************************************************
use "/Users/jdomins2/Desktop/CPS_Work/Crosswalks/onet_to_cps_crosswalk_cleaned.dta", clear
duplicates drop cps_code, force
destring cps_code, replace
merge 1:1 cps_code using "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta"
drop if _merge == 1
drop _merge
save "$data_root/Cleaned/P1_P4_ld_march2025_6M_w_titles.dta", replace

* All observations 
use "$data_root/Cleaned/P1_P4_ld_march2025_6M_w_titles.dta", clear
xtile q_openai2 = openai2, nquantiles(4)
tab q_openai2, gen(Dqopenai2)
rename Dqopenai24 DQ4_openai2

reg d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
        predict d_openai_S3_S1_resid, resid
		
foreach y in d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2 {
    reg `y' NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    predict `y'_resid, resid
}

save "$data_root/May/Residuals/6M_resid_OA_AO.dta", replace

* All observations 
use "$data_root/Cleaned/P1_P4_ld_march2025_6M_w_titles.dta", clear

keep if freq_wt_P2 >= 10

xtile q_openai2 = openai2, nquantiles(4)
tab q_openai2, gen(Dqopenai2)
rename Dqopenai24 DQ4_openai2

reg d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
        predict d_openai_S3_S1_resid, resid
		
foreach y in d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2 {
    reg `y' NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    predict `y'_resid, resid
}

save "$data_root/May/Residuals/6M_resid_OA_G10.dta", replace

* All observations 
use "$data_root/Cleaned/P1_P4_ld_march2025_6M_w_titles.dta", clear

keep if freq_wt_P2 >= 20

xtile q_openai2 = openai2, nquantiles(4)
tab q_openai2, gen(Dqopenai2)
rename Dqopenai24 DQ4_openai2

reg d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
        predict d_openai_S3_S1_resid, resid
		
foreach y in d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2 {
    reg `y' NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    predict `y'_resid, resid
}

save "$data_root/May/Residuals/6M_resid_OA_G20.dta", replace

* Claude G10
use "$data_root/Cleaned/P1_P4_ld_march2025_6M_w_titles.dta", clear

keep if freq_wt_P2 >= 10

xtile q_claude2 = claude2, nquantiles(4)
tab q_claude2, gen(Dqclaude2)
rename Dqclaude24 DQ4_claude2

reg d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
        predict d_claude_S3_S1_resid, resid
		
foreach y in d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2 {
    reg `y' NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    predict `y'_resid, resid
}

save "$data_root/May/Residuals/6M_resid_C_G10.dta", replace

********************************************************************************************************************
************************************** Quartile Based Index Interactions (5/13) ************************************
********************************************************************************************************************


* NR_CA (No controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCA_G10_A.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCA_G10_A.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCA_G10_A", keep(d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1) nocons append
}

* NR_CA (Controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCA_G10_B.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCA_G10_B.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCA_G10_B.txt", keep(d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1) nocons append
}

* NR_CA (No controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCA_G20_A.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCA_G20_A.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCA_G20_A", keep(d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1) nocons append
}

* NR_CA (Controls, G > 20 )
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCA_G20_B.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCA_G20_B.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCA_G20_B.txt", keep(d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1) nocons append
}

* NR_CI (No controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCI_G10_A.txt", keep(d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCI_G10_A.txt", keep(d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCI_G10_A", keep(d_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1) nocons append
}

* NR_CI (Controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCI_G10_B.txt", keep(d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCI_G10_B.txt", keep(d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCI_G10_B.txt", keep(d_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1) nocons append
}

* NR_CI (No controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCI_G20_A.txt", keep(d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCI_G20_A.txt", keep(d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCI_G20_A", keep(d_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1) nocons append
}

* NR_CI (Controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCI_G20_B.txt", keep(d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCI_G20_B.txt", keep(d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRCI_G20_B.txt", keep(d_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1) nocons append
}

* RC (No controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RC_G10_A.txt", keep(d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RC_G10_A.txt", keep(d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RC_G10_A", keep(d_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1) nocons append
}

* RC (Controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RC_G10_B.txt", keep(d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RC_G10_B.txt", keep(d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RC_G10_B.txt", keep(d_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1) nocons append
}

* RC (No controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RC_G20_A.txt", keep(d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RC_G20_A.txt", keep(d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RC_G20_A", keep(d_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1) nocons append
}

* RC (Controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RC_G20_B.txt", keep(d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RC_G20_B.txt", keep(d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RC_G20_B.txt", keep(d_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1) nocons append
}


* RM (No controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RM_G10_A.txt", keep(d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RM_G10_A.txt", keep(d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RM_G10_A", keep(d_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1) nocons append
}

* RM (Controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RM_G10_B.txt", keep(d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RM_G10_B.txt", keep(d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1) nocons append
    }
}
foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RM_G10_B.txt", keep(d_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1) nocons append
}

* RM (No controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RM_G20_A.txt", keep(d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RM_G20_A.txt", keep(d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RM_G20_A", keep(d_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1) nocons append
}

* RM (Controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RM_G20_B.txt", keep(d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RM_G20_B.txt", keep(d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1) nocons append
    }
}
foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_RM_G20_B.txt", keep(d_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1) nocons append
}


* NRMP (No controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRMP_G10_A.txt", keep(d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRMP_G10_A.txt", keep(d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRMP_G10_A", keep(d_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1) nocons append
}

* NRMP (Controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRMP_G10_B.txt", keep(d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRMP_G10_B.txt", keep(d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRMP_G10_B.txt", keep(d_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1) nocons append
}

* NRMP (No controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRMP_G20_A.txt", keep(d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRMP_G20_A.txt", keep(d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRMP_G20_A", keep(d_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1) nocons append
}

* NRMP (Controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRMP_G20_B.txt", keep(d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRMP_G20_B.txt", keep(d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_NRMP_G20_B.txt", keep(d_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1) nocons append
}


* All indices (No controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_ALL_G10_A.txt", nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_ALL_G10_A.txt", nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_ALL_G10_A.txt", nocons append
}

* ALl indices (Controls, G > 10)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1 DQ4_NRMP ///
		DQ4NRMP_x_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_ALL_G10_B.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_ALL_G10_B.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1 DQ4_NRMP /// 
		DQ4NRMP_x_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_ALL_G10_B.txt", keep(d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1) nocons append
}

* All indices (No controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_ALL_G20_A.txt", nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_ALL_G20_A.txt", nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_ALL_G20_A.txt", nocons append
}

* ALl indices (Controls, G > 20)
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1 DQ4_NRMP ///
		DQ4NRMP_x_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_ALL_G20_B.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_ALL_G20_B.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1 DQ4_NRMP /// 
		DQ4NRMP_x_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/05_14_25/P4P2_S3S1_ALL_G20_B.txt", keep(d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1) nocons append
}


********************************************************************************************************************
************************************* Fully specified interaction models (5/16) ************************************
********************************************************************************************************************

* NRCA, controls, task indices, all obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1 NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/NRCA_cont_A.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/NRCA_cont_A.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CA_x_C_3_1 NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/NRCA_cont_A.txt", keep(d_claude_S3_S1 NR_CA NR_CA_x_C_3_1 ) nocons append
}

* NRCA, controls, task indices, >= 10 monthly obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1 NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/NRCA_cont_B.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/NRCA_cont_B.txt", keep(d_openai_S3_S1 NR_CA NR_CA_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CA_x_C_3_1 NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/NRCA_cont_B.txt", keep(d_claude_S3_S1 NR_CA NR_CA_x_C_3_1 ) nocons append
}

* NRCI, controls, task indices, all obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1 NR_CA RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/NRCI_cont_A.txt", keep(d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/NRCI_cont_A.txt", keep(d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CI NR_CI_x_C_3_1 NR_CA RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/NRCI_cont_A.txt", keep(d_claude_S3_S1 NR_CI NR_CI_x_C_3_1 ) nocons append
}

* NRCI, controls, task indices, >= 10 monthly obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1 NR_CA RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/NRCI_cont_B.txt", keep(d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/NRCI_cont_B.txt", keep(d_openai_S3_S1 NR_CI NR_CI_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CI NR_CI_x_C_3_1 NR_CA RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/NRCI_cont_B.txt", keep(d_claude_S3_S1 NR_CI NR_CI_x_C_3_1 ) nocons append
}

* RC, controls, task indices, all obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 RC RC_x_OA_3_1 NR_CA NR_CI RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/RC_cont_A.txt", keep(d_openai_S3_S1 RC RC_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/RC_cont_A.txt", keep(d_openai_S3_S1 RC RC_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 RC RC_x_C_3_1 NR_CA NR_CI RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/RC_cont_A.txt", keep(d_claude_S3_S1 RC RC_x_C_3_1 ) nocons append
}

* RC, controls, task indices, >= 10 monthly obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 RC RC_x_OA_3_1 NR_CA NR_CI RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/RC_cont_B.txt", keep(d_openai_S3_S1 RC RC_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/RC_cont_B.txt", keep(d_openai_S3_S1 RC RC_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 RC RC_x_C_3_1 NR_CA NR_CI RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/RC_cont_B.txt", keep(d_claude_S3_S1 RC RC_x_C_3_1 ) nocons append
}

* RM, controls, task indices, all obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 RM RM_x_OA_3_1 NR_CA NR_CI RC NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/RM_cont_A.txt", keep(d_openai_S3_S1 RM RM_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/RM_cont_A.txt", keep(d_openai_S3_S1 RM RM_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 RM RM_x_C_3_1 NR_CA NR_CI RC NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/RM_cont_A.txt", keep(d_claude_S3_S1 RM RM_x_C_3_1 ) nocons append
}

* RM, controls, task indices, >= 10 monthly obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 RM RM_x_OA_3_1 NR_CA NR_CI RC NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/RM_cont_B.txt", keep(d_openai_S3_S1 RM RM_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/RM_cont_B.txt", keep(d_openai_S3_S1 RM RM_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 RM RM_x_C_3_1 NR_CA NR_CI RC NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/RM_cont_B.txt", keep(d_claude_S3_S1 RM RM_x_C_3_1 ) nocons append
}

* NRMP, controls, task indices, all obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NRMP NRMP_x_OA_3_1 NR_CA NR_CI RC RM prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/NRMP_cont_A.txt", keep(d_openai_S3_S1 NRMP NRMP_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/NRMP_cont_A.txt", keep(d_openai_S3_S1 NRMP NRMP_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NRMP NRMP_x_C_3_1 NR_CA NR_CI RC RM prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/NRMP_cont_A.txt", keep(d_claude_S3_S1 NRMP NRMP_x_C_3_1 ) nocons append
}

* NRMP, controls, task indices, >= 10 monthly obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NRMP NRMP_x_OA_3_1 NR_CA NR_CI RC RM prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/NRMP_cont_B.txt", keep(d_openai_S3_S1 NRMP NRMP_x_OA_3_1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/NRMP_cont_B.txt", keep(d_openai_S3_S1 NRMP NRMP_x_OA_3_1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NRMP NRMP_x_C_3_1 NR_CA NR_CI RC RM prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/NRMP_cont_B.txt", keep(d_claude_S3_S1 NRMP NRMP_x_C_3_1 ) nocons append
}



* D_NRCA, controls, task indices, all obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 /// 		
		prop_age_50plus_p2 prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/NRCA_Dummy_A.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/NRCA_Dummy_A.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 ///
        prop_age_50plus_p2 prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/NRCA_Dummy_A.txt", keep(d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1) nocons append
}

* D_NRCA, controls, task indices, >= 10 monthly obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 /// 		
		prop_age_50plus_p2 prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/NRCA_Dummy_B.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/NRCA_Dummy_B.txt", keep(d_openai_S3_S1 DQ4_NR_CA DQ4NR_CA_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2  ///
        prop_age_50plus_p2 prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/NRCA_Dummy_B.txt", keep(d_claude_S3_S1 DQ4_NR_CA DQ4NR_CA_x_claude_S3_S1) nocons append
}


* D_NRCI, controls, task indices, all obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 /// 		
		prop_age_50plus_p2 prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/NRCI_Dummy_A.txt", keep(d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/NRCI_Dummy_A.txt", keep(d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 ///
        prop_age_50plus_p2 prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/NRCI_Dummy_A.txt", keep(d_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1) nocons append
}

* D_NRCI, controls, task indices, >= 10 monthly obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 /// 		
		prop_age_50plus_p2 prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/NRCI_Dummy_B.txt", keep(d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/NRCI_Dummy_B.txt", keep(d_openai_S3_S1 DQ4_NR_CI DQ4NR_CI_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 ///
       prop_age_50plus_p2 prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/NRCI_Dummy_B.txt", keep(d_claude_S3_S1 DQ4_NR_CI DQ4NR_CI_x_claude_S3_S1) nocons append
}

* D_RC, controls, task indices, all obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/RC_Dummy_A.txt", keep(d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/RC_Dummy_A.txt", keep(d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2  ///
        prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/RC_Dummy_A.txt", keep(d_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1) nocons append
}

* D_RC, controls, task indices, >= 10 monthly obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/RC_Dummy_B.txt", keep(d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/RC_Dummy_B.txt", keep(d_openai_S3_S1 DQ4_RC DQ4RC_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 ///
        prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/RC_Dummy_B.txt", keep(d_claude_S3_S1 DQ4_RC DQ4RC_x_claude_S3_S1) nocons append
}

* D_RM, controls, task indices, all obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/RM_Dummy_A.txt", keep(d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/RM_Dummy_A.txt", keep(d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 ///
        prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/RM_Dummy_A.txt", keep(d_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1) nocons append
}

* D_RM, controls, task indices, >= 10 monthly obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 /// 		
		prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/RM_Dummy_B.txt", keep(d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/RM_Dummy_B.txt", keep(d_openai_S3_S1 DQ4_RM DQ4RM_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 ///
        prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/RM_Dummy_B.txt", keep(d_claude_S3_S1 DQ4_RM DQ4RM_x_claude_S3_S1) nocons append
}

* D_NRMP, controls, task indices, all obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 /// 		
		prop_age_50plus_p2  prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/NRMP_Dummy_A.txt", keep(d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/NRMP_Dummy_A.txt", keep(d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 ///
        prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/NRMP_Dummy_A.txt", keep(d_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1) nocons append
}

* D_NRMP, controls, task indices, >= 10 monthly obs
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 /// 		
		prop_age_50plus_p2 prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_16/NRMP_Dummy_B.txt", keep(d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_16/NRMP_Dummy_B.txt", keep(d_openai_S3_S1 DQ4_NRMP DQ4NRMP_x_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 ///
        prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_16/NRMP_Dummy_B.txt", keep(d_claude_S3_S1 DQ4_NRMP DQ4NRMP_x_claude_S3_S1) nocons append
}

********************************************************************************************************************
************************************** Descriptive Visuals ************************************
********************************************************************************************************************

use "$data_root/Cleaned/P1_P4_ld_march2025_6M_w_titles.dta", clear
sum openai1 openai2 openai3 openai4 openai5, det
sum claude1 claude2 claude3 claude4 claude5, det
gsort -d_openai_S3_S1
list cps_title d_openai_S3_S1 in 1/40 
sort d_openai_S3_S1
list cps_title d_openai_S3_S1 in 1/40 


use "$data_root/Cleaned/cps_for_analysis_march25.dta", clear

* Count number of people per occupation-month cell
gen person = 1
collapse (sum) person, by(cps_code ntime)

* Rename and save
rename person n_obs
save "$data_root/Cleaned/cps_monthly_occ_n.dta", replace

use "$data_root/Cleaned/monthly_cps_by_occ_march25.dta", clear
merge 1:1 cps_code ntime using "$data_root/Cleaned/cps_monthly_occ_n.dta"
drop _merge
save "$data_root/Cleaned/monthly_cps_by_occ_march25.dta",

* Exposure Summary Statistics
sum openai1 openai2 openai3 openai4 openai5 d_openai_S2_S1 d_openai_S3_S2 d_openai_S3_S1, det
sum claude1 claude2 claude3 claude4 claude5 d_claude_S3_S1 d_claude_S3_S2 d_claude_S2_S1, det


use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear
twoway (scatter d_claude_S3_S1 d_openai_S3_S1, msymbol(o)) ///
       (function y=x, range(d_openai_S3_S1)), ///
       ytitle("Claude Exposure") xtitle("ChatGPT Exposure") ///
       title("Claude vs. ChatGPT Exposure by Occupation") ///
       legend(off)
	   
* Correlation
foreach num in 1 2 3 4 5 {
	pwcorr openai`num' claude`num', sig
	spearman openai`num' claude`num'
}

* Correlation
foreach num in S3_S1 S3_S2 S2_S1 {
	pwcorr d_openai_`num' d_claude_`num', sig
	spearman d_openai_`num' d_claude_`num'
}

* Outcome Summary Statistics
sum d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2

* Control Summary Statistics
sum prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2
		
* Task Index Summary Stats
sum NR_CA NR_CI RC RM NRMP offshore

* Top and bottom 40
use "$data_root/Cleaned/P1_P4_ld_march2025_6M_w_titles.dta", clear
gsort -d_openai_S3_S1
list cps_code cps_title d_openai_S3_S1 in 1/40

* Binned scatter by age 
use "$data_root/Cleaned/cps_for_analysis_march25.dta", clear

binscatter d_openai_3_1 age, nquantiles(30) ///
    controls() ///
    ytitle("Change in ChatGPT Exposure (S3–S1)") ///
    xtitle("Age") ///
    title("Binned Scatterplot: Exposure vs. Age") ///
    mcolor(navy) ///
	linetype(none) ///
    graphregion(color(white)) ///
    legend(off)
	
binscatter d_openai_S3_S1 prop_fem_p2, nquantiles(30) ///
    controls() ///
    ytitle("Change in ChatGPT Exposure (S3–S1)") ///
    xtitle("Percent Female Workers in Occupation") ///
    title("Binned Scatterplot: Δ Exposure vs. Share Female") ///
    mcolor(navy) ///
	linetype(none) ///
    graphregion(color(white)) ///
    legend(off)

********************************************************************************************************************
************************************************** Checks (5/28) ***************************************************
********************************************************************************************************************

	
**************************************** P4 - P2 = β (S2 - S1) - All occs. *****************************************

* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1  [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_A.txt", keep(d_claude_S2_S1) nocons append
}



* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_B.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_29/P4-P2_S2-S1_C.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_29/P4-P2_S2-S1_C.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_29/P4-P2_S2-S1_C.txt", keep(d_claude_S2_S1) nocons append
}

****************************** P4 - P2 = β (S2 - S1) - > 10 avg. monthly P2 obs.  *********************************

* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G10_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G10_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G10_A.txt", keep(d_claude_S2_S1) nocons append
}



* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G10_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G10_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G10_B.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_29/P4-P2_S2-S1_G10_C.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_29/P4-P2_S2-S1_G10_C.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_29/P4-P2_S2-S1_G10_C.txt", keep(d_claude_S2_S1) nocons append
}

****************************** P4 - P2 = β (S2 - S1) - > 20 avg. monthly P2 obs.  *********************************

* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G20_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G20_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G20_A.txt", keep(d_claude_S2_S1) nocons append
}



* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G20_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G20_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S2-S1_G20_B.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_29/P4-P2_S2-S1_G20_C.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_29/P4-P2_S2-S1_G20_C.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_29/P4-P2_S2-S1_G20_C.txt", keep(d_claude_S2_S1) nocons append
}


**************************************** P4 - P2 = β (S3 - S1) - All occs. *****************************************

* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1  [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_A.txt", keep(d_claude_S3_S1) nocons append
}



* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_29/P4-P2_S3-S1_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_29/P4-P2_S3-S1_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_29/P4-P2_S3-S1_C.txt", keep(d_claude_S3_S1) nocons append
}

****************************** P4 - P2 = β (S3 - S1) - > 10 avg. monthly P2 obs.  *********************************

* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G10_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G10_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G10_A.txt", keep(d_claude_S3_S1) nocons append
}



* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G10_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G10_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G10_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/5_29/P4-P2_S3-S1_G10_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_29/P4-P2_S3-S1_G10_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/5_29/P4-P2_S3-S1_G10_C.txt", keep(d_claude_S3_S1) nocons append
}

****************************** P4 - P2 = β (S3 - S1) - > 20 avg. monthly P2 obs.  *********************************

* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_A.txt", keep(d_claude_S3_S1) nocons append
}



* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/May/txt/WP/P4-P2_S3-S1_G20_C.txt", keep(d_claude_S3_S1) nocons append
}

*******************************************************************************************************************
******************************************* Quartile Interactions  ************************************************
*******************************************************************************************************************

****************************** Top Quartile *********************************

use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear
* Creating Quartile-based Interaction Terms
foreach var in openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5 {
    forvalues num = 1/4 {
gen `var'_x_DQ`num'_`var'= `var' * DQ`num'_`var'
	}
}

gen d_openai_3_1_x_DQ1= d_openai_S3_S1 * Dqd_openai_3_11
gen d_openai_3_1_x_DQ4= d_openai_S3_S1 * Dqd_openai_3_14

gen d_claude_3_1_x_DQ1= d_claude_S3_S1 * Dqd_claude_3_11
gen d_claude_3_1_x_DQ4= d_claude_S3_S1 * Dqd_claude_3_14
save "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", replace

* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 d_openai_3_1_x_DQ4 Dqd_openai_3_14 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/June/txt/6_12/top_Q_D_A.txt", keep(d_openai_S3_S1 d_openai_3_1_x_DQ4 Dqd_openai_3_14) nocons replace
    }
    else {
        outreg2 using  "$export_root/June/txt/6_12/top_Q_D_A.txt", keep(d_openai_S3_S1 d_openai_3_1_x_DQ4 Dqd_openai_3_14) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 d_claude_3_1_x_DQ4 Dqd_claude_3_14 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/June/txt/6_12/top_Q_D_A.txt", keep(d_claude_S3_S1 d_claude_3_1_x_DQ4 Dqd_claude_3_14) nocons append
}

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 d_openai_3_1_x_DQ4 Dqd_openai_3_14 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
		
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/June/txt/6_12/top_Q_D_B.txt", keep(d_openai_S3_S1 d_openai_3_1_x_DQ4 Dqd_openai_3_14) nocons replace
    }
    else {
        outreg2 using  "$export_root/June/txt/6_12/top_Q_D_B.txt", keep(d_openai_S3_S1 d_openai_3_1_x_DQ4 Dqd_openai_3_14) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 d_claude_3_1_x_DQ4 Dqd_claude_3_14 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/June/txt/6_12/top_Q_D_B.txt", keep(d_claude_S3_S1 d_claude_3_1_x_DQ4 Dqd_claude_3_14) nocons append
}


* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 d_openai_3_1_x_DQ4 Dqd_openai_3_14 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_p2 prop_age_50plus_p2 ///
        prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
		
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/June/txt/6_12/top_Q_D_C.txt", keep(d_openai_S3_S1 d_openai_3_1_x_DQ4 Dqd_openai_3_14) nocons replace
    }
    else {
        outreg2 using  "$export_root/June/txt/6_12/top_Q_D_C.txt", keep(d_openai_S3_S1 d_openai_3_1_x_DQ4 Dqd_openai_3_14) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 d_claude_3_1_x_DQ4 Dqd_claude_3_14 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_p2 prop_age_50plus_p2 ///
        prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/June/txt/6_12/top_Q_D_C.txt", keep(d_claude_S3_S1 d_claude_3_1_x_DQ4 Dqd_claude_3_14) nocons append
}

****************************** Bottom Quartile *********************************


* Baseline model
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 d_openai_3_1_x_DQ1 Dqd_openai_3_11 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/June/txt/6_12/bottom_Q_D_A.txt", keep(d_openai_S3_S1 d_openai_3_1_x_DQ1 Dqd_openai_3_11) nocons replace
    }
    else {
        outreg2 using  "$export_root/June/txt/6_12/bottom_Q_D_A.txt", keep(d_openai_S3_S1 d_openai_3_1_x_DQ1 Dqd_openai_3_11) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 d_claude_3_1_x_DQ1 Dqd_claude_3_11 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/June/txt/6_12/bottom_Q_D_A.txt", keep(d_claude_S3_S1 d_claude_3_1_x_DQ1 Dqd_claude_3_11) nocons append
}

* W/ Demographic Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 d_openai_3_1_x_DQ1 Dqd_openai_3_11  prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
		
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/June/txt/6_12/bottom_Q_D_B.txt", keep(d_openai_S3_S1 d_openai_3_1_x_DQ1 Dqd_openai_3_11) nocons replace
    }
    else {
        outreg2 using  "$export_root/June/txt/6_12/bottom_Q_D_B.txt", keep(d_openai_S3_S1 d_openai_3_1_x_DQ1 Dqd_openai_3_11) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 d_claude_3_1_x_DQ1 Dqd_claude_3_11 prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/June/txt/6_12/bottom_Q_D_B.txt", keep(d_claude_S3_S1 d_claude_3_1_x_DQ1 Dqd_claude_3_11) nocons append
}


* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 d_openai_3_1_x_DQ1 Dqd_openai_3_11  NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_p2 prop_age_50plus_p2 ///
        prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
		
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/June/txt/6_12/bottom_Q_D_C.txt", keep(d_openai_S3_S1 d_openai_3_1_x_DQ1 Dqd_openai_3_11) nocons replace
    }
    else {
        outreg2 using  "$export_root/June/txt/6_12/bottom_Q_D_C.txt", keep(d_openai_S3_S1 d_openai_3_1_x_DQ1 Dqd_openai_3_11) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 d_claude_3_1_x_DQ1 Dqd_claude_3_11 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_p2 prop_age_50plus_p2 ///
        prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 10 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/June/txt/6_12/bottom_Q_D_C.txt", keep(d_claude_S3_S1 d_claude_3_1_x_DQ1 Dqd_claude_3_11) nocons append
}


********************************************************************************************************************
************************************************** Draft (6/26) ***************************************************
********************************************************************************************************************

*** G20
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/June/txt/6_26/main_g20.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_26/main_g20.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 20 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/June/txt/6_26/main_g20.txt", keep(d_claude_S3_S1) nocons append
}

*** G50
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 50 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/June/txt/6_26/main_g50.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_26/main_g50.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 50 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/June/txt/6_26/main_g50.txt", keep(d_claude_S3_S1) nocons append
}

*** G100
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 100 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/June/txt/6_26/main_g100.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_26/main_g100.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 100 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/June/txt/6_26/main_g100.txt", keep(d_claude_S3_S1) nocons append
}

*** G150
use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 150 [aweight = freq_wt_P2], vce(robust)
    
    if "`y'" == "d_log_emp_P4_P2" {
        outreg2 using "$export_root/June/txt/6_26/main_g150.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_26/main_g150.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 if freq_wt_P2 >= 150 [aweight = freq_wt_P2], vce(robust)
	outreg2 using "$export_root/June/txt/6_26/main_g150.txt", keep(d_claude_S3_S1) nocons append
}





use "$data_root/Cleaned/P1_P4_ld_march2025_6M.dta", clear

local outcomes d_log_emp_P4_P2 d_unemp_rate_P4_P2 d_ahrswork1_P4_P2 d_ahrswork2_P4_P2 d_ahrsworkt_P4_P2 d_other_job_P4_P2 d_fulltime_P4_P2
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
    
   
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP prop_age_30to50_p2 prop_age_50plus_p2 prop_black_p2 ///
        prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 ///
        prop_northeast_p2 prop_west_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
	
}
