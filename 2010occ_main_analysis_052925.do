* Name: 2010occ_main_analysis_052925
* Author: Jacob Dominski
* Date Created:05/29/25

************************************************ Set Global paths **************************************************

global data_root = "/Users/jdomins2/Desktop/CPS_Work/Data"
global export_root = "/Users/jdomins2/Desktop/CPS_Work/Output"
global crosswalk_root = "/Users/jdomins2/Desktop/CPS_Work/Crosswalks"


************************************* Creating 2010 CPS to OCC2010 crosswalk ****************************************

use "$data_root/CPS/monthly_cps_2010_2025", clear

*** Only keeping years they use the 2010 CPS system
keep if year >= 2011 & year <= 2019

*** Making sure we have numerical codes
destring occ occ2010, replace force

*** Creating crosswalk of all unique (OCC, OCC2010) pairs
contract occ occ2010

*** Sorting by harmonized code for readability
sort occ2010 occ

*** Counting distinct 2010 CPS and OCC2010 codes
distinct occ
distinct occ2010
*** 534 distinct 2010 CPS occupations, none match to more than one occ2010
*** 453 distinct occ2010 occupations, some match to more than one 2010 CPS occupations
*** The map from 2010 CPS to OCC2010 is 1:1 and M:1

save "$crosswalk_root/crosswalk_occ_to_occ2010_2011_2019.dta", replace

use "$data_root/Working/cps_2010_exp.dta", clear
merge 1:1 occ using "$crosswalk_root/crosswalk_occ_to_occ2010_2011_2019.dta"
list occ if _merge == 1
*** Missing CPS data for 3 occupations for which we have exposure scores: Judges, postmasters, and legislators
list occ if _merge == 2
drop if occ == 0
*** Missing exposure scores for 15 2010 CPS occupations, all of which are "all other" or "miscellaneous" occupations
drop if _merge == 1 | _merge == 2

collapse (mean) openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5 [aw=_freq], by(occ2010)
save "$data_root/Working/OCC2010_from_CPS_2010_exp.dta", replace

*** Check
gsort - openai3 
list occ2010 openai3 in 1/40

************************************* Creating 2018 CPS to OCC2010 crosswalk ****************************************

use "$data_root/CPS/monthly_cps_2010_2025", clear

*** Only keeping years they use the 2010 CPS system
keep if year >= 2020

*** Making sure we have numerical codes
destring occ occ2010, replace force

*** Creating crosswalk of all unique (OCC, OCC2010) pairs
contract occ occ2010

*** Sorting by harmonized code for readability
sort occ2010 occ

*** Counting distinct 2018 CPS and OCC2010 codes
distinct occ
distinct occ2010
*** 527 distinct 2018 CPS occupations, none match to more than one occ2010
*** 424 distinct occ2010 occupations, some match to more than one 2018 CPS occupations
*** The map from 2018 CPS to OCC2010 is 1:1 and M:1

save "$crosswalk_root/crosswalk_occ_to_occ2010_2020_2025.dta", replace

use "$data_root/Ai_Exposure/v2/Cleaned/occ_exposure_openAI_claude_llama_v3.dta", clear
rename cps_code occ
rename cps_openai_final_exp_s* openai*
rename cps_claude_final_exp_s* claude*
merge 1:1 occ using "$crosswalk_root/crosswalk_occ_to_occ2010_2020_2025.dta"
list occ if _merge == 1
*** Missing CPS data for 1 occupations for which we have exposure scores: legislators
list occ if _merge == 2
drop if occ == 0
*** Missing exposure scores for 13 2018 CPS occupations, all of which are "all other" occupations
drop if _merge == 1 | _merge == 2

collapse (mean) openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5 [aw=_freq], by(occ2010)
rename openai* openai*_2018
rename claude* claude*_2018
save "$data_root/Working/OCC2010_from_CPS_2018_exp.dta", replace

*** Check
gsort - openai3 
list occ2010 openai3 in 1/40

************************************* Comparing scores ****************************************
merge 1:1 occ2010 using "$data_root/Working/OCC2010_from_CPS_2010_exp.dta"
list occ2010 if _merge == 1
list occ2010 if _merge == 2
*** Missing 3 exposure scores when use 2010 cps to occ2010 map
*** Missing 29 exposure scores when using 2018 cps to occ2010 map
count if openai3 != openai3_2018
gen d_check = abs(openai3 - openai3_2018) if openai3 != openai3_2018
sum d_check, det
rename d_check d_check_3
gen d_check1 = abs(openai1 - openai1_2018) if openai1 != openai1_2018
gen d_check2 = abs(openai2 - openai2_2018) if openai2 != openai2_2018
gen d_check4 = abs(openai3 - openai3_2018) if openai3 != openai3_2018
gen d_check5 = abs(openai4 - openai4_2018) if openai4 != openai4_2018
sum d_check1 d_check2 d_check_3 d_check4 d_check5, det
save "$data_root/Cleaned/OCC2010_exp.dta", replace

*********************************************  Merging CPS w/ Exposure *********************************************
use "$data_root/CPS/monthly_cps_2010_2025", clear
*** 22,002,427 obs***
tab occ2010

*** Dropping obs without occ2010 codes (NIU)
drop if occ2010 == 9999
*** 11,025,017 obs ***

merge m:1 occ2010 using "$data_root/Working/OCC2010_from_CPS_2018_exp.dta"
* There are no occupations for which we have exposure scores but no CPS data (_merge == 2)

preserve
keep if _merge == 1
gen byte tag = 0
bysort occ2010 (month year): replace tag = 1 if _n == 1
keep if tag == 1
drop tag
list occ2010
restore
* We don't have exposure scores for 35 unique occupations; 29 of these are occupations who do not appear in CPS basic monthlies past 2019; we would like a consistent set of occupations and exposure scores to compare
* The remaining 6 occupations are: "Religious Workers, nec," "Sales and Related Workers, all other," "Communications Equipment Operators, All Other," "Food Processing, nec," "Motor Vehicle Operators, All Other," and "Military, Rank Not Specified." These are all residual or unclassified occupational buckets. When using both the 2010 and 2018 CPS systems, there were a variety of "all other" occupations for which we failed to generate exposure scores. This occured because O*NET does not provide the detailed task data used to generate our scores for "all other" occupations. These 6 residual occupations also map to these "all other" occupations on O*NET.

drop if _merge == 1
* 10,927,923 obs
drop _merge

save "$data_root/Working/cps_2010_2025_occ2010.dta", replace

******************************************* Cleaning at Individual Level *******************************************

use "$data_root/Working/cps_2010_2025_occ2010.dta", clear
rename openai*_2018 openai*_occ2010
rename claude*_2018 claude*_occ2010

keep if age>=18
***10,770,541 obs***

keep if age<65
***10,010,844 obs***

* Creating time
gen time = ym(year, month) 
format time %tm 
br time 
gen ntime=time-755 


gen Dunemp = .
replace Dunemp = 1 if empstat == 21
replace Dunemp = 0 if empstat == 10 | empstat == 12  // employed (at work or not at work)


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



* Exposure Quartiles for OpenAI and Claude Exposure Scores
foreach var in openai1_occ2010 openai2_occ2010 openai3_occ2010 openai4_occ2010 openai5_occ2010 claude1_occ2010 claude2_occ2010 claude3_occ2010 claude4_occ2010 claude5_occ2010{
	xtile q_`var' = `var', nquantiles(4)
}

* Exposure Quartile Dummies
foreach var in openai1_occ2010 openai2_occ2010 openai3_occ2010 openai4_occ2010 openai5_occ2010 claude1_occ2010 claude2_occ2010 claude3_occ2010 claude4_occ2010 claude5_occ2010 {
	tab q_`var', gen(Dq`var')
}

* Renaming Quartile Dummies
foreach var in openai1_occ2010 openai2_occ2010 openai3_occ2010 openai4_occ2010 openai5_occ2010 claude1_occ2010 claude2_occ2010 claude3_occ2010 claude4_occ2010 claude5_occ2010{
	rename Dq`var'1 DQ1_`var'
	rename Dq`var'2 DQ2_`var'
	rename Dq`var'3 DQ3_`var'
	rename Dq`var'4 DQ4_`var'
}


* Checking Unemployment Statistics by Exposure Score
tab empstat
tabstat openai1_occ2010 openai3_occ2010, by(empstat) stats(n mean min max)


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


* Creating Unemployment Rate
gen demployed = 0
replace demployed = 1 if empstat == 10 | empstat == 12
gen dlabforce = 1
replace dlabforce = 0 if empstat == 31 | empstat == 32 | empstat == 33 | empstat == 34 | empstat == 35 | empstat ==36

preserve
collapse (sum) emp_count=demployed labor_force_count=dlabforce, by(year month occ2010)
save "$data_root/Working/monthly_emp_labforce_2011_2019.dta", replace
restore

merge m:1 year month occ2010 using "$data_root/Working/monthly_emp_labforce_2011_2019.dta"
drop _merge
gen unemp_rate = 1 - (emp_count / labor_force_count) if labor_force_count > 0
br year month occ2010 emp_count labor_force_count unemp_rate

* Checking Hours Worked
gen hrs_work_check = ahrswork1 + ahrswork2
count if hrs_work_check != ahrsworkt & !missing(ahrswork2)
drop hrs_work_check

* Creating Other Job Dummy
gen other_job = .
replace other_job = 0 if empstat == 10 | empstat == 12  // Employed: at work or not at work
replace other_job = 1 if ((ahrswork2 > 0 & !missing(ahrswork2)) | ((uhrswork2 > 0 & !missing(uhrswork2)) & (empstat == 10 | empstat == 12)))

tab actsame
replace actsame = . if actsame > 98
gen new_wrk_acts = 0 if !missing(actsame)
replace new_wrk_acts = 1 if actsame == 2 

gen d_south = (statefip == 10 | statefip == 11 | statefip == 12 | statefip == 13 | statefip == 24 | statefip == 37 | statefip == 45 | statefip == 51 | statefip == 54 | statefip == 1 | statefip == 21 | statefip == 28 | statefip == 47 | statefip == 5 | statefip == 22 | statefip == 40 | statefip == 48)
gen d_midwest = (statefip == 17 | statefip == 18 | statefip == 26 | statefip == 39 | statefip == 55 | statefip == 19 | statefip == 20 | statefip == 27 | statefip == 29 | statefip == 31 | statefip == 38 | statefip == 46)
gen d_northeast = (statefip == 9 | statefip == 23 | statefip == 25 | statefip == 33 | statefip == 44 | statefip == 50 | statefip == 34 | statefip == 36 | statefip == 42)
gen d_west = (statefip == 4 | statefip == 8 | statefip == 16 | statefip == 30 | statefip == 32 | statefip == 35 | statefip == 49 | statefip == 56 | statefip == 2 | statefip == 6 | statefip == 15 | statefip == 41 | statefip == 53)

gen age_30less = (agegroup == 1)
gen age_30to50 = (agegroup == 2) 
gen age_50plus = (agegroup == 3) 
gen age_under26 = age < 26 if age != .

*** Earnings
sum earnweek2_cpiu_2010, det
replace earnweek2_cpiu_2010 = . if earnweek2_cpiu_2010 == 99999999.99
sum earnweek2_cpiu_2010, det
rename earnweek2_cpiu_2010 EW_2010_Base
gen EW_2010_clean = .
replace EW_2010_clean = EW_2010_Base
replace EW_2010_clean = 2884.61 if EW_2010_clean > 2884.61 & !missing(EW_2010_clean)
gen log_EW_base = log(EW_2010_Base)
gen log_EW_clean = log(EW_2010_clean)

save "$data_root/Working/cps_2010_2025_occ2010_individ.dta", replace

************************************* Creating Occupation-Month Level Outcomes + Controls **************************************
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear


*Creating Occupation, Month Level Outcome Variables
collapse (sum) demployed Dunemp dlabforce ///
         (mean) ahrswork1 ahrsworkt ntime openai1_occ2010 openai2_occ2010 openai3_occ2010 openai4_occ2010 openai5_occ2010 claude1_occ2010 ///
		 claude2_occ2010 claude3_occ2010 claude4_occ2010 claude5_occ2010 unemp_rate other_job new_wrk_acts ahrswork2 Fulltime EW_2010_Base ///
		 log_EW_base EW_2010_clean log_EW_clean, ///
         by(year month occ2010)

*Confirming everything is going well w/ how I calculate unemp. rates
gen unemp_rate_new = Dunemp / dlabforce
list if unemp_rate_new != unemp_rate
gen log_emp = log(demployed)
drop unemp_rate_new
save "$data_root/Cleaned/cps_by_occ_2010_2025_occ2010.dta", replace


use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear
*Creating Occupation-Month Level Controls
sort occ2010 year month

* Generate total count of workers per occupation-month
bysort year month occ2010: gen total_workers = _N
sum total_workers, det

* Compute Proportion of Women 
bysort year month occ2010: egen num_fem = total(Dfem)
gen prop_fem = num_fem / total_workers
sum prop_fem, det

* Compute Education Shares
gen educ_q1 = (educ <= 72) // Less than high school
gen educ_q2 = (educ >= 73 & educ <= 110) // HS Degree & Some College
gen educ_q3 = (educ == 111) // College degree
gen educ_q4 = (educ >= 123)
gen educ_hs_or_less = (educ <= 73)
gen educ_college_or_more = (educ >= 111)
sum educ_q1 educ_q2 educ_q3 educ_q4, det

bysort year month occ2010: egen num_educ_q1 = total(educ_q1)
bysort year month occ2010: egen num_educ_q2 = total(educ_q2)
bysort year month occ2010: egen num_educ_q3 = total(educ_q3)
bysort year month occ2010: egen num_educ_q4 = total(educ_q4)
bysort year month occ2010: egen num_educ_hs_or_less = total(educ_hs_or_less)
bysort year month occ2010: egen num_educ_college_or_more = total(educ_college_or_more)

gen prop_educ_q1 = num_educ_q1 / total_workers
gen prop_educ_q2 = num_educ_q2 / total_workers
gen prop_educ_q3 = num_educ_q3 / total_workers
gen prop_educ_q4 = num_educ_q4 / total_workers
gen prop_educ_hs_or_less = num_educ_hs_or_less / total_workers 
gen prop_educ_college_or_more = num_educ_college_or_more / total_workers 

sum prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4, det

* Compute Age Group Shares 
bysort year month occ2010: egen num_age_30less = total(age_30less)
bysort year month occ2010: egen num_age_30to50 = total(age_30to50)
bysort year month occ2010: egen num_age_50plus = total(age_50plus)
bysort year month occ2010: egen num_age_under26 = total(age_under26)

gen prop_age_30less = num_age_30less / total_workers
gen prop_age_30to50 = num_age_30to50 / total_workers
gen prop_age_50plus = num_age_50plus / total_workers
gen prop_age_under26 = num_age_under26 / total_workers
sum prop_age_30less prop_age_30to50 prop_age_50plus, det

* Compute Race Shares 
bysort year month occ2010: egen num_white = total(race_white)
bysort year month occ2010: egen num_black = total(race_black)
bysort year month occ2010: egen num_asian = total(race_asian)
bysort year month occ2010: egen num_native = total(race_native)
bysort year month occ2010: egen num_pacific = total(race_pacific)
bysort year month occ2010: egen num_mixed_other = total(race_mixed_other)

gen prop_white = num_white / total_workers
gen prop_black = num_black / total_workers
gen prop_asian = num_asian / total_workers
gen prop_native = num_native / total_workers
gen prop_pacific = num_pacific / total_workers
gen prop_mixed_other = num_mixed_other / total_workers
sum prop_white prop_black prop_asian prop_native prop_pacific prop_mixed_other, det

* Keep One Observation per Occupation-Month
collapse (mean) prop_fem prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_educ_hs_or_less prop_educ_college_or_more ///
         prop_age_30less prop_age_30to50 prop_age_50plus prop_age_under26 ///
         prop_white prop_black prop_asian prop_native prop_pacific prop_mixed_other, by(year month occ2010)
save "$data_root/Working/cps_2010_2025_occ2010_controls.dta", replace

* Compute State Shares
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear

* Count the number of workers in each state within each occupation-month
bysort year month occ2010 state: gen workers_in_state = _N

* Compute total workers in the occupation-month
bysort year month occ2010: gen total_occupation_workers = _N

* Compute the proportion of workers in each state
gen prop_state = workers_in_state / total_occupation_workers

* Aggregate to ensure unique state proportions per occupation-month
collapse (mean) prop_state, by(year month occ2010 state)

* Reshape to create separate variables for each state
reshape wide prop_state, i(year month occ2010) j(statefip)


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

egen check_sum = rowtotal(prop_northeast prop_midwest prop_south prop_west)
count if check_sum > 1 | check_sum < 1 
count if check_sum > 1.001
count if check_sum < 0.999
drop check_sum

save "$data_root/Working/state_2010_2025_emp_shares_occ2010.dta", replace


merge 1:1 year month occ2010 using "$data_root/Working/cps_2010_2025_occ2010_controls.dta"
drop _merge

merge 1:1 year month occ2010 using "$data_root/Cleaned/cps_by_occ_2010_2025_occ2010.dta"
drop _merge
rename Fulltime fulltime
save "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", replace

********************************************************************************************************************
*************************************** Creating Averages for 6 Month Periods **************************************
********************************************************************************************************************

********************************************* P1C (Oct 2010 - March 2011) *******************************************

use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear

* Keep P1C 
keep if ((year == 2011 & (month == 1 | month == 2 | month == 3)) | (year == 2010 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010)


* Rename variables to specify they are from P1C
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime /// 
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P1C
}

save "$data_root/Working/P1C.dta", replace

********************************************* P2C (Oct 2011 - March 2012) *******************************************

use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear

* Keep P2C 
keep if ((year == 2012 & (month == 1 | month == 2 | month == 3)) | (year == 2011 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010)


* Rename variables to specify they are from P2C
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P2C
}

save "$data_root/Working/P2C.dta", replace

********************************************* P3C (Oct 2012 - March 2013) *******************************************

use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear

* Keep P3C 
keep if ((year == 2013 & (month == 1 | month == 2 | month == 3)) | (year == 2012 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5 ///
prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010)


* Rename variables to specify they are from P3C
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P3C
}

save "$data_root/Working/P3C.dta", replace

********************************************* P4C (Oct 2013 - March 2014) *******************************************

use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear

* Keep P4C (
keep if ((year == 2014 & (month == 1 | month == 2 | month == 3)) | (year == 2013 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010)


* Rename variables to specify they are from P4C
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P4C
}

save "$data_root/Working/P4C.dta", replace

********************************************* P5C (Oct 2014 - March 2015) *******************************************

use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear

* Keep P5C 
keep if ((year == 2015 & (month == 1 | month == 2 | month == 3)) | (year == 2014 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010)


* Rename variables to specify they are from P5C
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest  /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P5C
}

save "$data_root/Working/P5C.dta", replace

********************************************* P6C (Oct 2015 - March 2016) *******************************************

use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear

* Keep P6C
keep if ((year == 2016 & (month == 1 | month == 2 | month == 3)) | (year == 2015 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010)


* Rename variables to specify they are from P6C
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest  /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P6C
}

save "$data_root/Working/P6C.dta", replace

********************************************* P7C (Oct 2016 - March 2017) *******************************************

use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear

* Keep P7C 
keep if ((year == 2017 & (month == 1 | month == 2 | month == 3)) | (year == 2016 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010)


* Rename variables to specify they are from P7C
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest  /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P7C
}

save "$data_root/Working/P7C.dta", replace

********************************************* P8C (Oct 2017 - March 2018) *******************************************

use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear

* Keep P8C 
keep if ((year == 2018 & (month == 1 | month == 2 | month == 3)) | (year == 2017 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010)


* Rename variables to specify they are from P8C
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest  /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P8C
}

save "$data_root/Working/P8C.dta", replace

********************************************* P9C (Oct 2018 - March 2019) *******************************************

use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear

* Keep P9C 
keep if ((year == 2019 & (month == 1 | month == 2 | month == 3)) | (year == 2018 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010)


* Rename variables to specify they are from P9C
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest  /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P9C
}

save "$data_root/Working/P9C.dta", replace

********************************************* P10C (Oct 2019 - March 2020) *******************************************

use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear

* Keep P10C 
keep if ((year == 2020 & (month == 1 | month == 2 | month == 3)) | (year == 2019 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010)


* Rename variables to specify they are from P10C
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest  /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P10C
}

save "$data_root/Working/P10C.dta", replace

********************************************* P11C (Oct 2020 - March 2021) *******************************************

use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear

* Keep P11C 
keep if ((year == 2021 & (month == 1 | month == 2 | month == 3)) | (year == 2020 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010)


* Rename variables to specify they are from P11C
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest  /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime /// 
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P11C
}

save "$data_root/Working/P11C.dta", replace

********************************************* P1T (Oct 2021 - March 2022) *******************************************

use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear

* Keep P1T 
keep if ((year == 2022 & (month == 1 | month == 2 | month == 3)) | (year == 2021 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010)


* Rename variables to specify they are from P1T
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest  /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P1T
}

save "$data_root/Working/P1T.dta", replace

********************************************* P2T (Oct 2022 - March 2023) *******************************************

use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear

* Keep P2T 
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010)


* Rename variables to specify they are from P2T
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest  /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P2T
}

save "$data_root/Working/P2T.dta", replace

********************************************* P3T (Oct 2023 - March 2024) *******************************************

use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear

* Keep P3T 
keep if ((year == 2024 & (month == 1 | month == 2 | month == 3)) | (year == 2023 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010)


* Rename variables to specify they are from P3T
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest  /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P3T
}

save "$data_root/Working/P3T.dta", replace

********************************************* P4T (Oct 2024 - March 2025) *******************************************

use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear

* Keep P4T 
keep if ((year == 2025 & (month == 1 | month == 2 | month == 3)) | (year == 2024 & (month == 10 | month == 11 | month == 12)))

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010)


* Rename variables to specify they are from P4T
foreach var of varlist unemp_rate log_emp demployed Dunemp ahrswork1 ahrsworkt prop_age_under26 ///
prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest  /// 
prop_south prop_west prop_pacific prop_mixed_other prop_educ_* prop_state* prop_fem other_job new_wrk_acts ahrswork2 fulltime ///
EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P4T
}

save "$data_root/Working/P4T.dta", replace

****************************************************** Merging ****************************************************
use "$data_root/Working/P4T.dta", clear
merge 1:1 occ2010 using "$data_root/Working/P3T.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P2T.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P1T.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P11C.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P10C.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P9C.dta"
label value occ2010
list occ2010 if _merge == 1
* Podiatrists don't appear before between March 2012 and December 2019. Dropping this occupation to have a consistent set of occupations across periods.
drop if _merge == 1
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P8C.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P7C.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P6C.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P5C.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P4C.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P3C.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P2C.dta"
label value occ2010
list occ2010 if _merge == 2
* Podiatrists. Dropping
drop if _merge == 2
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P1C.dta"
label value occ2010
list occ2010 if _merge == 2
* Podiatrists. Dropping
drop if _merge == 2
drop _merge

merge 1:1 occ2010 using "$data_root/Working/OCC2010_from_CPS_2018_exp.dta"
label value occ2010
list occ2010 if _merge == 2
* Podiatrists. Dropping
drop if _merge == 2
drop _merge

save "$data_root/Working/2010_2025_6M_occ2010.dta", replace

*********************************************** Computing Differences *********************************************
use "$data_root/Working/2010_2025_6M_occ2010.dta", clear

* Exposure Differences
foreach model in openai claude {
	gen d_`model'_S2_S1 = `model'2_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S1 = `model'3_occ2010 - `model'1_occ2010
	gen d_`model'_S4_S1 = `model'4_occ2010 - `model'1_occ2010
	gen d_`model'_S5_S1 = `model'5_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S2 = `model'3_occ2010 - `model'2_occ2010
	gen d_`model'_S4_S2 = `model'4_occ2010 - `model'2_occ2010
	gen d_`model'_S5_S2 = `model'5_occ2010 - `model'2_occ2010
	gen d_`model'_S4_S3 = `model'4_occ2010 - `model'3_occ2010
	gen d_`model'_S5_S3 = `model'5_occ2010 - `model'3_occ2010
	gen d_`model'_S5_S4 = `model'5_occ2010 - `model'4_occ2010
}

foreach stage in P1C P2C P3C P4C P5C P6C P7C P8C P9C P10C P11C P1T P2T P3T P4T {
	rename prop_educ_college_or_more_`stage' prop_educ_ba_plus_`stage'
}


* Creating P1C - P3C Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime prop_age_under26 prop_educ_hs_or_less prop_educ_ba_plus EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P1C_P3C = `var'_P3C - `var'_P1C
}

* Creating P2C - P4C Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime prop_age_under26 prop_educ_hs_or_less prop_educ_ba_plus EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P2C_P4C = `var'_P4C - `var'_P2C
}

* Creating P3C - P5C Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime prop_age_under26 prop_educ_hs_or_less prop_educ_ba_plus EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P3C_P5C = `var'_P5C - `var'_P3C
}

* Creating P4C - P6C Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime prop_age_under26 prop_educ_hs_or_less prop_educ_ba_plus EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P4C_P6C = `var'_P6C - `var'_P4C
}

* Creating P5C - P7C Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime prop_age_under26 prop_educ_hs_or_less prop_educ_ba_plus EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P5C_P7C = `var'_P7C - `var'_P5C
}

* Creating P6C - P8C Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime prop_age_under26 prop_educ_hs_or_less prop_educ_ba_plus EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P6C_P8C = `var'_P8C - `var'_P6C
}

* Creating P7C - P9C Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime prop_age_under26 prop_educ_hs_or_less prop_educ_ba_plus EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P7C_P9C = `var'_P9C - `var'_P7C
}

* Creating P8C - P10C Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime prop_age_under26 prop_educ_hs_or_less prop_educ_ba_plus EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P8C_P10C = `var'_P10C - `var'_P8C
}

* Creating P9C - P11C Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime prop_age_under26 prop_educ_hs_or_less prop_educ_ba_plus EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P9C_P11C = `var'_P11C - `var'_P9C
}

* Creating P11C - P2T Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime prop_age_under26 prop_educ_hs_or_less prop_educ_ba_plus EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P10C_P1T = `var'_P1T - `var'_P10C
}

* Creating P11C - P2T Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime prop_age_under26 prop_educ_hs_or_less prop_educ_ba_plus EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P11C_P2T = `var'_P2T - `var'_P11C
}

* Creating P1T - P3T Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime prop_age_under26 prop_educ_hs_or_less prop_educ_ba_plus EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P1T_P3T = `var'_P3T - `var'_P1T
}

* Creating P2T - P4T Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime prop_age_under26 prop_educ_hs_or_less prop_educ_ba_plus EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P2T_P4T = `var'_P4T - `var'_P2T
}

* Creating P3T - P4T Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime prop_age_under26 prop_educ_hs_or_less prop_educ_ba_plus EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P3T_P4T = `var'_P4T - `var'_P3T
}

* Creating P2T - P3T Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_30less prop_age_30to50 prop_age_50plus prop_white prop_black prop_asian prop_native prop_northeast prop_midwest prop_south prop_west prop_pacific prop_mixed_other prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime prop_age_under26 prop_educ_hs_or_less prop_educ_ba_plus EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P2T_P3T = `var'_P3T - `var'_P2T
}

foreach var in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime d_EW_2010_Base d_log_EW_base d_EW_2010_clean d_log_EW_clean {
	foreach stage in P1C_P3C P2C_P4C P3C_P5C P4C_P6C P5C_P7C P6C_P8C P7C_P9C P8C_P10C P9C_P11C P2T_P4T P3T_P4T P2T_P3T {
		replace `var'_`stage' = `var'_`stage' * 100
	}
}

save "$data_root/Working/2010_2025_6M_periods_occ2010.dta", replace

* Checking key outcomes 
sum d_log_emp_P1C_P3C d_log_emp_P2C_P4C d_log_emp_P3C_P5C d_log_emp_P4C_P6C d_log_emp_P5C_P7C d_log_emp_P6C_P8C d_log_emp_P7C_P9C ///
	d_log_emp_P8C_P10C d_log_emp_P9C_P11C d_log_emp_P2T_P4T d_log_emp_P3T_P4T d_log_emp_P2T_P3T, det
sum d_unemp_rate_P1C_P3C d_unemp_rate_P2C_P4C d_unemp_rate_P3C_P5C d_unemp_rate_P4C_P6C d_unemp_rate_P5C_P7C d_unemp_rate_P6C_P8C ///
	d_unemp_rate_P7C_P9C d_unemp_rate_P8C_P10C d_unemp_rate_P9C_P11C d_unemp_rate_P2T_P4T d_unemp_rate_P3T_P4T d_unemp_rate_P2T_P3T, det

*********************************************** Creating Weights *********************************************	
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear

*** P1C ***
label value occ2010
keep if ((year == 2011 & (month == 1 | month == 2 | month == 3)) | (year == 2010 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

insobs 1
replace occ2010 = 1240 if missing(occ2010)
replace count = 0 if missing(count)

insobs 3
replace occ2010 = 5165 if missing(occ2010)
replace count = 0 if missing(count)

drop tag
gen tag = 1
preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

collapse (mean) count, by (occ2010)
rename count freq_wt_P1C
save "$data_root/Working/P1C_wt.dta", replace


*** P2C ***
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear
label value occ2010
keep if ((year == 2012 & (month == 1 | month == 2 | month == 3)) | (year == 2011 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

collapse (mean) count, by (occ2010)
rename count freq_wt_P2C
save "$data_root/Working/P2C_wt.dta", replace

*** P3C ***
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear
label value occ2010
keep if ((year == 2013 & (month == 1 | month == 2 | month == 3)) | (year == 2012 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

collapse (mean) count, by (occ2010)
rename count freq_wt_P3C
save "$data_root/Working/P3C_wt.dta", replace

*** P4C ***
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear
label value occ2010
keep if ((year == 2014 & (month == 1 | month == 2 | month == 3)) | (year == 2013 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

insobs 1
replace occ2010 = 8850 if missing(occ2010)
replace count = 0 if missing(count)

drop tag
gen tag = 1
preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

collapse (mean) count, by (occ2010)
rename count freq_wt_P4C
save "$data_root/Working/P4C_wt.dta", replace

*** P5C ***
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear
label value occ2010
keep if ((year == 2015 & (month == 1 | month == 2 | month == 3)) | (year == 2014 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

insobs 1
replace occ2010 = 1710 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 5910 if missing(occ2010)
replace count = 0 if missing(count)

drop tag
gen tag = 1
preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

collapse (mean) count, by (occ2010)
rename count freq_wt_P5C
save "$data_root/Working/P5C_wt.dta", replace

*** P6C ***
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear
label value occ2010
keep if ((year == 2016 & (month == 1 | month == 2 | month == 3)) | (year == 2015 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

insobs 1
replace occ2010 = 7030 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 5910 if missing(occ2010)
replace count = 0 if missing(count)

drop tag
gen tag = 1
preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

collapse (mean) count, by (occ2010)
rename count freq_wt_P6C
save "$data_root/Working/P6C_wt.dta", replace

*** P7C ***
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear
label value occ2010
keep if ((year == 2017 & (month == 1 | month == 2 | month == 3)) | (year == 2016 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

collapse (mean) count, by (occ2010)
rename count freq_wt_P7C
save "$data_root/Working/P7C_wt.dta", replace

*** P8C ***
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear
label value occ2010
keep if ((year == 2018 & (month == 1 | month == 2 | month == 3)) | (year == 2017 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

insobs 1
replace occ2010 = 3200 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 8330 if missing(occ2010)
replace count = 0 if missing(count)

insobs 2
replace occ2010 = 8420 if missing(occ2010)
replace count = 0 if missing(count)

drop tag
gen tag = 1
preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

collapse (mean) count, by (occ2010)
rename count freq_wt_P8C
save "$data_root/Working/P8C_wt.dta", replace

*** P9C ***
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear
label value occ2010
keep if ((year == 2019 & (month == 1 | month == 2 | month == 3)) | (year == 2018 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

collapse (mean) count, by (occ2010)
rename count freq_wt_P9C
save "$data_root/Working/P9C_wt.dta", replace

*** P10C ***
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear
label value occ2010
keep if ((year == 2020 & (month == 1 | month == 2 | month == 3)) | (year == 2019 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

insobs 3
replace occ2010 = 3120 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 6740 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 7030 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 7850 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 8330 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 8910 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 8940 if missing(occ2010)
replace count = 0 if missing(count)

drop tag
gen tag = 1
preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

collapse (mean) count, by (occ2010)
rename count freq_wt_P10C
save "$data_root/Working/P10C_wt.dta", replace

*** P11C ***
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear
label value occ2010
keep if ((year == 2021 & (month == 1 | month == 2 | month == 3)) | (year == 2020 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

insobs 1
replace occ2010 = 2740 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 5500 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 8010 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 8850 if missing(occ2010)
replace count = 0 if missing(count)


drop tag
gen tag = 1
preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

collapse (mean) count, by (occ2010)
rename count freq_wt_P11C
save "$data_root/Working/P11C_wt.dta", replace

*** P1T ***
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear
label value occ2010
keep if ((year == 2022 & (month == 1 | month == 2 | month == 3)) | (year == 2021 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

insobs 1
replace occ2010 = 3120 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 5010 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 7030 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 8250 if missing(occ2010)
replace count = 0 if missing(count)

insobs 3
replace occ2010 = 8850 if missing(occ2010)
replace count = 0 if missing(count)

insobs 3
replace occ2010 = 8910 if missing(occ2010)
replace count = 0 if missing(count)

insobs 2
replace occ2010 = 8940 if missing(occ2010)
replace count = 0 if missing(count)


drop tag
gen tag = 1
preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

collapse (mean) count, by (occ2010)
rename count freq_wt_P1T
save "$data_root/Working/P1T_wt.dta", replace

*** P2T ***
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear
label value occ2010
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

insobs 1
replace occ2010 = 510 if missing(occ2010)
replace count = 0 if missing(count)

insobs 2
replace occ2010 = 2740 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 5910 if missing(occ2010)
replace count = 0 if missing(count)

insobs 2
replace occ2010 = 8010 if missing(occ2010)
replace count = 0 if missing(count)

insobs 2
replace occ2010 = 8330 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 8730 if missing(occ2010)
replace count = 0 if missing(count)

insobs 3
replace occ2010 = 8910 if missing(occ2010)
replace count = 0 if missing(count)


drop tag
gen tag = 1
preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

collapse (mean) count, by (occ2010)
rename count freq_wt_P2T
save "$data_root/Working/P2T_wt.dta", replace

*** P3T ***
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear
label value occ2010
keep if ((year == 2024 & (month == 1 | month == 2 | month == 3)) | (year == 2023 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

insobs 1
replace occ2010 = 510 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 1710 if missing(occ2010)
replace count = 0 if missing(count)

insobs 4
replace occ2010 = 3900 if missing(occ2010)
replace count = 0 if missing(count)

insobs 2
replace occ2010 = 5020 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 5910 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 8250 if missing(occ2010)
replace count = 0 if missing(count)

insobs 5
replace occ2010 = 8910 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 8930 if missing(occ2010)
replace count = 0 if missing(count)


drop tag
gen tag = 1
preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

collapse (mean) count, by (occ2010)
rename count freq_wt_P3T
save "$data_root/Working/P3T_wt.dta", replace

*** P4T ***
use "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear
label value occ2010
keep if ((year == 2025 & (month == 1 | month == 2 | month == 3)) | (year == 2024 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

insobs 1
replace occ2010 = 2740 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 1710 if missing(occ2010)
replace count = 0 if missing(count)

insobs 2
replace occ2010 = 3900 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 3120 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 3210 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 7610 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 7730 if missing(occ2010)
replace count = 0 if missing(count)

insobs 2
replace occ2010 = 8010 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 8460 if missing(occ2010)
replace count = 0 if missing(count)

insobs 1
replace occ2010 = 8910 if missing(occ2010)
replace count = 0 if missing(count)


drop tag
gen tag = 1
preserve
collapse (sum) tag, by(occ2010)
count if tag == 6
list occ2010 tag if tag < 6
restore

collapse (mean) count, by (occ2010)
rename count freq_wt_P4T
save "$data_root/Working/P4T_wt.dta", replace

*********************************************** Merging Weights *********************************************	
use "$data_root/Working/P4T_wt.dta", clear
merge 1:1 occ2010 using "$data_root/Working/P3T_wt.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P2T_wt.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P1T_wt.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P11C_wt.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P10C_wt.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P9C_wt.dta"
label value occ2010
list occ2010 if _merge == 1
* Podiatrists don't appear before between March 2012 and December 2019. Dropping this occupation to have a consistent set of occupations across periods.
drop if _merge == 1
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P8C_wt.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P7C_wt.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P6C_wt.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P5C_wt.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P4C_wt.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P3C_wt.dta"
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P2C_wt.dta"
label value occ2010
list occ2010 if _merge == 2
* Podiatrists again.
drop if _merge == 2
drop _merge

merge 1:1 occ2010 using "$data_root/Working/P1C_wt.dta"
list occ2010 if _merge == 2
* Podiatrists again.
drop if _merge == 2
drop _merge

merge 1:1 occ2010 using "$data_root/Working/2010_2025_6M_periods_occ2010.dta"
drop _merge
save "$data_root/Working/2010_2025_6M_wgt_occ2010", replace


**************************************************** Taking Task Indices to OCC2010 Level ***********************************************
*** Routine indices at the 2018 CPS level
use "$data_root/Working/soc_AA_routine.dta", clear
rename cps_code occ

*** Merging
merge 1:1 occ using "$crosswalk_root/crosswalk_occ_to_occ2010_2020_2025.dta"
drop if occ == 0
list occ if _merge == 2
*** Missing task index data for 28 occupations. 15 of these occupations are normal occupations for which the work activity and work context variables used in the creation of these indices was not available (1021, 2755, 3401, 3402, 3515, 3725, 3946, 4840, 60, 6115, 705, 845, 9121, 9141, 9142). The remaining 13 are "all other" occupations, also missing these variables.

drop if _merge == 2
drop _merge
collapse (mean) NR_CA NR_CI RC RM NRMP offshore [aw=_freq], by(occ2010)

*** Check
distinct occ2010
save "$data_root/Cleaned/task_indices_occ2010", replace

*** Only 409 occupations have indices compared to 416 occupations with exposure scores and cps data in every period.
merge 1:1 occ2010 using "$data_root/Working/2010_2025_6M_wgt_occ2010"
label value occ2010
list occ2010 if _merge == 1
* Podiatrists again.
list occ2010 if _merge == 2
*** Missing routine indices for 8 occupations: Financial Analysts, Entertainers and Performers, Sports and Related Workers, All Other, Emergency Medical Technicians and Paramedics, Medical Records and Health Information Technicians, Supervisors, Protective Service Workers, All Other, Sales Representatives, Services, All Other, Fishing and hunting workers, and Taxi Drivers and Chauffeurs. All of these occupations are missing work activites and contexts. 
drop _merge
save "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", replace

**************************************************** Taking Webb Exposure to OCC2010 Level ***********************************************
use "$data_root/webb/final_df_out.dta", clear
rename onetsoccode onet_code
save "$data_root/webb//final_df_out.dta", replace

use "$crosswalk_root/onet_to_cps_crosswalk_cleaned.dta", clear
duplicates tag onet_code soc_code cps_code, generate(tag_exact)
br onet_code soc_code cps_code tag_exact if tag_exact > 0
duplicates drop onet_code soc_code cps_code, force
bysort soc_code cps_code (onet_code): gen dup_check = _N
br onet_code soc_code cps_code dup_check if dup_check > 1

*** Merge with Webb Exposure (ONET-Level) ***
merge m:1 onet_code using "$data_root/webb//final_df_out.dta"
list onet_title if _merge == 1
list index if _merge == 2

*** Lots of unmatched occupations, because Webb scores at at the 2010 ONET level
use "$data_root/webb/final_df_out.dta", clear
rename onet_code onet2010
save "$data_root/webb/final_df_out.dta", replace

*** Importing 2010 ONET to 2019 ONET crosswalk
import delimited "/Users/jdomins2/Desktop/CPS_Work/onet_2010_to_2019_crosswalk.csv", clear
rename v1 onet2010
rename v2 onet2019
rename v3 title2019
drop in 1
merge m:1 onet2010 using "$data_root/webb/final_df_out.dta"
distinct(onet2010) if _merge == 3

preserve
keep if _merge == 3
collapse (mean) agg_pairs ai_score software_score robot_score, by(onet2019)
save "$data_root/webb/crosswalked_occs.dta", replace
restore

keep if _merge == 2
drop onet2019
rename onet2010 onet2019 
append using "$data_root/webb/crosswalked_occs.dta"
distinct(onet2019)
*** Some crosswalked occupations map to occupations that already existed (i.e. an occupation getting aggregated into another occupation)
collapse (mean) agg_pairs ai_score software_score robot_score, by(onet2019)
rename onet2019 onet_code
save "$data_root/webb/onet_2019_scores.dta", replace

use "$crosswalk_root/onet_to_cps_crosswalk_cleaned.dta", clear
duplicates tag onet_code soc_code cps_code, generate(tag_exact)
br onet_code soc_code cps_code tag_exact if tag_exact > 0
duplicates drop onet_code soc_code cps_code, force
bysort soc_code cps_code (onet_code): gen dup_check = _N
br onet_code soc_code cps_code dup_check if dup_check > 1

*** Merge with Webb Exposure (ONET-Level) ***
merge m:1 onet_code using "$data_root/webb/onet_2019_scores.dta"

*** 86 unmatched occupations from the crosswalk; mainly "all other occupations"; other occupations such as "blockchain engineers" likely didn't exist in the 2010 onet system.

drop if _merge == 1

*** Calculate ONET-level weights within each SOC-CPS pair ***
bysort soc_code cps_code (onet_code): gen num_valid_onet_codes = _N
gen onet_weight_valid = 1 / num_valid_onet_codes

*** Calculate onet level weighted Webb scores ***
foreach var in ai_score software_score robot_score {
	gen onet_`var'_wgt = `var' * onet_weight_valid
}

*** Sum ONET-level scores within each SOC-CPS occupation pair to get SOC level scores ***
foreach var in ai_score software_score robot_score  {
        bysort cps_code soc_code (onet_code): gen soc_`var' = sum(onet_`var'_wgt)
}

*** Keep only the last observation within each SOC-CPS group ***
bysort cps_code soc_code (onet_code): keep if _n == _N

*** Calculate SOC-level weights within each CPS category ***
bysort cps_code (soc_code): gen num_soc_codes_valid = _N
egen total_census_employment = total(tot_emp), by(cps_code)
gen soc_weight_valid = tot_emp / total_census_employment
replace soc_weight_valid = 1 if onet_code == "45-3031.00"

*** Calculate SOL level weighted Webb scores ***
foreach var in ai_score software_score robot_score {
	gen sol_`var'_wgt = soc_`var' * soc_weight_valid
}

*** Sum SOC-level scores within each CPS category to get final CPS-level scores ***
foreach var in ai_score software_score robot_score {
        egen cps_`var' = total(sol_`var'_wgt), by(cps_code)
}

bysort cps_code (soc_code): keep if _n == _N
distinct cps_code
rename cps_code occ
drop _merge
destring occ, replace

*** Merging with CPS to OCC2010 crosswalk
merge 1:1 occ using "$crosswalk_root/crosswalk_occ_to_occ2010_2020_2025.dta"

*** We are missing Webb scores for 17 occupations; one of these are individuals without occupational codes; we are also missing scores for counselors and social workers; the remaining 14 are "all other" or "nec" occupations.
drop if _merge == 2
rename cps_ai_score webb_ai
rename cps_software_score webb_software
rename cps_robot_score webb_robot
collapse (mean) webb_ai webb_software webb_robot [aw=_freq], by(occ2010)
merge 1:1 occ2010 using "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta"
br if _merge == 2
drop _merge
*** 3 unmatched occupations for which we have exposure scores and cps data but no Webb measures; all are "all other" occupations
save "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", replace

*** 2SLS Results & Tests for key P4T - P2T outcomes using OpenAI exposure between stages 1 and 3, and all controls and weights used in fully specified models

*** Using Software Exposure

ivreg2 d_log_emp_P2T_P4T (d_openai_S3_S1 = webb_software) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
ivreg2 d_unemp_rate_P2T_P4T (d_openai_S3_S1 = webb_software) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
ivreg2 d_ahrswork1_P2T_P4T (d_openai_S3_S1 = webb_software) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
ivreg2 d_ahrswork2_P2T_P4T (d_openai_S3_S1 = webb_software) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
ivreg2 d_ahrsworkt_P2T_P4T (d_openai_S3_S1 = webb_software) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
ivreg2 d_other_job_P2T_P4T (d_openai_S3_S1 = webb_software) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust

ivreg2 d_fulltime_P2T_P4T (d_openai_S3_S1 = webb_software) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
*** Using Robot Exposure
	
ivreg2 d_log_emp_P2T_P4T (d_openai_S3_S1 = webb_robot) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	

ivreg2 d_unemp_rate_P2T_P4T (d_openai_S3_S1 = webb_robot) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	

ivreg2 d_ahrswork1_P2T_P4T (d_openai_S3_S1 = webb_robot) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
	
ivreg2 d_ahrswork2_P2T_P4T (d_openai_S3_S1 = webb_robot) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
	
ivreg2 d_ahrsworkt_P2T_P4T (d_openai_S3_S1 = webb_robot) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
	
ivreg2 d_other_job_P2T_P4T (d_openai_S3_S1 = webb_robot) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
	
ivreg2 d_fulltime_P2T_P4T (d_openai_S3_S1 = webb_robot) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
*** Both software and robot
	
ivreg2 d_log_emp_P2T_P4T (d_openai_S3_S1 = webb_robot webb_software) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	

ivreg2 d_unemp_rate_P2T_P4T (d_openai_S3_S1 = webb_robot webb_software) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
ivreg2 d_ahrswork1_P2T_P4T (d_openai_S3_S1 = webb_robot webb_software) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
ivreg2 d_ahrswork2_P2T_P4T (d_openai_S3_S1 = webb_robot webb_software) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
ivreg2 d_ahrsworkt_P2T_P4T (d_openai_S3_S1 = webb_robot webb_software) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
ivreg2 d_other_job_P2T_P4T (d_openai_S3_S1 = webb_robot webb_software) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	
ivreg2 d_fulltime_P2T_P4T (d_openai_S3_S1 = webb_robot webb_software) ///
    NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T ///
    prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T ///
    prop_pacific_P2T prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
    prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
    [aweight = freq_wt_P2T], first robust
	


**************************************************** Taking Dingle WFH to OCC2010 Level ***********************************************
import delimited "$data_root/dingle/occupations_workathome.csv", clear
rename onetsoccode onet_code
save "$data_root/dingle/onet_WFH_dingle.dta", replace

use "$crosswalk_root/onet_to_cps_crosswalk_cleaned.dta", clear
duplicates tag onet_code soc_code cps_code, generate(tag_exact)
br onet_code soc_code cps_code tag_exact if tag_exact > 0
duplicates drop onet_code soc_code cps_code, force
bysort soc_code cps_code (onet_code): gen dup_check = _N
br onet_code soc_code cps_code dup_check if dup_check > 1

*** Merge with Webb Exposure (ONET-Level) ***
merge m:1 onet_code using "$data_root/dingle/onet_WFH_dingle.dta"
list onet_code if _merge == 2

use "$data_root/dingle/onet_WFH_dingle.dta", clear
rename onet_code onet2010
save "$data_root/dingle/onet_WFH_dingle.dta", replace


*** Importing 2010 ONET to 2019 ONET crosswalk generated based on unmatched occupations
import delimited "/Users/jdomins2/Desktop/CPS_Work/wfh_onet_2010_to_2019_crosswalk.csv", clear
rename v1 onet2010
rename v2 onet2019
rename v3 title2019
drop in 1
merge m:1 onet2010 using "$data_root/dingle/onet_WFH_dingle.dta"
distinct(onet2010) if _merge == 3

preserve
keep if _merge == 3
collapse (mean) teleworkable, by(onet2019)
save "$data_root/dingle/wfh_crosswalked_occs.dta", replace
restore

keep if _merge == 2
drop onet2019
rename onet2010 onet2019 
append using "$data_root/dingle/wfh_crosswalked_occs.dta"
distinct(onet2019)
*** Some crosswalked occupations map to occupations that already existed (i.e. an occupation getting aggregated into another occupation)
collapse (mean) teleworkable, by(onet2019)
rename onet2019 onet_code
save "$data_root/dingle/wfh_onet_2019_scores.dta", replace

use "$crosswalk_root/onet_to_cps_crosswalk_cleaned.dta", clear
duplicates tag onet_code soc_code cps_code, generate(tag_exact)
br onet_code soc_code cps_code tag_exact if tag_exact > 0
duplicates drop onet_code soc_code cps_code, force
bysort soc_code cps_code (onet_code): gen dup_check = _N
br onet_code soc_code cps_code dup_check if dup_check > 1

*** Merge with Webb Exposure (ONET-Level) ***
merge m:1 onet_code using "$data_root/dingle/wfh_onet_2019_scores.dta"
list onet_title if _merge == 1

*** 82 unmatched occupations from the crosswalk; mainly "all other occupations"; 

drop if _merge == 1

*** Calculate ONET-level weights within each SOC-CPS pair ***
bysort soc_code cps_code (onet_code): gen num_valid_onet_codes = _N
gen onet_weight_valid = 1 / num_valid_onet_codes

*** Calculate onet level weighted Webb scores ***
gen onet_tele_wgt = teleworkable * onet_weight_valid

*** Sum ONET-level scores within each SOC-CPS occupation pair to get SOC level scores ***
bysort cps_code soc_code (onet_code): gen soc_tele = sum(onet_tele_wgt)


*** Keep only the last observation within each SOC-CPS group ***
bysort cps_code soc_code (onet_code): keep if _n == _N

*** Calculate SOC-level weights within each CPS category ***
bysort cps_code (soc_code): gen num_soc_codes_valid = _N
egen total_census_employment = total(tot_emp), by(cps_code)
gen soc_weight_valid = tot_emp / total_census_employment
replace soc_weight_valid = 1 if onet_code == "45-3031.00"

*** Calculate SOL level weighted Webb scores ***
gen sol_tele_wgt = soc_tele * soc_weight_valid

*** Sum SOC-level scores within each CPS category to get final CPS-level scores ***
egen cps_tele = total(sol_tele_wgt), by(cps_code)

bysort cps_code (soc_code): keep if _n == _N
distinct cps_code
rename cps_code occ
drop _merge
destring occ, replace
keep occ cps_title cps_tele
rename cps_tele teleworkable

*** Merging with CPS to OCC2010 crosswalk
merge 1:1 occ using "$crosswalk_root/crosswalk_occ_to_occ2010_2020_2025.dta"
list occ2010 if _merge == 2

*** We are missing Webb scores for 17 occupations; one of these are individuals without occupational codes; we are also missing scores for counselors and social workers; the remaining 14 are "all other" or "nec" occupations.
drop if _merge == 2
collapse (mean) teleworkable [aw=_freq], by(occ2010)
distinct occ2010
merge 1:1 occ2010 using "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta"
br if _merge == 2
*** 3 unmatched occupations for which we have exposure scores and cps data but no Webb measures; all are "all other" occupations
save "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", replace




********************************************************************************************************************
***************************************************** Analysis *****************************************************
********************************************************************************************************************

********************************************** P4T - P2T = β (S2 - S1) ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P2T_P4T_A.txt", keep(d_claude_S2_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P2T_P4T_B.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_C.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_C.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P2T_P4T_C.txt", keep(d_claude_S2_S1) nocons append
}

********************************************** P4T - P2T = β (S2 - S1); G10 ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_A_G10.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_A_G10.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P2T_P4T_A_G10.txt", keep(d_claude_S2_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_B_G10.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_B_G10.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P2T_P4T_B_G10.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_C_G10.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_C_G10.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P2T_P4T_C_G10.txt", keep(d_claude_S2_S1) nocons append
}


********************************************** P4T - P2T = β (S3 - S1) ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_A.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_C.txt", keep(d_claude_S3_S1) nocons append
}

********************************************** P4T - P2T = β (S3 - S1); G10 ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_A_G10.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_A_G10.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_A_G10.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_B_G10.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_B_G10.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_B_G10.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_C_G10.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_C_G10.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P2T_P4T_3_1_C_G10.txt", keep(d_claude_S3_S1) nocons append
}

********************************************** P11C - P9C = β (S3 - S1) ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P9C_P11C d_unemp_rate_P9C_P11C d_ahrswork1_P9C_P11C d_ahrswork2_P9C_P11C d_ahrsworkt_P9C_P11C d_other_job_P9C_P11C d_fulltime_P9C_P11C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 [aweight = freq_wt_P9C], vce(robust)
    
    if "`y'" == "d_log_emp_P9C_P11C" {
        outreg2 using "$export_root/May/txt/5_30/P9C_P11C_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P9C_P11C_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 [aweight = freq_wt_P9C], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P9C_P11C_A.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P9C_P11C d_unemp_rate_P9C_P11C d_ahrswork1_P9C_P11C d_ahrswork2_P9C_P11C d_ahrsworkt_P9C_P11C d_other_job_P9C_P11C d_fulltime_P9C_P11C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_P9C prop_age_50plus_P9C prop_black_P9C ///
        prop_asian_P9C prop_native_P9C prop_mixed_other_P9C prop_pacific_P9C ///
        prop_educ_q1_P9C prop_educ_q2_P9C prop_educ_q3_P9C prop_midwest_P9C ///
        prop_northeast_P9C prop_west_P9C prop_fem_P9C [aweight = freq_wt_P9C], vce(robust)
    
    if "`y'" == "d_log_emp_P9C_P11C" {
        outreg2 using "$export_root/May/txt/5_30/P9C_P11C_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P9C_P11C_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_P9C prop_age_50plus_P9C prop_black_P9C ///
        prop_asian_P9C prop_native_P9C prop_mixed_other_P9C prop_pacific_P9C ///
        prop_educ_q1_P9C prop_educ_q2_P9C prop_educ_q3_P9C prop_midwest_P9C ///
        prop_northeast_P9C prop_west_P9C prop_fem_P9C [aweight = freq_wt_P9C], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P9C_P11C_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P9C_P11C d_unemp_rate_P9C_P11C d_ahrswork1_P9C_P11C d_ahrswork2_P9C_P11C d_ahrsworkt_P9C_P11C d_other_job_P9C_P11C d_fulltime_P9C_P11C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P9C prop_age_50plus_P9C prop_black_P9C ///
        prop_asian_P9C prop_native_P9C prop_mixed_other_P9C prop_pacific_P9C ///
        prop_educ_q1_P9C prop_educ_q2_P9C prop_educ_q3_P9C prop_midwest_P9C ///
        prop_northeast_P9C prop_west_P9C prop_fem_P9C [aweight = freq_wt_P9C], vce(robust)
    
    if "`y'" == "d_log_emp_P9C_P11C" {
        outreg2 using "$export_root/May/txt/5_30/P9C_P11C_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P9C_P11C_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P9C prop_age_50plus_P9C prop_black_P9C ///
        prop_asian_P9C prop_native_P9C prop_mixed_other_P9C prop_pacific_P9C ///
        prop_educ_q1_P9C prop_educ_q2_P9C prop_educ_q3_P9C prop_midwest_P9C ///
        prop_northeast_P9C prop_west_P9C prop_fem_P9C [aweight = freq_wt_P9C], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P9C_P11C_C.txt", keep(d_claude_S3_S1) nocons append
}

********************************************** P10C - P8C = β (S3 - S1) ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P8C_P10C d_unemp_rate_P8C_P10C d_ahrswork1_P8C_P10C d_ahrswork2_P8C_P10C d_ahrsworkt_P8C_P10C d_other_job_P8C_P10C d_fulltime_P8C_P10C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 [aweight = freq_wt_P8C], vce(robust)
    
    if "`y'" == "d_log_emp_P8C_P10C" {
        outreg2 using "$export_root/May/txt/5_30/P8C_P10C_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P8C_P10C_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 [aweight = freq_wt_P8C], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P8C_P10C_A.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P8C_P10C d_unemp_rate_P8C_P10C d_ahrswork1_P8C_P10C d_ahrswork2_P8C_P10C d_ahrsworkt_P8C_P10C d_other_job_P8C_P10C d_fulltime_P8C_P10C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_P8C prop_age_50plus_P8C prop_black_P8C ///
        prop_asian_P8C prop_native_P8C prop_mixed_other_P8C prop_pacific_P8C ///
        prop_educ_q1_P8C prop_educ_q2_P8C prop_educ_q3_P8C prop_midwest_P8C ///
        prop_northeast_P8C prop_west_P8C prop_fem_P8C [aweight = freq_wt_P8C], vce(robust)
    
    if "`y'" == "d_log_emp_P8C_P10C" {
        outreg2 using "$export_root/May/txt/5_30/P8C_P10C_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P8C_P10C_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_P8C prop_age_50plus_P8C prop_black_P8C ///
        prop_asian_P8C prop_native_P8C prop_mixed_other_P8C prop_pacific_P8C ///
        prop_educ_q1_P8C prop_educ_q2_P8C prop_educ_q3_P8C prop_midwest_P8C ///
        prop_northeast_P8C prop_west_P8C prop_fem_P8C [aweight = freq_wt_P8C], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P8C_P10C_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P8C_P10C d_unemp_rate_P8C_P10C d_ahrswork1_P8C_P10C d_ahrswork2_P8C_P10C d_ahrsworkt_P8C_P10C d_other_job_P8C_P10C d_fulltime_P8C_P10C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P8C prop_age_50plus_P8C prop_black_P8C ///
        prop_asian_P8C prop_native_P8C prop_mixed_other_P8C prop_pacific_P8C ///
        prop_educ_q1_P8C prop_educ_q2_P8C prop_educ_q3_P8C prop_midwest_P8C ///
        prop_northeast_P8C prop_west_P8C prop_fem_P8C [aweight = freq_wt_P8C], vce(robust)
    
    if "`y'" == "d_log_emp_P8C_P10C" {
        outreg2 using "$export_root/May/txt/5_30/P8C_P10C_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P8C_P10C_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P8C prop_age_50plus_P8C prop_black_P8C ///
        prop_asian_P8C prop_native_P8C prop_mixed_other_P8C prop_pacific_P8C ///
        prop_educ_q1_P8C prop_educ_q2_P8C prop_educ_q3_P8C prop_midwest_P8C ///
        prop_northeast_P8C prop_west_P8C prop_fem_P8C [aweight = freq_wt_P8C], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P8C_P10C_C.txt", keep(d_claude_S3_S1) nocons append
}

********************************************** P4T - P2T = β (S4 - S2) ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S4_S2 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_4_2_A.txt", keep(d_openai_S4_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_4_2_A.txt", keep(d_openai_S4_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S2 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P2T_P4T_4_2_A.txt", keep(d_claude_S4_S2) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S4_S2 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_4_2_B.txt", keep(d_openai_S4_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_4_2_B.txt", keep(d_openai_S4_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S2 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P2T_P4T_4_2_B.txt", keep(d_claude_S4_S2) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S4_S2 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_4_2_C.txt", keep(d_openai_S4_S2) nocons replace
    }
    else {
        outreg2 using "$export_root/May/txt/5_30/P2T_P4T_4_2_C.txt", keep(d_openai_S4_S2) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S4_S2 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/May/txt/5_30/P2T_P4T_4_2_C.txt", keep(d_claude_S4_S2) nocons append
}


********************************************** P1C - P3C = β (S3 - S1) ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P1C_P3C d_unemp_rate_P1C_P3C d_ahrswork1_P1C_P3C d_ahrswork2_P1C_P3C d_ahrsworkt_P1C_P3C d_other_job_P1C_P3C d_fulltime_P1C_P3C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 [aweight = freq_wt_P1C], vce(robust)
    
    if "`y'" == "d_log_emp_P1C_P3C" {
        outreg2 using "$export_root/June/txt/6_10/P1C_P3C_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P1C_P3C_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 [aweight = freq_wt_P1C], vce(robust)
	outreg2 using "$export_root/June/txt/6_10/P1C_P3C_A.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P1C_P3C d_unemp_rate_P1C_P3C d_ahrswork1_P1C_P3C d_ahrswork2_P1C_P3C d_ahrsworkt_P1C_P3C d_other_job_P1C_P3C d_fulltime_P1C_P3C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_P1C prop_age_50plus_P1C prop_black_P1C ///
        prop_asian_P1C prop_native_P1C prop_mixed_other_P1C prop_pacific_P1C ///
        prop_educ_q1_P1C prop_educ_q2_P1C prop_educ_q3_P1C prop_midwest_P1C ///
        prop_northeast_P1C prop_west_P1C prop_fem_P1C [aweight = freq_wt_P1C], vce(robust)
    
    if "`y'" == "d_log_emp_P1C_P3C" {
        outreg2 using "$export_root/June/txt/6_10/P1C_P3C_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P1C_P3C_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_P1C prop_age_50plus_P1C prop_black_P1C ///
        prop_asian_P1C prop_native_P1C prop_mixed_other_P1C prop_pacific_P1C ///
        prop_educ_q1_P1C prop_educ_q2_P1C prop_educ_q3_P1C prop_midwest_P1C ///
        prop_northeast_P1C prop_west_P1C prop_fem_P1C [aweight = freq_wt_P1C], vce(robust)
	outreg2 using "$export_root/June/txt/6_10/P1C_P3C_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P1C_P3C d_unemp_rate_P1C_P3C d_ahrswork1_P1C_P3C d_ahrswork2_P1C_P3C d_ahrsworkt_P1C_P3C d_other_job_P1C_P3C d_fulltime_P1C_P3C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P1C prop_age_50plus_P1C prop_black_P1C ///
        prop_asian_P1C prop_native_P1C prop_mixed_other_P1C prop_pacific_P1C ///
        prop_educ_q1_P1C prop_educ_q2_P1C prop_educ_q3_P1C prop_midwest_P1C ///
        prop_northeast_P1C prop_west_P1C prop_fem_P1C [aweight = freq_wt_P1C], vce(robust)
    
    if "`y'" == "d_log_emp_P1C_P3C" {
        outreg2 using "$export_root/June/txt/6_10/P1C_P3C_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P1C_P3C_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P1C prop_age_50plus_P1C prop_black_P1C ///
        prop_asian_P1C prop_native_P1C prop_mixed_other_P1C prop_pacific_P1C ///
        prop_educ_q1_P1C prop_educ_q2_P1C prop_educ_q3_P1C prop_midwest_P1C ///
        prop_northeast_P1C prop_west_P1C prop_fem_P1C [aweight = freq_wt_P1C], vce(robust)
	outreg2 using "$export_root/June/txt/6_10/P1C_P3C_C.txt", keep(d_claude_S3_S1) nocons append
}

********************************************** P2C - P4C = β (S3 - S1) ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2C_P4C d_unemp_rate_P2C_P4C d_ahrswork1_P2C_P4C d_ahrswork2_P2C_P4C d_ahrsworkt_P2C_P4C d_other_job_P2C_P4C d_fulltime_P2C_P4C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 [aweight = freq_wt_P2C], vce(robust)
    
    if "`y'" == "d_log_emp_P2C_P4C" {
        outreg2 using "$export_root/June/txt/6_10/P2C_P4C_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P2C_P4C_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 [aweight = freq_wt_P2C], vce(robust)
	outreg2 using "$export_root/June/txt/6_10/P2C_P4C_A.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2C_P4C d_unemp_rate_P2C_P4C d_ahrswork1_P2C_P4C d_ahrswork2_P2C_P4C d_ahrsworkt_P2C_P4C d_other_job_P2C_P4C d_fulltime_P2C_P4C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_P2C prop_age_50plus_P2C prop_black_P2C ///
        prop_asian_P2C prop_native_P2C prop_mixed_other_P2C prop_pacific_P2C ///
        prop_educ_q1_P2C prop_educ_q2_P2C prop_educ_q3_P2C prop_midwest_P2C ///
        prop_northeast_P2C prop_west_P2C prop_fem_P2C [aweight = freq_wt_P2C], vce(robust)
    
    if "`y'" == "d_log_emp_P2C_P4C" {
        outreg2 using "$export_root/June/txt/6_10/P2C_P4C_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P2C_P4C_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_P2C prop_age_50plus_P2C prop_black_P2C ///
        prop_asian_P2C prop_native_P2C prop_mixed_other_P2C prop_pacific_P2C ///
        prop_educ_q1_P2C prop_educ_q2_P2C prop_educ_q3_P2C prop_midwest_P2C ///
        prop_northeast_P2C prop_west_P2C prop_fem_P2C [aweight = freq_wt_P2C], vce(robust)
	outreg2 using "$export_root/June/txt/6_10/P2C_P4C_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2C_P4C d_unemp_rate_P2C_P4C d_ahrswork1_P2C_P4C d_ahrswork2_P2C_P4C d_ahrsworkt_P2C_P4C d_other_job_P2C_P4C d_fulltime_P2C_P4C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2C prop_age_50plus_P2C prop_black_P2C ///
        prop_asian_P2C prop_native_P2C prop_mixed_other_P2C prop_pacific_P2C ///
        prop_educ_q1_P2C prop_educ_q2_P2C prop_educ_q3_P2C prop_midwest_P2C ///
        prop_northeast_P2C prop_west_P2C prop_fem_P2C [aweight = freq_wt_P2C], vce(robust)
    
    if "`y'" == "d_log_emp_P2C_P4C" {
        outreg2 using "$export_root/June/txt/6_10/P2C_P4C_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P2C_P4C_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2C prop_age_50plus_P2C prop_black_P2C ///
        prop_asian_P2C prop_native_P2C prop_mixed_other_P2C prop_pacific_P2C ///
        prop_educ_q1_P2C prop_educ_q2_P2C prop_educ_q3_P2C prop_midwest_P2C ///
        prop_northeast_P2C prop_west_P2C prop_fem_P2C [aweight = freq_wt_P2C], vce(robust)
	outreg2 using "$export_root/June/txt/6_10/P2C_P4C_C.txt", keep(d_claude_S3_S1) nocons append
}

********************************************** P5C - P3C = β (S3 - S1) ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P3C_P5C d_unemp_rate_P3C_P5C d_ahrswork1_P3C_P5C d_ahrswork2_P3C_P5C d_ahrsworkt_P3C_P5C d_other_job_P3C_P5C d_fulltime_P3C_P5C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 [aweight = freq_wt_P3C], vce(robust)
    
    if "`y'" == "d_log_emp_P3C_P5C" {
        outreg2 using "$export_root/June/txt/6_10/P3C_P5C_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P3C_P5C_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 [aweight = freq_wt_P3C], vce(robust)
	outreg2 using "$export_root/June/txt/6_10/P3C_P5C_A.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P3C_P5C d_unemp_rate_P3C_P5C d_ahrswork1_P3C_P5C d_ahrswork2_P3C_P5C d_ahrsworkt_P3C_P5C d_other_job_P3C_P5C d_fulltime_P3C_P5C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_P3C prop_age_50plus_P3C prop_black_P3C ///
        prop_asian_P3C prop_native_P3C prop_mixed_other_P3C prop_pacific_P3C ///
        prop_educ_q1_P3C prop_educ_q2_P3C prop_educ_q3_P3C prop_midwest_P3C ///
        prop_northeast_P3C prop_west_P3C prop_fem_P3C [aweight = freq_wt_P3C], vce(robust)
    
    if "`y'" == "d_log_emp_P3C_P5C" {
        outreg2 using "$export_root/June/txt/6_10/P3C_P5C_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P3C_P5C_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_P3C prop_age_50plus_P3C prop_black_P3C ///
        prop_asian_P3C prop_native_P3C prop_mixed_other_P3C prop_pacific_P3C ///
        prop_educ_q1_P3C prop_educ_q2_P3C prop_educ_q3_P3C prop_midwest_P3C ///
        prop_northeast_P3C prop_west_P3C prop_fem_P3C [aweight = freq_wt_P3C], vce(robust)
	outreg2 using "$export_root/June/txt/6_10/P3C_P5C_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P3C_P5C d_unemp_rate_P3C_P5C d_ahrswork1_P3C_P5C d_ahrswork2_P3C_P5C d_ahrsworkt_P3C_P5C d_other_job_P3C_P5C d_fulltime_P3C_P5C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P3C prop_age_50plus_P3C prop_black_P3C ///
        prop_asian_P3C prop_native_P3C prop_mixed_other_P3C prop_pacific_P3C ///
        prop_educ_q1_P3C prop_educ_q2_P3C prop_educ_q3_P3C prop_midwest_P3C ///
        prop_northeast_P3C prop_west_P3C prop_fem_P3C [aweight = freq_wt_P3C], vce(robust)
    
    if "`y'" == "d_log_emp_P3C_P5C" {
        outreg2 using "$export_root/June/txt/6_10/P3C_P5C_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P3C_P5C_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P3C prop_age_50plus_P3C prop_black_P3C ///
        prop_asian_P3C prop_native_P3C prop_mixed_other_P3C prop_pacific_P3C ///
        prop_educ_q1_P3C prop_educ_q2_P3C prop_educ_q3_P3C prop_midwest_P3C ///
        prop_northeast_P3C prop_west_P3C prop_fem_P3C [aweight = freq_wt_P3C], vce(robust)
	outreg2 using "$export_root/June/txt/6_10/P3C_P5C_C.txt", keep(d_claude_S3_S1) nocons append
}

********************************************** P6C - P4C = β (S3 - S1) ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P4C_P6C d_unemp_rate_P4C_P6C d_ahrswork1_P4C_P6C d_ahrswork2_P4C_P6C d_ahrsworkt_P4C_P6C d_other_job_P4C_P6C d_fulltime_P4C_P6C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 [aweight = freq_wt_P4C], vce(robust)
    
    if "`y'" == "d_log_emp_P4C_P6C" {
        outreg2 using "$export_root/June/txt/6_10/P6C_P4C_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P6C_P4C_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 [aweight = freq_wt_P4C], vce(robust)
	outreg2 using "$export_root/June/txt/6_10/P6C_P4C_A.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P4C_P6C d_unemp_rate_P4C_P6C d_ahrswork1_P4C_P6C d_ahrswork2_P4C_P6C d_ahrsworkt_P4C_P6C d_other_job_P4C_P6C d_fulltime_P4C_P6C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_P4C prop_age_50plus_P4C prop_black_P4C ///
        prop_asian_P4C prop_native_P4C prop_mixed_other_P4C prop_pacific_P4C ///
        prop_educ_q1_P4C prop_educ_q2_P4C prop_educ_q3_P4C prop_midwest_P4C ///
        prop_northeast_P4C prop_west_P4C prop_fem_P4C [aweight = freq_wt_P4C], vce(robust)
    
    if "`y'" == "d_log_emp_P4C_P6C" {
        outreg2 using "$export_root/June/txt/6_10/P6C_P4C_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P6C_P4C_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_P4C prop_age_50plus_P4C prop_black_P4C ///
        prop_asian_P4C prop_native_P4C prop_mixed_other_P4C prop_pacific_P4C ///
        prop_educ_q1_P4C prop_educ_q2_P4C prop_educ_q3_P4C prop_midwest_P4C ///
        prop_northeast_P4C prop_west_P4C prop_fem_P4C [aweight = freq_wt_P4C], vce(robust)
	outreg2 using "$export_root/June/txt/6_10/P6C_P4C_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P4C_P6C d_unemp_rate_P4C_P6C d_ahrswork1_P4C_P6C d_ahrswork2_P4C_P6C d_ahrsworkt_P4C_P6C d_other_job_P4C_P6C d_fulltime_P4C_P6C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P4C prop_age_50plus_P4C prop_black_P4C ///
        prop_asian_P4C prop_native_P4C prop_mixed_other_P4C prop_pacific_P4C ///
        prop_educ_q1_P4C prop_educ_q2_P4C prop_educ_q3_P4C prop_midwest_P4C ///
        prop_northeast_P4C prop_west_P4C prop_fem_P4C [aweight = freq_wt_P4C], vce(robust)
    
    if "`y'" == "d_log_emp_P4C_P6C" {
        outreg2 using "$export_root/June/txt/6_10/P6C_P4C_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P6C_P4C_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P4C prop_age_50plus_P4C prop_black_P4C ///
        prop_asian_P4C prop_native_P4C prop_mixed_other_P4C prop_pacific_P4C ///
        prop_educ_q1_P4C prop_educ_q2_P4C prop_educ_q3_P4C prop_midwest_P4C ///
        prop_northeast_P4C prop_west_P4C prop_fem_P4C [aweight = freq_wt_P4C], vce(robust)
	outreg2 using "$export_root/June/txt/6_10/P6C_P4C_C.txt", keep(d_claude_S3_S1) nocons append
}

********************************************** P7C - P5C = β (S3 - S1) ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P5C_P7C d_unemp_rate_P5C_P7C d_ahrswork1_P5C_P7C d_ahrswork2_P5C_P7C d_ahrsworkt_P5C_P7C d_other_job_P5C_P7C d_fulltime_P5C_P7C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 [aweight = freq_wt_P5C], vce(robust)
    
    if "`y'" == "d_log_emp_P5C_P7C" {
        outreg2 using "$export_root/June/txt/6_10/P5C_P7C_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P5C_P7C_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 [aweight = freq_wt_P5C], vce(robust)
	outreg2 using "$export_root/June/txt/6_10/P5C_P7C_A.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P5C_P7C d_unemp_rate_P5C_P7C d_ahrswork1_P5C_P7C d_ahrswork2_P5C_P7C d_ahrsworkt_P5C_P7C d_other_job_P5C_P7C d_fulltime_P5C_P7C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_P5C prop_age_50plus_P5C prop_black_P5C ///
        prop_asian_P5C prop_native_P5C prop_mixed_other_P5C prop_pacific_P5C ///
        prop_educ_q1_P5C prop_educ_q2_P5C prop_educ_q3_P5C prop_midwest_P5C ///
        prop_northeast_P5C prop_west_P5C prop_fem_P5C [aweight = freq_wt_P5C], vce(robust)
    
    if "`y'" == "d_log_emp_P5C_P7C" {
        outreg2 using "$export_root/June/txt/6_10/P5C_P7C_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P5C_P7C_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_P5C prop_age_50plus_P5C prop_black_P5C ///
        prop_asian_P5C prop_native_P5C prop_mixed_other_P5C prop_pacific_P5C ///
        prop_educ_q1_P5C prop_educ_q2_P5C prop_educ_q3_P5C prop_midwest_P5C ///
        prop_northeast_P5C prop_west_P5C prop_fem_P5C [aweight = freq_wt_P5C], vce(robust)
	outreg2 using "$export_root/June/txt/6_10/P5C_P7C_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P5C_P7C d_unemp_rate_P5C_P7C d_ahrswork1_P5C_P7C d_ahrswork2_P5C_P7C d_ahrsworkt_P5C_P7C d_other_job_P5C_P7C d_fulltime_P5C_P7C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P5C prop_age_50plus_P5C prop_black_P5C ///
        prop_asian_P5C prop_native_P5C prop_mixed_other_P5C prop_pacific_P5C ///
        prop_educ_q1_P5C prop_educ_q2_P5C prop_educ_q3_P5C prop_midwest_P5C ///
        prop_northeast_P5C prop_west_P5C prop_fem_P5C [aweight = freq_wt_P5C], vce(robust)
    
    if "`y'" == "d_log_emp_P5C_P7C" {
        outreg2 using "$export_root/June/txt/6_10/P5C_P7C_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P5C_P7C_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P5C prop_age_50plus_P5C prop_black_P5C ///
        prop_asian_P5C prop_native_P5C prop_mixed_other_P5C prop_pacific_P5C ///
        prop_educ_q1_P5C prop_educ_q2_P5C prop_educ_q3_P5C prop_midwest_P5C ///
        prop_northeast_P5C prop_west_P5C prop_fem_P5C [aweight = freq_wt_P5C], vce(robust)
	outreg2 using "$export_root/June/txt/6_10/P5C_P7C_C.txt", keep(d_claude_S3_S1) nocons append
}


********************************************** P8C - P6C = β (S3 - S1) ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P6C_P8C d_unemp_rate_P6C_P8C d_ahrswork1_P6C_P8C d_ahrswork2_P6C_P8C d_ahrsworkt_P6C_P8C d_other_job_P6C_P8C d_fulltime_P6C_P8C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 [aweight = freq_wt_P6C], vce(robust)
    
    if "`y'" == "d_log_emp_P6C_P8C" {
        outreg2 using "$export_root/June/txt/6_10/P6C_P8C_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P6C_P8C_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
    reg `y' d_claude_S3_S1 [aweight = freq_wt_P6C], vce(robust)
    outreg2 using "$export_root/June/txt/6_10/P6C_P8C_A.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P6C_P8C d_unemp_rate_P6C_P8C d_ahrswork1_P6C_P8C d_ahrswork2_P6C_P8C d_ahrsworkt_P6C_P8C d_other_job_P6C_P8C d_fulltime_P6C_P8C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_P6C prop_age_50plus_P6C prop_black_P6C ///
        prop_asian_P6C prop_native_P6C prop_mixed_other_P6C prop_pacific_P6C ///
        prop_educ_q1_P6C prop_educ_q2_P6C prop_educ_q3_P6C prop_midwest_P6C ///
        prop_northeast_P6C prop_west_P6C prop_fem_P6C [aweight = freq_wt_P6C], vce(robust)
    
    if "`y'" == "d_log_emp_P6C_P8C" {
        outreg2 using "$export_root/June/txt/6_10/P6C_P8C_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P6C_P8C_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
    reg `y' d_claude_S3_S1 prop_age_30to50_P6C prop_age_50plus_P6C prop_black_P6C ///
        prop_asian_P6C prop_native_P6C prop_mixed_other_P6C prop_pacific_P6C ///
        prop_educ_q1_P6C prop_educ_q2_P6C prop_educ_q3_P6C prop_midwest_P6C ///
        prop_northeast_P6C prop_west_P6C prop_fem_P6C [aweight = freq_wt_P6C], vce(robust)
    outreg2 using "$export_root/June/txt/6_10/P6C_P8C_B.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P6C_P8C d_unemp_rate_P6C_P8C d_ahrswork1_P6C_P8C d_ahrswork2_P6C_P8C d_ahrsworkt_P6C_P8C d_other_job_P6C_P8C d_fulltime_P6C_P8C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P6C prop_age_50plus_P6C prop_black_P6C ///
        prop_asian_P6C prop_native_P6C prop_mixed_other_P6C prop_pacific_P6C ///
        prop_educ_q1_P6C prop_educ_q2_P6C prop_educ_q3_P6C prop_midwest_P6C ///
        prop_northeast_P6C prop_west_P6C prop_fem_P6C [aweight = freq_wt_P6C], vce(robust)
    
    if "`y'" == "d_log_emp_P6C_P8C" {
        outreg2 using "$export_root/June/txt/6_10/P6C_P8C_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P6C_P8C_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
    reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P6C prop_age_50plus_P6C prop_black_P6C ///
        prop_asian_P6C prop_native_P6C prop_mixed_other_P6C prop_pacific_P6C ///
        prop_educ_q1_P6C prop_educ_q2_P6C prop_educ_q3_P6C prop_midwest_P6C ///
        prop_northeast_P6C prop_west_P6C prop_fem_P6C [aweight = freq_wt_P6C], vce(robust)
    outreg2 using "$export_root/June/txt/6_10/P6C_P8C_C.txt", keep(d_claude_S3_S1) nocons append
}


********************************************** P9C - P7C = β (S3 - S1) ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P7C_P9C d_unemp_rate_P7C_P9C d_ahrswork1_P7C_P9C d_ahrswork2_P7C_P9C d_ahrsworkt_P7C_P9C d_other_job_P7C_P9C d_fulltime_P7C_P9C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 [aweight = freq_wt_P7C], vce(robust)
    
    if "`y'" == "d_log_emp_P7C_P9C" {
        outreg2 using "$export_root/June/txt/6_10/P7C_P9C_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P7C_P9C_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
    reg `y' d_claude_S3_S1 [aweight = freq_wt_P7C], vce(robust)
    outreg2 using "$export_root/June/txt/6_10/P7C_P9C_A.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P7C_P9C d_unemp_rate_P7C_P9C d_ahrswork1_P7C_P9C d_ahrswork2_P7C_P9C d_ahrsworkt_P7C_P9C d_other_job_P7C_P9C d_fulltime_P7C_P9C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_P7C prop_age_50plus_P7C prop_black_P7C ///
        prop_asian_P7C prop_native_P7C prop_mixed_other_P7C prop_pacific_P7C ///
        prop_educ_q1_P7C prop_educ_q2_P7C prop_educ_q3_P7C prop_midwest_P7C ///
        prop_northeast_P7C prop_west_P7C prop_fem_P7C [aweight = freq_wt_P7C], vce(robust)
    
    if "`y'" == "d_log_emp_P7C_P9C" {
        outreg2 using "$export_root/June/txt/6_10/P7C_P9C_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P7C_P9C_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
    reg `y' d_claude_S3_S1 prop_age_30to50_P7C prop_age_50plus_P7C prop_black_P7C ///
        prop_asian_P7C prop_native_P7C prop_mixed_other_P7C prop_pacific_P7C ///
        prop_educ_q1_P7C prop_educ_q2_P7C prop_educ_q3_P7C prop_midwest_P7C ///
        prop_northeast_P7C prop_west_P7C prop_fem_P7C [aweight = freq_wt_P7C], vce(robust)
    outreg2 using "$export_root/June/txt/6_10/P7C_P9C_B.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P7C_P9C d_unemp_rate_P7C_P9C d_ahrswork1_P7C_P9C d_ahrswork2_P7C_P9C d_ahrsworkt_P7C_P9C d_other_job_P7C_P9C d_fulltime_P7C_P9C
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P7C prop_age_50plus_P7C prop_black_P7C ///
        prop_asian_P7C prop_native_P7C prop_mixed_other_P7C prop_pacific_P7C ///
        prop_educ_q1_P7C prop_educ_q2_P7C prop_educ_q3_P7C prop_midwest_P7C ///
        prop_northeast_P7C prop_west_P7C prop_fem_P7C [aweight = freq_wt_P7C], vce(robust)
    
    if "`y'" == "d_log_emp_P7C_P9C" {
        outreg2 using "$export_root/June/txt/6_10/P7C_P9C_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_10/P7C_P9C_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
    reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P7C prop_age_50plus_P7C prop_black_P7C ///
        prop_asian_P7C prop_native_P7C prop_mixed_other_P7C prop_pacific_P7C ///
        prop_educ_q1_P7C prop_educ_q2_P7C prop_educ_q3_P7C prop_midwest_P7C ///
        prop_northeast_P7C prop_west_P7C prop_fem_P7C [aweight = freq_wt_P7C], vce(robust)
    outreg2 using "$export_root/June/txt/6_10/P7C_P9C_C.txt", keep(d_claude_S3_S1) nocons append
}

**********************************************************************************************************************
********************************************* Adding WFH to Main Results *********************************************
**********************************************************************************************************************

********************************************* P4T - P2T, S2 - S1 *********************************************
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP offshore teleworkable prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/P2T_P4T_A.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/P2T_P4T_A.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP offshore teleworkable prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/P2T_P4T_A.txt", keep(d_claude_S2_S1) nocons append
}

use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP offshore teleworkable prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/P2T_P4T_B.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/P2T_P4T_B.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP offshore teleworkable prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/P2T_P4T_B.txt", keep(d_claude_S2_S1) nocons append
}

********************************************* P4T - P2T, S3 - S1 *********************************************
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore teleworkable prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/P2T_P4T_3_1_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/P2T_P4T_3_1_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore teleworkable prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/P2T_P4T_3_1_A.txt", keep(d_claude_S3_S1) nocons append
}

use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore teleworkable prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/P2T_P4T_3_1_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/P2T_P4T_3_1_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore teleworkable prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/P2T_P4T_3_1_B.txt", keep(d_claude_S3_S1) nocons append
}

********************************************* P4T - P2T, S3 - S1 G10 *********************************************
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore teleworkable prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/P2T_P4T_3_1_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/P2T_P4T_3_1_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore teleworkable prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/P2T_P4T_3_1_A.txt", keep(d_claude_S3_S1) nocons append
}

use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore teleworkable prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/P2T_P4T_3_1_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/P2T_P4T_3_1_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore teleworkable prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/P2T_P4T_3_1_B.txt", keep(d_claude_S3_S1) nocons append
}



**********************************************************************************************************************
************************************************* Heterogeniety ******************************************************
**********************************************************************************************************************

****************************************************** Age ***********************************************************
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

gen x_30less_int_openai = d_openai_S3_S1 * prop_age_30less_P2T
gen x_30less_int_claude = d_claude_S3_S1 * prop_age_30less_P2T

gen x_26less_int_openai = d_openai_S3_S1 * prop_age_under26_P2T
gen x_26less_int_claude = d_claude_S3_S1 * prop_age_under26_P2T
save "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", replace


local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 x_30less_int_openai prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/30less_A.txt", keep(d_openai_S3_S1 x_30less_int_openai) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/30less_A.txt", keep(d_openai_S3_S1 x_30less_int_openai) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 x_30less_int_claude prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/30less_A.txt", keep(d_claude_S3_S1 x_30less_int_claude) nocons append
}

use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 x_26less_int_openai prop_age_under26_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/30less_B.txt", keep(d_openai_S3_S1 x_26less_int_openai) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/30less_B.txt", keep(d_openai_S3_S1 x_26less_int_openai) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 x_26less_int_claude prop_age_under26_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_50plus_P2T ///
        prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/30less_B.txt", keep(d_claude_S3_S1 x_26less_int_claude) nocons append
}

****************************************************** Gender ***********************************************************
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear


gen prop_male_P2T = 1 - prop_fem_P2T
gen male_int_openai = d_openai_S3_S1 * prop_male_P2T
gen male_int_claude = d_claude_S3_S1 * prop_male_P2T

save "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", replace

local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 male_int_openai prop_male_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/male_A.txt", keep(d_openai_S3_S1 male_int_openai) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/male_A.txt", keep(d_openai_S3_S1 male_int_openai) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 male_int_claude prop_male_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T ///
        prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/male_A.txt", keep(d_claude_S3_S1 male_int_claude) nocons append
}

****************************************************** Region ***********************************************************
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

gen west_int_openai = d_openai_S3_S1 * prop_west_P2T
gen west_int_claude = d_claude_S3_S1 * prop_west_P2T

gen south_int_openai = d_openai_S3_S1 * prop_south_P2T
gen south_int_claude = d_claude_S3_S1 * prop_south_P2T

gen midwest_int_openai = d_openai_S3_S1 * prop_midwest_P2T
gen midwest_int_claude = d_claude_S3_S1 * prop_midwest_P2T

gen northeast_int_openai = d_openai_S3_S1 * prop_northeast_P2T
gen northeast_int_claude = d_claude_S3_S1 * prop_northeast_P2T

save "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", replace

*** West
local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 west_int_openai prop_west_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/west_A.txt", keep(d_openai_S3_S1 west_int_openai) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/west_A.txt", keep(d_openai_S3_S1 west_int_openai) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 west_int_claude prop_west_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T ///
        prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/west_A.txt", keep(d_claude_S3_S1 west_int_claude) nocons append
}

*** Midwest
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear
local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 midwest_int_openai prop_midwest_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T ///
        prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/midwest_A.txt", keep(d_openai_S3_S1 midwest_int_openai) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/midwest_A.txt", keep(d_openai_S3_S1 midwest_int_openai) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 midwest_int_claude prop_midwest_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore ///
        prop_age_30to50_P2T prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/midwest_A.txt", keep(d_claude_S3_S1 midwest_int_claude) nocons append
}

*** Northeast
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear
local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 northeast_int_openai prop_northeast_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T ///
        prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_west_P2T ///
        prop_midwest_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/northeast_A.txt", keep(d_openai_S3_S1 northeast_int_openai) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/northeast_A.txt", keep(d_openai_S3_S1 northeast_int_openai) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 northeast_int_claude prop_northeast_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore ///
        prop_age_30to50_P2T prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_west_P2T ///
        prop_midwest_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/northeast_A.txt", keep(d_claude_S3_S1 northeast_int_claude) nocons append
}

*** South
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear
local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 south_int_openai prop_south_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T ///
        prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_west_P2T ///
        prop_midwest_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/south_A.txt", keep(d_openai_S3_S1 south_int_openai) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/south_A.txt", keep(d_openai_S3_S1 south_int_openai) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 south_int_claude prop_south_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore ///
        prop_age_30to50_P2T prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_west_P2T ///
        prop_midwest_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/south_A.txt", keep(d_claude_S3_S1 south_int_claude) nocons append
}

****************************************************** Race ***********************************************************
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

gen white_int_openai = d_openai_S3_S1 * prop_white_P2T
gen white_int_claude = d_claude_S3_S1 * prop_white_P2T

gen black_int_openai = d_openai_S3_S1 * prop_black_P2T
gen black_int_claude = d_claude_S3_S1 * prop_black_P2T

gen asian_int_openai = d_openai_S3_S1 * prop_asian_P2T
gen asian_int_claude = d_claude_S3_S1 * prop_asian_P2T


save "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", replace

*** White
local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 white_int_openai prop_white_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/white_A.txt", keep(d_openai_S3_S1 white_int_openai) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/white_A.txt", keep(d_openai_S3_S1 white_int_openai) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 white_int_claude prop_white_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/white_A.txt", keep(d_claude_S3_S1 white_int_claude) nocons append
}

*** Black
local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 black_int_openai prop_black_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/black_A.txt", keep(d_openai_S3_S1 black_int_openai) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/black_A.txt", keep(d_openai_S3_S1 black_int_openai) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 black_int_claude prop_black_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/black_A.txt", keep(d_claude_S3_S1 black_int_claude) nocons append
}

*** Asian
local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 asian_int_openai prop_asian_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T ///
        prop_black_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/asian_A.txt", keep(d_openai_S3_S1 asian_int_openai) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/asian_A.txt", keep(d_openai_S3_S1 asian_int_openai) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 asian_int_claude prop_asian_P2T prop_age_30less_P2T NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T ///
        prop_black_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/asian_A.txt", keep(d_claude_S3_S1 asian_int_claude) nocons append
}

****************************************************** Educ ***********************************************************
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

gen lesshs_int_openai = d_openai_S3_S1 * prop_educ_q1_P2T
gen lesshs_int_claude = d_claude_S3_S1 * prop_educ_q1_P2T

gen hs_or_less_int_openai = d_openai_S3_S1 * prop_educ_hs_or_less_P2T
gen hs_or_less_int_claude = d_claude_S3_S1 * prop_educ_hs_or_less_P2T

gen ba_plus_int_openai = d_openai_S3_S1 * prop_educ_ba_plus_P2T
gen ba_plus_int_claude = d_claude_S3_S1 * prop_educ_ba_plus_P2T

gen moreba_int_openai = d_openai_S3_S1 * prop_educ_q4_P2T
gen moreba_int_claude = d_claude_S3_S1 * prop_educ_q4_P2T

save "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", replace

*** Less than HS
local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 lesshs_int_openai NR_CA NR_CI RC RM NRMP offshore prop_age_30less_P2T prop_age_30to50_P2T ///
        prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/lesshs_A.txt", keep(d_openai_S3_S1 lesshs_int_openai) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/lesshs_A.txt", keep(d_openai_S3_S1 lesshs_int_openai) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 lesshs_int_claude NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_30less_P2T ///
        prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/lesshs_A.txt", keep(d_claude_S3_S1 lesshs_int_claude) nocons append
}

*** HS or less
local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 hs_or_less_int_openai NR_CA NR_CI RC RM NRMP offshore prop_age_30less_P2T prop_age_30to50_P2T ///
        prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/hs_or_less_A.txt", keep(d_openai_S3_S1 hs_or_less_int_openai) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/hs_or_less_A.txt", keep(d_openai_S3_S1 hs_or_less_int_openai) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 hs_or_less_int_claude NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_30less_P2T ///
        prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/hs_or_less_A.txt", keep(d_claude_S3_S1 hs_or_less_int_claude) nocons append
}

*** BA Plus
local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 ba_plus_int_openai NR_CA NR_CI RC RM NRMP offshore prop_age_30less_P2T prop_age_30to50_P2T ///
        prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/ba_plus_A.txt", keep(d_openai_S3_S1 ba_plus_int_openai) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/ba_plus_A.txt", keep(d_openai_S3_S1 ba_plus_int_openai) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 ba_plus_int_claude NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_30less_P2T ///
        prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/ba_plus_A.txt", keep(d_claude_S3_S1 ba_plus_int_claude) nocons append
}

*** More than BA
local outcomes d_log_emp_P2T_P4T d_unemp_rate_P2T_P4T d_ahrswork1_P2T_P4T d_ahrswork2_P2T_P4T d_ahrsworkt_P2T_P4T d_other_job_P2T_P4T d_fulltime_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 moreba_int_openai NR_CA NR_CI RC RM NRMP offshore prop_age_30less_P2T prop_age_30to50_P2T ///
        prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_11/moreba_A.txt", keep(d_openai_S3_S1 moreba_int_openai) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_11/moreba_A.txt", keep(d_openai_S3_S1 moreba_int_openai) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 moreba_int_claude NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_30less_P2T ///
        prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_11/moreba_A.txt", keep(d_claude_S3_S1 moreba_int_claude) nocons append
}

****************************************************** Task Indices ***********************************************************
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

reg d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore, vce(robust)
outreg2 using "$export_root/June/txt/6_11/indices_A.txt", nocons replace

reg d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore [aweight = freq_wt_P2T], vce(robust)
outreg2 using "$export_root/June/txt/6_11/indices_B.txt", nocons replace

reg d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_30less_P2T ///
        prop_black_P2T prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T prop_west_P2T ///
        prop_northeast_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
outreg2 using "$export_root/June/txt/6_11/indices_C.txt", nocons replace

use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear
reg d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore, vce(robust)
outreg2 using "$export_root/June/txt/6_11/indices_A.txt", nocons replace

reg d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore [aweight = freq_wt_P2], vce(robust)
outreg2 using "$export_root/June/txt/6_11/indices_B.txt", nocons replace

reg d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_p2 prop_age_30less_p2 ///
        prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 prop_west_p2 ///
        prop_northeast_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
outreg2 using "$export_root/June/txt/6_11/indices_C.txt", nocons replace

use "$data_root/Cleaned/P1_P4_ld_march2025.dta", clear
reg d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore, vce(robust)
outreg2 using "$export_root/June/txt/6_11/indices_C_A.txt", nocons replace

reg d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore [aweight = freq_wt_P2], vce(robust)
outreg2 using "$export_root/June/txt/6_11/indices_C_B.txt", nocons replace

reg d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_p2 prop_age_30less_p2 ///
        prop_black_p2 prop_asian_p2 prop_native_p2 prop_mixed_other_p2 prop_pacific_p2 ///
        prop_educ_q1_p2 prop_educ_q2_p2 prop_educ_q3_p2 prop_midwest_p2 prop_west_p2 ///
        prop_northeast_p2 prop_fem_p2 [aweight = freq_wt_P2], vce(robust)
outreg2 using "$export_root/June/txt/6_11/indices_C_C.txt", nocons replace

********************************************** P3T - P2T = β (S2 - S1); G10 ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P3T d_unemp_rate_P2T_P3T d_ahrswork1_P2T_P3T d_ahrswork2_P2T_P3T d_ahrsworkt_P2T_P3T d_other_job_P2T_P3T d_fulltime_P2T_P3T
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P3T" {
        outreg2 using "$export_root/June/txt/6_12/P3T_P2T_A_G10.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_12/P3T_P2T_A_G10.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_12/P3T_P2T_A_G10.txt", keep(d_claude_S2_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P3T d_unemp_rate_P2T_P3T d_ahrswork1_P2T_P3T d_ahrswork2_P2T_P3T d_ahrsworkt_P2T_P3T d_other_job_P2T_P3T d_fulltime_P2T_P3T
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P3T" {
        outreg2 using "$export_root/June/txt/6_12/P3T_P2T_B_G10.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_12/P3T_P2T_B_G10.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using"$export_root/June/txt/6_12/P3T_P2T_B_G10.txt", keep(d_claude_S2_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_log_emp_P2T_P3T d_unemp_rate_P2T_P3T d_ahrswork1_P2T_P3T d_ahrswork2_P2T_P3T d_ahrsworkt_P2T_P3T d_other_job_P2T_P3T d_fulltime_P2T_P3T
foreach y in `outcomes' {
    reg `y' d_openai_S2_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_log_emp_P2T_P3T" {
        outreg2 using "$export_root/June/txt/6_12/P3T_P2T_C_G10.txt", keep(d_openai_S2_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_12/P3T_P2T_C_G10.txt", keep(d_openai_S2_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S2_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_12/P3T_P2T_C_G10.txt", keep(d_claude_S2_S1) nocons append
	
}

*******************************************************************************************************************
********************************************** Loop for main figure ***********************************************
*******************************************************************************************************************

* Load data
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

* Define outcomes and period diffs
local outcomes d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime

* Each entry is: outcome_period base_period
local specs ///
    P2T_P4T P2T ///
    P1T_P3T P1T ///
    P11C_P2T P11C ///
    P10C_P1T P10C ///
    P9C_P11C P9C ///
    P8C_P10C P8C ///
    P7C_P9C P7C ///
    P6C_P8C P6C ///
    P5C_P7C P5C ///
    P4C_P6C P4C ///
    P3C_P5C P3C ///
    P2C_P4C P2C ///
    P1C_P3C P1C

* Loop over OpenAI
forvalues i = 1(2)25 {
    local p : word `i' of `specs'
    local base : word `=`i'+1' of `specs'

    foreach y in `outcomes' {
        reg `y'_`p' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore ///
            prop_age_30to50_`base' prop_age_50plus_`base' prop_black_`base' ///
            prop_asian_`base' prop_native_`base' prop_mixed_other_`base' prop_pacific_`base' ///
            prop_educ_q1_`base' prop_educ_q2_`base' prop_educ_q3_`base' ///
            prop_midwest_`base' prop_northeast_`base' prop_west_`base' prop_fem_`base' ///
            if freq_wt_`base' >= 10 [aweight = freq_wt_`base'], vce(robust)

        if "`y'" == "d_log_emp" & "`p'" == "P2T_P4T" {
            outreg2 using "$export_root/June/txt/6_12/PanelEstimates_OpenAI.txt", keep(d_openai_S3_S1) nocons replace
        }
        else {
            outreg2 using "$export_root/June/txt/6_12/PanelEstimates_OpenAI.txt", keep(d_openai_S3_S1) nocons append
        }
    }
}

* Loop over Claude
forvalues i = 1(2)25 {
    local p : word `i' of `specs'
    local base : word `=`i'+1' of `specs'

    foreach y in `outcomes' {
        reg `y'_`p' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore ///
            prop_age_30to50_`base' prop_age_50plus_`base' prop_black_`base' ///
            prop_asian_`base' prop_native_`base' prop_mixed_other_`base' prop_pacific_`base' ///
            prop_educ_q1_`base' prop_educ_q2_`base' prop_educ_q3_`base' ///
            prop_midwest_`base' prop_northeast_`base' prop_west_`base' prop_fem_`base' ///
            [aweight = freq_wt_`base'], vce(robust)

        outreg2 using "$export_root/June/txt/6_12/PanelEstimates_Claude.txt", keep(d_claude_S3_S1) nocons append
    }
}


* Load data
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

* Define outcomes and period diffs
local outcomes d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime

* Each entry is: outcome_period base_period
local specs ///
    P2T_P4T P2T ///
    P1T_P3T P1T ///
    P11C_P2T P11C ///
    P10C_P1T P10C ///
    P9C_P11C P9C 


* Loop over OpenAI
forvalues i = 1(2)25 {
    local p : word `i' of `specs'
    local base : word `=`i'+1' of `specs'

    foreach y in `outcomes' {
        reg `y'_`p' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore ///
            prop_age_30to50_`base' prop_age_50plus_`base' prop_black_`base' ///
            prop_asian_`base' prop_native_`base' prop_mixed_other_`base' prop_pacific_`base' ///
            prop_educ_q1_`base' prop_educ_q2_`base' prop_educ_q3_`base' ///
            prop_midwest_`base' prop_northeast_`base' prop_west_`base' prop_fem_`base' ///
            if freq_wt_`base' >= 10 [aweight = freq_wt_`base'], vce(robust)

        if "`y'" == "d_log_emp" & "`p'" == "P2T_P4T" {
            outreg2 using "$export_root/June/txt/6_12/PanelEstimates_OpenAI.txt", keep(d_openai_S3_S1) nocons replace
        }
        else {
            outreg2 using "$export_root/June/txt/6_12/PanelEstimates_OpenAI.txt", keep(d_openai_S3_S1) nocons append
        }
    }
}

* Loop over Claude
forvalues i = 1(2)25 {
    local p : word `i' of `specs'
    local base : word `=`i'+1' of `specs'

    foreach y in `outcomes' {
        reg `y'_`p' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore ///
            prop_age_30to50_`base' prop_age_50plus_`base' prop_black_`base' ///
            prop_asian_`base' prop_native_`base' prop_mixed_other_`base' prop_pacific_`base' ///
            prop_educ_q1_`base' prop_educ_q2_`base' prop_educ_q3_`base' ///
            prop_midwest_`base' prop_northeast_`base' prop_west_`base' prop_fem_`base' ///
            if freq_wt_`base' >= 10 [aweight = freq_wt_`base'], vce(robust)

        outreg2 using "$export_root/June/txt/6_12/PanelEstimates_Claude.txt", keep(d_claude_S3_S1) nocons append
    }
}

* Load data
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

* Define outcomes and exposure difference variables
local outcomes d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime
local exposure_diffs d_openai_S2_S1 d_openai_S3_S1 d_openai_S4_S1 d_openai_S5_S1

* Use the same period and base period for all (P2T_P4T)
local base P2T

* Loop over OpenAI exposure difference measures
foreach exp in `exposure_diffs' {
    foreach y in `outcomes' {
        reg `y'_P2T_P4T `exp' NR_CA NR_CI RC RM NRMP offshore ///
            prop_age_30to50_`base' prop_age_50plus_`base' prop_black_`base' ///
            prop_asian_`base' prop_native_`base' prop_mixed_other_`base' prop_pacific_`base' ///
            prop_educ_q1_`base' prop_educ_q2_`base' prop_educ_q3_`base' ///
            prop_midwest_`base' prop_northeast_`base' prop_west_`base' prop_fem_`base' ///
            if freq_wt_`base' >= 10 [aweight = freq_wt_`base'], vce(robust)

        if "`exp'" == "d_openai_S2_S1" & "`y'" == "d_log_emp" {
            outreg2 using "$export_root/June/txt/6_25/ExposureComparison_OpenAI.txt", keep(`exp') nocons replace
        }
        else {
            outreg2 using "$export_root/June/txt/6_25/ExposureComparison_OpenAI.txt", keep(`exp') nocons append
        }
    }
}

* Define outcomes and exposure difference variables
local outcomes d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime
local exposure_diffs d_claude_S2_S1 d_claude_S3_S1 d_claude_S4_S1 d_claude_S5_S1

* Use the same period and base period for all (P2T_P4T)
local base P2T

* Loop over OpenAI exposure difference measures
foreach exp in `exposure_diffs' {
    foreach y in `outcomes' {
        reg `y'_P2T_P4T `exp' NR_CA NR_CI RC RM NRMP offshore ///
            prop_age_30to50_`base' prop_age_50plus_`base' prop_black_`base' ///
            prop_asian_`base' prop_native_`base' prop_mixed_other_`base' prop_pacific_`base' ///
            prop_educ_q1_`base' prop_educ_q2_`base' prop_educ_q3_`base' ///
            prop_midwest_`base' prop_northeast_`base' prop_west_`base' prop_fem_`base' ///
            if freq_wt_`base' >= 10 [aweight = freq_wt_`base'], vce(robust)

        if "`exp'" == "d_claude_S2_S1" & "`y'" == "d_log_emp" {
            outreg2 using "$export_root/June/txt/6_25/ExposureComparison_claude.txt", keep(`exp') nocons replace
        }
        else {
            outreg2 using "$export_root/June/txt/6_25/ExposureComparison_claude.txt", keep(`exp') nocons append
        }
    }
}

* Load your data
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

* Define exposure differences and outcomes
local stages S2_S1 S3_S1 S4_S1 S5_S1
local outcomes d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime

* Generate standardized exposure variables
foreach s of local stages {
    summarize d_openai_`s' if freq_wt_P2T >= 10,
    local mu = r(mean)
    local sd = r(sd)

    gen z_openai_`s' = (d_openai_`s' - `mu') / `sd'
}


* Loop over standardized exposures and outcomes
foreach s of local stages {
    foreach y of local outcomes {
        reg `y'_P2T_P4T z_openai_`s' NR_CA NR_CI RC RM NRMP offshore ///
            prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
            prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
            prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
            prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
            if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)

        * Export results
        if "`y'" == "d_log_emp" & "`s'" == "S2_S1" {
            outreg2 using "$export_root/June/txt/Standardized_OpenAI.txt", keep(z_openai_`s') nocons replace
        }
        else {
            outreg2 using "$export_root/June/txt/Standardized_OpenAI.txt", keep(z_openai_`s') nocons append
        }
    }
}

* Load your data
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

* Define exposure differences and outcomes
local stages S2_S1 S3_S1 S4_S1 S5_S1
local outcomes d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime

* Generate standardized exposure variables
foreach s of local stages {
    summarize d_claude_`s' if freq_wt_P2T >= 10,
    local mu = r(mean)
    local sd = r(sd)

    gen z_claude_`s' = (d_openai_`s' - `mu') / `sd'
}


* Loop over standardized exposures and outcomes
foreach s of local stages {
    foreach y of local outcomes {
        reg `y'_P2T_P4T z_claude_`s' NR_CA NR_CI RC RM NRMP offshore ///
            prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
            prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
            prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T ///
            prop_midwest_P2T prop_northeast_P2T prop_west_P2T prop_fem_P2T ///
            if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)

        * Export results
        if "`y'" == "d_log_emp" & "`s'" == "S2_S1" {
            outreg2 using "$export_root/June/txt/Standardized_claude.txt", keep(z_claude_`s') nocons replace
        }
        else {
            outreg2 using "$export_root/June/txt/Standardized_claude.txt", keep(z_claude_`s') nocons append
        }
    }
}






************************************************************************
*******************************************************************************************************************
********************************************** Earnings ***********************************************
*******************************************************************************************************************

********************************************** P4T - P2T = β (S3 - S1) ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_EW_2010_Base_P2T_P4T d_log_EW_base_P2T_P4T d_EW_2010_clean_P2T_P4T d_log_EW_clean_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_EW_2010_Base_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_12/earnings_3_1_A.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_12/earnings_3_1_A.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_12/earnings_3_1_A.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear
local outcomes d_EW_2010_Base_P2T_P4T d_log_EW_base_P2T_P4T d_EW_2010_clean_P2T_P4T d_log_EW_clean_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_EW_2010_Base_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_12/earnings_3_1_B.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_12/earnings_3_1_B.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_12/earnings_3_1_B.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_EW_2010_Base_P2T_P4T d_log_EW_base_P2T_P4T d_EW_2010_clean_P2T_P4T d_log_EW_clean_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_EW_2010_Base_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_12/earnings_3_1_C.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_12/earnings_3_1_C.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_12/earnings_3_1_C.txt", keep(d_claude_S3_S1) nocons append
}

 
********************************************** P4T - P2T = β (S3 - S1) >= 10 ***********************************************

*** Baseline Model
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_EW_2010_Base_P2T_P4T d_log_EW_base_P2T_P4T d_EW_2010_clean_P2T_P4T d_log_EW_clean_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_EW_2010_Base_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_12/earnings_3_1_A_G10.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_12/earnings_3_1_A_G10.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_12/earnings_3_1_A_G10.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear
local outcomes d_EW_2010_Base_P2T_P4T d_log_EW_base_P2T_P4T d_EW_2010_clean_P2T_P4T d_log_EW_clean_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_EW_2010_Base_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_12/earnings_3_1_B_G10.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_12/earnings_3_1_B_G10.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_12/earnings_3_1_B_G10.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/2010_2025_ld_analysis_occ2010.dta", clear

local outcomes d_EW_2010_Base_P2T_P4T d_log_EW_base_P2T_P4T d_EW_2010_clean_P2T_P4T d_log_EW_clean_P2T_P4T
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
    
    if "`y'" == "d_EW_2010_Base_P2T_P4T" {
        outreg2 using "$export_root/June/txt/6_12/earnings_3_1_C_G10.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_12/earnings_3_1_C_G10.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30to50_P2T prop_age_50plus_P2T prop_black_P2T ///
        prop_asian_P2T prop_native_P2T prop_mixed_other_P2T prop_pacific_P2T ///
        prop_educ_q1_P2T prop_educ_q2_P2T prop_educ_q3_P2T prop_midwest_P2T ///
        prop_northeast_P2T prop_west_P2T prop_fem_P2T if freq_wt_P2T >= 10 [aweight = freq_wt_P2T], vce(robust)
	outreg2 using "$export_root/June/txt/6_12/earnings_3_1_C_G10.txt", keep(d_claude_S3_S1) nocons append
}
