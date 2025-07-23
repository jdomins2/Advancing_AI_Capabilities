* Name: het_061725
* Author: Jacob Dominski
* Date Created:06/17/25

************************************************ Set Global paths **************************************************

global data_root = "/Users/jdomins2/Desktop/CPS_Work/Data"
global export_root = "/Users/jdomins2/Desktop/CPS_Work/Output"
global crosswalk_root = "/Users/jdomins2/Desktop/CPS_Work/Crosswalks"

************************************************ Cleaning (Individual) **************************************************
use  "$data_root/Working/cps_2010_2025_occ2010_individ.dta", clear

*** Gender ***
tab sex
* 1 - male; 2 - female


*** Region (Major) ***
tab region
gen region_major = .
replace region_major = 1 if region == 11 | region == 12 
* Northeast Region
replace region_major = 2 if region == 21 | region == 22 
* Midwest Region
replace region_major = 3 if region == 31 | region == 32 | region == 33 
* South Region
replace region_major = 4 if region == 41 | region == 42 
* West Region
tab region_major
label define region_lbl 1 "Northeast" 2 "Midwest" 3 "South" 4 "West"
label values region_major region_lbl


*** Region (coasts) ***
gen region_group = .
replace region_group = 1 if region == 42
*** West coast: census pacific divitions
replace region_group = 2 if region == 11 | region == 12 | statefip == 10 | statefip == 51 | statefip == 24 | statefip == 11
*** East coast: census Divisions New England and Mid Atlantic + DE + VA + MD + DC
replace region_group = 3 if missing(region_group)
label define coast_lbl 1 "West Coast" 2 "East Coast" 3 "Non-Coastal" 
label values region_group coast_lbl

*** Region (Rust belt) ***
gen region_rust = 0
replace region_rust = 1 if statefip == 17 | statefip == 18 | statefip == 26 | statefip == 29 | statefip == 39 | statefip == 42 | statefip == 54 | statefip == 55 /// Illinois, Indiana, Michigan, Missouri, Ohio, Pennsylvania, West Virginia, Wisconsin

label define rust_lbl 1 "Rust Belt" 0 "Non-rust belt" 
label values region_rust rust_lbl
tab region_rust

*** Age group ***
tab agegroup
* 1 - 30 and under; 2 - 30 plus to 50 and under; 3 - Over 50
tab age
drop agegroup
gen agegroup = .
replace agegroup = 1 if age < 26 & !missing(age)
replace agegroup = 2 if age >= 26 & age <= 55 & !missing(age)
replace agegroup = 3 if age > 55
label define age_lbl 1 "Under 26" 2 "26-55" 3 "Over 55" 
label values agegroup age_lbl


*** Race ***
tab race
gen race_group = .
replace race_group = 1 if race == 100
* White
replace race_group = 2 if race == 200
* Black
replace race_group = 3 if race == 651
* Asian
replace race_group = 3 if race == 300
* All other
replace race_group = 4 if missing(race_group) & !missing(race)
label define race_lbl 1 "White" 2 "Black" 3 "Asian" 4 "All other races"
label values race_group race_lbl


tab race_group

*** Education ***
tab educ
gen educ_group = .
replace educ_group = 1 if educ <= 72
* Less than high school
replace educ_group = 2 if educ >= 73 & educ <= 110
* HS Degree & Some College
replace educ_group = 3 if educ == 111 
* BA
replace educ_group = 4 if educ >= 112
* More than BA
tab educ_group
label define educ_lbl 1 "Less than HS" 2 "HS / Some College" 3 "BA" 4 "More than BA"
label values educ_group educ_lbl


*** Industry ***
gen ind1990_group = .
replace ind1990_group = 1 if ind1990 >= 001 & ind1990 <= 050 // Agriculture, forestry, and fisheries
replace ind1990_group = 2 if ind1990 >= 051 & ind1990 <= 392 // Construction and Manufacturing
replace ind1990_group = 3 if ind1990 >= 393 & ind1990 <= 472 |  ind1990 >= 900 & ind1990 <= 932 // Transportation, Communications, Public Administration
replace ind1990_group = 4 if ind1990 >= 473 & ind1990 <= 691 // Trade
replace ind1990_group = 5 if ind1990 >= 692 & ind1990 <= 760 // Finance, Insurance, Real Estate, and Business Services
replace ind1990_group = 6 if ind1990 >= 761 & ind1990 <= 810 // Services except Professional 
replace ind1990_group = 7 if ind1990 >= 811 & ind1990 <= 893 // Professional and Related Services
label define indust_lbl 1 "Agriculture, forestry, and fisheries" 2 "Construction and Manufacturing" 3 "Transportation, Communications, Public Administration" 4 "Trade" 5 "Finance, Insurance, Real Estate, and Business Services" 6 "Services except Professional" 7 "Professional and Related Services"
label values ind1990_group indust_lbl

save "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", replace


************************************* Creating Occupation-Month Level Outcomes + Controls (Gender) **************************************
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear


*Creating Occupation, Month Level Outcome Variables
collapse (sum) demployed Dunemp dlabforce ///
         (mean) ahrswork1 ahrsworkt ntime openai1_occ2010 openai2_occ2010 openai3_occ2010 openai4_occ2010 openai5_occ2010 claude1_occ2010 ///
		 claude2_occ2010 claude3_occ2010 claude4_occ2010 claude5_occ2010 unemp_rate other_job new_wrk_acts ahrswork2 Fulltime EW_2010_Base ///
		 log_EW_base EW_2010_clean log_EW_clean, ///
         by(year month occ2010 sex)

*Confirming everything is going well w/ how I calculate unemp. rates
gen unemp_rate_new = Dunemp / dlabforce
gen log_emp = log(demployed)
drop unemp_rate
rename unemp_rate_new unemp_rate

save "$data_root/working/occ2010_het_gender.dta", replace


*Creating Occupation-Month Level Controls
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
sort occ2010 year month sex

* Generate total count of workers per occupation-month
bysort year month occ2010 sex: gen total_workers = _N
sum total_workers, det

* Compute Proportion of Women 
bysort year month occ2010 sex: egen prop_male = mean(sex == 1)
bysort year month occ2010 sex: egen prop_fem = mean(sex == 2)


* Compute Education Shares
bysort year month occ2010 sex: egen prop_educ_q1 = mean(educ_group == 1)
bysort year month occ2010 sex: egen prop_educ_q2 = mean(educ_group == 2)
bysort year month occ2010 sex: egen prop_educ_q3 = mean(educ_group == 3)
bysort year month occ2010 sex: egen prop_educ_q4 = mean(educ_group == 4)

* Compute Age Group Shares 
bysort year month occ2010 sex: egen prop_age_26less = mean(agegroup == 1)
bysort year month occ2010 sex: egen prop_age_26to55 = mean(agegroup == 2)
bysort year month occ2010 sex: egen prop_age_55plus = mean(agegroup == 3)


* Compute Race Shares 
bysort year month occ2010 sex: egen prop_white = mean(race_group == 1)
bysort year month occ2010 sex: egen prop_black = mean(race_group == 2)
bysort year month occ2010 sex: egen prop_asian = mean(race_group == 3)
bysort year month occ2010 sex: egen prop_other = mean(race_group == 4)

* Compute Region Shares 
bysort year month occ2010 sex: egen prop_northeast = mean(region_major == 1)
bysort year month occ2010 sex: egen prop_midwest = mean(region_major == 2)
bysort year month occ2010 sex: egen prop_south = mean(region_major == 3)
bysort year month occ2010 sex: egen prop_west = mean(region_major == 4)


* Keep One Observation per Occupation-Month
collapse (mean) prop_fem prop_male prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 ///
         prop_age_26less prop_age_26to55 prop_age_55plus prop_northeast prop_midwest prop_south prop_west ///
         prop_white prop_black prop_asian prop_other, by(year month occ2010 sex)


merge 1:1 year month occ2010 sex using "$data_root/Working/occ2010_het_gender.dta"
drop _merge
rename Fulltime fulltime
gen split_type = "gender" if !missing(sex)
save "$data_root/working/het_occ2010/occ2010_het_gender.dta", replace

************************************* Creating Occupation-Month Level Outcomes + Controls (Race) **************************************
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear


*Creating Occupation, Month Level Outcome Variables
collapse (sum) demployed Dunemp dlabforce ///
         (mean) ahrswork1 ahrsworkt ntime openai1_occ2010 openai2_occ2010 openai3_occ2010 openai4_occ2010 openai5_occ2010 claude1_occ2010 ///
		 claude2_occ2010 claude3_occ2010 claude4_occ2010 claude5_occ2010 unemp_rate other_job new_wrk_acts ahrswork2 Fulltime EW_2010_Base ///
		 log_EW_base EW_2010_clean log_EW_clean, ///
         by(year month occ2010 race_group)

*Remaking unenployment rates by race
gen unemp_rate_new = Dunemp / dlabforce
gen log_emp = log(demployed)
drop unemp_rate
rename unemp_rate_new unemp_rate

save "$data_root/working/occ2010_het_race.dta", replace


*Creating Occupation-Month Level Controls
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
sort occ2010 year month race_group

* Generate total count of workers per occupation-month
bysort year month occ2010 race_group: gen total_workers = _N
sum total_workers, det

* Compute Proportion of Women 
bysort year month occ2010 race_group: egen prop_male = mean(sex == 1)
bysort year month occ2010 race_group: egen prop_fem = mean(sex == 2)


* Compute Education Shares
bysort year month occ2010 race_group: egen prop_educ_q1 = mean(educ_group == 1)
bysort year month occ2010 race_group: egen prop_educ_q2 = mean(educ_group == 2)
bysort year month occ2010 race_group: egen prop_educ_q3 = mean(educ_group == 3)
bysort year month occ2010 race_group: egen prop_educ_q4 = mean(educ_group == 4)

* Compute Age Group Shares 
bysort year month occ2010 race_group: egen prop_age_26less = mean(agegroup == 1)
bysort year month occ2010 race_group: egen prop_age_26to55 = mean(agegroup == 2)
bysort year month occ2010 race_group: egen prop_age_55plus = mean(agegroup == 3)


* Compute Race Shares 
bysort year month occ2010 race_group: egen prop_white = mean(race_group == 1)
bysort year month occ2010 race_group: egen prop_black = mean(race_group == 2)
bysort year month occ2010 race_group: egen prop_asian = mean(race_group == 3)
bysort year month occ2010 race_group: egen prop_other = mean(race_group == 4)


* Compute Region Shares 
bysort year month occ2010 race_group: egen prop_northeast = mean(region_major == 1)
bysort year month occ2010 race_group: egen prop_midwest = mean(region_major == 2)
bysort year month occ2010 race_group: egen prop_south = mean(region_major == 3)
bysort year month occ2010 race_group: egen prop_west = mean(region_major == 4)


* Keep One Observation per Occupation-Month
collapse (mean) prop_fem prop_male prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 ///
         prop_age_26less prop_age_26to55 prop_age_55plus prop_northeast prop_midwest prop_south prop_west ///
         prop_white prop_black prop_asian prop_other, by(year month occ2010 race_group)


merge 1:1 year month occ2010 race_group using "$data_root/Working/occ2010_het_race.dta"
drop _merge
rename Fulltime fulltime
gen split_type = "race" if !missing(race_group)
save "$data_root/working/het_occ2010/occ2010_het_race.dta", replace

************************************* Creating Occupation-Month Level Outcomes + Controls (Educ) **************************************
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear


*Creating Occupation, Month Level Outcome Variables
collapse (sum) demployed Dunemp dlabforce ///
         (mean) ahrswork1 ahrsworkt ntime openai1_occ2010 openai2_occ2010 openai3_occ2010 openai4_occ2010 openai5_occ2010 claude1_occ2010 ///
		 claude2_occ2010 claude3_occ2010 claude4_occ2010 claude5_occ2010 unemp_rate other_job new_wrk_acts ahrswork2 Fulltime EW_2010_Base ///
		 log_EW_base EW_2010_clean log_EW_clean, ///
         by(year month occ2010 educ_group)

*Remaking unenployment rates by race
gen unemp_rate_new = Dunemp / dlabforce
gen log_emp = log(demployed)
drop unemp_rate
rename unemp_rate_new unemp_rate


save "$data_root/working/occ2010_het_educ.dta", replace


*Creating Occupation-Month Level Controls
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
sort occ2010 year month educ_group

* Generate total count of workers per occupation-month
bysort year month occ2010 race_group: gen total_workers = _N
sum total_workers, det

* Compute Proportion of Women 
bysort year month occ2010 educ_group: egen prop_male = mean(sex == 1)
bysort year month occ2010 educ_group: egen prop_fem = mean(sex == 2)


* Compute Education Shares
bysort year month occ2010 educ_group: egen prop_educ_q1 = mean(educ_group == 1)
bysort year month occ2010 educ_group: egen prop_educ_q2 = mean(educ_group == 2)
bysort year month occ2010 educ_group: egen prop_educ_q3 = mean(educ_group == 3)
bysort year month occ2010 educ_group: egen prop_educ_q4 = mean(educ_group == 4)

* Compute Age Group Shares 
bysort year month occ2010 educ_group: egen prop_age_26less = mean(agegroup == 1)
bysort year month occ2010 educ_group: egen prop_age_26to55 = mean(agegroup == 2)
bysort year month occ2010 educ_group: egen prop_age_55plus = mean(agegroup == 3)


* Compute Race Shares 
bysort year month occ2010 educ_group: egen prop_white = mean(race_group == 1)
bysort year month occ2010 educ_group: egen prop_black = mean(race_group == 2)
bysort year month occ2010 educ_group: egen prop_asian = mean(race_group == 3)
bysort year month occ2010 educ_group: egen prop_other = mean(race_group == 4)


* Compute Region Shares 
bysort year month occ2010 educ_group: egen prop_northeast = mean(region_major == 1)
bysort year month occ2010 educ_group: egen prop_midwest = mean(region_major == 2)
bysort year month occ2010 educ_group: egen prop_south = mean(region_major == 3)
bysort year month occ2010 educ_group: egen prop_west = mean(region_major == 4)


* Keep One Observation per Occupation-Month
collapse (mean) prop_fem prop_male prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 ///
         prop_age_26less prop_age_26to55 prop_age_55plus prop_northeast prop_midwest prop_south prop_west ///
         prop_white prop_black prop_asian prop_other, by(year month occ2010 educ_group)


merge 1:1 year month occ2010 educ_group using "$data_root/Working/occ2010_het_educ.dta"
drop _merge
rename Fulltime fulltime
gen split_type = "educ" if !missing(educ_group)
count 
count if split_type == "educ"
save "$data_root/working/het_occ2010/occ2010_het_educ.dta", replace

************************************* Creating Occupation-Month Level Outcomes + Controls (Region) **************************************
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear


*Creating Occupation, Month Level Outcome Variables
collapse (sum) demployed Dunemp dlabforce ///
         (mean) ahrswork1 ahrsworkt ntime openai1_occ2010 openai2_occ2010 openai3_occ2010 openai4_occ2010 openai5_occ2010 claude1_occ2010 ///
		 claude2_occ2010 claude3_occ2010 claude4_occ2010 claude5_occ2010 unemp_rate other_job new_wrk_acts ahrswork2 Fulltime EW_2010_Base ///
		 log_EW_base EW_2010_clean log_EW_clean, ///
         by(year month occ2010 region_major)

*Remaking unenployment rates by race
gen unemp_rate_new = Dunemp / dlabforce
gen log_emp = log(demployed)
drop unemp_rate
rename unemp_rate_new unemp_rate

save "$data_root/working/occ2010_het_region.dta", replace


*Creating Occupation-Month Level Controls
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
sort occ2010 year month region_major

* Generate total count of workers per occupation-month
bysort year month occ2010 region_major: gen total_workers = _N
sum total_workers, det

* Compute Proportion of Women 
bysort year month occ2010 region_major: egen prop_male = mean(sex == 1)
bysort year month occ2010 region_major: egen prop_fem = mean(sex == 2)


* Compute Education Shares
bysort year month occ2010 region_major: egen prop_educ_q1 = mean(educ_group == 1)
bysort year month occ2010 region_major: egen prop_educ_q2 = mean(educ_group == 2)
bysort year month occ2010 region_major: egen prop_educ_q3 = mean(educ_group == 3)
bysort year month occ2010 region_major: egen prop_educ_q4 = mean(educ_group == 4)

* Compute Age Group Shares 
bysort year month occ2010 region_major: egen prop_age_26less = mean(agegroup == 1)
bysort year month occ2010 region_major: egen prop_age_26to55 = mean(agegroup == 2)
bysort year month occ2010 region_major: egen prop_age_55plus = mean(agegroup == 3)


* Compute Race Shares 
bysort year month occ2010 region_major: egen prop_white = mean(race_group == 1)
bysort year month occ2010 region_major: egen prop_black = mean(race_group == 2)
bysort year month occ2010 region_major: egen prop_asian = mean(race_group == 3)
bysort year month occ2010 region_major: egen prop_other = mean(race_group == 4)


* Compute Region Shares 
bysort year month occ2010 region_major: egen prop_northeast = mean(region_major == 1)
bysort year month occ2010 region_major: egen prop_midwest = mean(region_major == 2)
bysort year month occ2010 region_major: egen prop_south = mean(region_major == 3)
bysort year month occ2010 region_major: egen prop_west = mean(region_major == 4)


* Keep One Observation per Occupation-Month
collapse (mean) prop_fem prop_male prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 ///
         prop_age_26less prop_age_26to55 prop_age_55plus prop_northeast prop_midwest prop_south prop_west ///
         prop_white prop_black prop_asian prop_other, by(year month occ2010 region_major)


merge 1:1 year month occ2010 region_major using "$data_root/Working/occ2010_het_region.dta"
drop _merge
rename Fulltime fulltime
gen split_type = "region" if !missing(region_major)
count
count if split_type == "region"
save "$data_root/working/het_occ2010/occ2010_het_region.dta", replace

************************************* Creating Occupation-Month Level Outcomes + Controls (Region V2) **************************************
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear


*Creating Occupation, Month Level Outcome Variables
collapse (sum) demployed Dunemp dlabforce ///
         (mean) ahrswork1 ahrsworkt ntime openai1_occ2010 openai2_occ2010 openai3_occ2010 openai4_occ2010 openai5_occ2010 claude1_occ2010 ///
		 claude2_occ2010 claude3_occ2010 claude4_occ2010 claude5_occ2010 unemp_rate other_job new_wrk_acts ahrswork2 Fulltime EW_2010_Base ///
		 log_EW_base EW_2010_clean log_EW_clean, ///
         by(year month occ2010 region_group)

*Remaking unenployment rates by race
gen unemp_rate_new = Dunemp / dlabforce
gen log_emp = log(demployed)
drop unemp_rate
rename unemp_rate_new unemp_rate

save "$data_root/working/occ2010_het_region_group.dta", replace


*Creating Occupation-Month Level Controls
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
sort occ2010 year month region_major

* Generate total count of workers per occupation-month
bysort year month occ2010 region_group: gen total_workers = _N
sum total_workers, det

* Compute Proportion of Women 
bysort year month occ2010 region_group: egen prop_male = mean(sex == 1)
bysort year month occ2010 region_group: egen prop_fem = mean(sex == 2)


* Compute Education Shares
bysort year month occ2010 region_group: egen prop_educ_q1 = mean(educ_group == 1)
bysort year month occ2010 region_group: egen prop_educ_q2 = mean(educ_group == 2)
bysort year month occ2010 region_group: egen prop_educ_q3 = mean(educ_group == 3)
bysort year month occ2010 region_group: egen prop_educ_q4 = mean(educ_group == 4)

* Compute Age Group Shares 
bysort year month occ2010 region_group: egen prop_age_26less = mean(agegroup == 1)
bysort year month occ2010 region_group: egen prop_age_26to55 = mean(agegroup == 2)
bysort year month occ2010 region_group: egen prop_age_55plus = mean(agegroup == 3)


* Compute Race Shares 
bysort year month occ2010 region_group: egen prop_white = mean(race_group == 1)
bysort year month occ2010 region_group: egen prop_black = mean(race_group == 2)
bysort year month occ2010 region_group: egen prop_asian = mean(race_group == 3)
bysort year month occ2010 region_group: egen prop_other = mean(race_group == 4)


* Compute Region Shares 
bysort year month occ2010 region_group: egen prop_westC = mean(region_group == 1)
bysort year month occ2010 region_group: egen prop_eastC = mean(region_group == 2)
bysort year month occ2010 region_group: egen prop_otherC = mean(region_group == 3)



* Keep One Observation per Occupation-Month
collapse (mean) prop_fem prop_male prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 ///
         prop_age_26less prop_age_26to55 prop_age_55plus prop_westC prop_eastC prop_otherC ///
         prop_white prop_black prop_asian prop_other, by(year month occ2010 region_group)


merge 1:1 year month occ2010 region_group using "$data_root/Working/occ2010_het_region_group.dta"
drop _merge
rename Fulltime fulltime
gen split_type = "region_group" if !missing(region_group)
count
count if split_type == "region_group"
save "$data_root/working/het_occ2010/occ2010_het_region_group.dta", replace

************************************* Creating Occupation-Month Level Outcomes + Controls (Region V2) **************************************
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear


*Creating Occupation, Month Level Outcome Variables
collapse (sum) demployed Dunemp dlabforce ///
         (mean) ahrswork1 ahrsworkt ntime openai1_occ2010 openai2_occ2010 openai3_occ2010 openai4_occ2010 openai5_occ2010 claude1_occ2010 ///
		 claude2_occ2010 claude3_occ2010 claude4_occ2010 claude5_occ2010 unemp_rate other_job new_wrk_acts ahrswork2 Fulltime EW_2010_Base ///
		 log_EW_base EW_2010_clean log_EW_clean, ///
         by(year month occ2010 region_rust)

*Remaking unenployment rates by race
gen unemp_rate_new = Dunemp / dlabforce
gen log_emp = log(demployed)
drop unemp_rate
rename unemp_rate_new unemp_rate

save "$data_root/working/occ2010_het_region_rust.dta", replace


*Creating Occupation-Month Level Controls
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
sort occ2010 year month region_rust

* Generate total count of workers per occupation-month
bysort year month occ2010 region_rust: gen total_workers = _N
sum total_workers, det

* Compute Proportion of Women 
bysort year month occ2010 region_rust: egen prop_male = mean(sex == 1)
bysort year month occ2010 region_rust: egen prop_fem = mean(sex == 2)


* Compute Education Shares
bysort year month occ2010 region_rust: egen prop_educ_q1 = mean(educ_group == 1)
bysort year month occ2010 region_rust: egen prop_educ_q2 = mean(educ_group == 2)
bysort year month occ2010 region_rust: egen prop_educ_q3 = mean(educ_group == 3)
bysort year month occ2010 region_rust: egen prop_educ_q4 = mean(educ_group == 4)

* Compute Age Group Shares 
bysort year month occ2010 region_rust: egen prop_age_26less = mean(agegroup == 1)
bysort year month occ2010 region_rust: egen prop_age_26to55 = mean(agegroup == 2)
bysort year month occ2010 region_rust: egen prop_age_55plus = mean(agegroup == 3)


* Compute Race Shares 
bysort year month occ2010 region_rust: egen prop_white = mean(race_group == 1)
bysort year month occ2010 region_rust: egen prop_black = mean(race_group == 2)
bysort year month occ2010 region_rust: egen prop_asian = mean(race_group == 3)
bysort year month occ2010 region_rust: egen prop_other = mean(race_group == 4)


* Compute Region Shares 
bysort year month occ2010 region_rust: egen prop_rust = mean(region_rust == 1)
bysort year month occ2010 region_rust: egen prop_nonrust = mean(region_rust == 0)


* Keep One Observation per Occupation-Month
collapse (mean) prop_fem prop_male prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 ///
         prop_age_26less prop_age_26to55 prop_age_55plus prop_rust prop_nonrust ///
         prop_white prop_black prop_asian prop_other, by(year month occ2010 region_rust)


merge 1:1 year month occ2010 region_rust using "$data_root/Working/occ2010_het_region_rust.dta"
drop _merge
rename Fulltime fulltime
gen split_type = "region_rust" if !missing(region_rust)
count
count if split_type == "region_rust"
save "$data_root/working/het_occ2010/occ2010_het_region_rust.dta", replace

************************************* Creating Occupation-Month Level Outcomes + Controls (Age) **************************************
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear


*Creating Occupation, Month Level Outcome Variables
collapse (sum) demployed Dunemp dlabforce ///
         (mean) ahrswork1 ahrsworkt ntime openai1_occ2010 openai2_occ2010 openai3_occ2010 openai4_occ2010 openai5_occ2010 claude1_occ2010 ///
		 claude2_occ2010 claude3_occ2010 claude4_occ2010 claude5_occ2010 unemp_rate other_job new_wrk_acts ahrswork2 Fulltime EW_2010_Base ///
		 log_EW_base EW_2010_clean log_EW_clean, ///
         by(year month occ2010 agegroup)

*Remaking unenployment rates by race
gen unemp_rate_new = Dunemp / dlabforce
gen log_emp = log(demployed)
drop unemp_rate
rename unemp_rate_new unemp_rate


save "$data_root/working/occ2010_het_age.dta", replace


*Creating Occupation-Month Level Controls
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
sort occ2010 year month agegroup

* Generate total count of workers per occupation-month
bysort year month occ2010 agegroup: gen total_workers = _N
sum total_workers, det

* Compute Proportion of Women 
bysort year month occ2010 agegroup: egen prop_male = mean(sex == 1)
bysort year month occ2010 agegroup: egen prop_fem = mean(sex == 2)


* Compute Education Shares
bysort year month occ2010 agegroup: egen prop_educ_q1 = mean(educ_group == 1)
bysort year month occ2010 agegroup: egen prop_educ_q2 = mean(educ_group == 2)
bysort year month occ2010 agegroup: egen prop_educ_q3 = mean(educ_group == 3)
bysort year month occ2010 agegroup: egen prop_educ_q4 = mean(educ_group == 4)

* Compute Age Group Shares 
bysort year month occ2010 agegroup: egen prop_age_26less = mean(agegroup == 1)
bysort year month occ2010 agegroup: egen prop_age_26to55 = mean(agegroup == 2)
bysort year month occ2010 agegroup: egen prop_age_55plus = mean(agegroup == 3)


* Compute Race Shares 
bysort year month occ2010 agegroup: egen prop_white = mean(race_group == 1)
bysort year month occ2010 agegroup: egen prop_black = mean(race_group == 2)
bysort year month occ2010 agegroup: egen prop_asian = mean(race_group == 3)
bysort year month occ2010 agegroup: egen prop_other = mean(race_group == 4)


* Compute Region Shares 
bysort year month occ2010 agegroup: egen prop_northeast = mean(region_major == 1)
bysort year month occ2010 agegroup: egen prop_midwest = mean(region_major == 2)
bysort year month occ2010 agegroup: egen prop_south = mean(region_major == 3)
bysort year month occ2010 agegroup: egen prop_west = mean(region_major == 4)


* Keep One Observation per Occupation-Month
collapse (mean) prop_fem prop_male prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 ///
         prop_age_26less prop_age_26to55 prop_age_55plus prop_northeast prop_midwest prop_south prop_west ///
         prop_white prop_black prop_asian prop_other, by(year month occ2010 agegroup)


merge 1:1 year month occ2010 agegroup using "$data_root/Working/occ2010_het_age.dta"
drop _merge
rename Fulltime fulltime
gen split_type = "age"
count 
count if split_type == "age"
save "$data_root/working/het_occ2010/occ2010_het_age.dta", replace

************************************* Creating Occupation-Month Level Outcomes + Controls (Industry) **************************************
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear


*Creating Occupation, Month Level Outcome Variables
collapse (sum) demployed Dunemp dlabforce ///
         (mean) ahrswork1 ahrsworkt ntime openai1_occ2010 openai2_occ2010 openai3_occ2010 openai4_occ2010 openai5_occ2010 claude1_occ2010 ///
		 claude2_occ2010 claude3_occ2010 claude4_occ2010 claude5_occ2010 unemp_rate other_job new_wrk_acts ahrswork2 Fulltime EW_2010_Base ///
		 log_EW_base EW_2010_clean log_EW_clean, ///
         by(year month occ2010 ind1990_group)

*Remaking unenployment rates by race
gen unemp_rate_new = Dunemp / dlabforce
gen log_emp = log(demployed)
drop unemp_rate
rename unemp_rate_new unemp_rate


save "$data_root/working/occ2010_het_ind1990.dta", replace


*Creating Occupation-Month Level Controls
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
sort occ2010 year month ind1990_group

* Generate total count of workers per occupation-month
bysort year month occ2010 ind1990_group: gen total_workers = _N
sum total_workers, det

* Compute Proportion of Women 
bysort year month occ2010 ind1990_group: egen prop_male = mean(sex == 1)
bysort year month occ2010 ind1990_group: egen prop_fem = mean(sex == 2)


* Compute Education Shares
bysort year month occ2010 ind1990_group: egen prop_educ_q1 = mean(educ_group == 1)
bysort year month occ2010 ind1990_group: egen prop_educ_q2 = mean(educ_group == 2)
bysort year month occ2010 ind1990_group: egen prop_educ_q3 = mean(educ_group == 3)
bysort year month occ2010 ind1990_group: egen prop_educ_q4 = mean(educ_group == 4)

* Compute Age Group Shares 
bysort year month occ2010 ind1990_group: egen prop_age_26less = mean(agegroup == 1)
bysort year month occ2010 ind1990_group: egen prop_age_26to55 = mean(agegroup == 2)
bysort year month occ2010 ind1990_group: egen prop_age_55plus = mean(agegroup == 3)


* Compute Race Shares 
bysort year month occ2010 ind1990_group: egen prop_white = mean(race_group == 1)
bysort year month occ2010 ind1990_group: egen prop_black = mean(race_group == 2)
bysort year month occ2010 ind1990_group: egen prop_asian = mean(race_group == 3)
bysort year month occ2010 ind1990_group: egen prop_other = mean(race_group == 4)


* Compute Region Shares 
bysort year month occ2010 ind1990_group: egen prop_northeast = mean(region_major == 1)
bysort year month occ2010 ind1990_group: egen prop_midwest = mean(region_major == 2)
bysort year month occ2010 ind1990_group: egen prop_south = mean(region_major == 3)
bysort year month occ2010 ind1990_group: egen prop_west = mean(region_major == 4)


* Keep One Observation per Occupation-Month
collapse (mean) prop_fem prop_male prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 ///
         prop_age_26less prop_age_26to55 prop_age_55plus prop_northeast prop_midwest prop_south prop_west ///
         prop_white prop_black prop_asian prop_other, by(year month occ2010 ind1990_group)


merge 1:1 year month occ2010 ind1990_group using "$data_root/Working/occ2010_het_ind1990.dta"
drop _merge
rename Fulltime fulltime
gen split_type = "ind1990"
count 
count if split_type == "ind1990"
save "$data_root/working/het_occ2010/occ2010_het_ind1990.dta", replace

************************************* Appending **************************************
use "$data_root/Working/monthly_cps_by_occ_2010_2025_occ2010.dta", clear
gen split_type = "total"
append using "$data_root/working/het_occ2010/occ2010_het_age.dta"
append using "$data_root/working/het_occ2010/occ2010_het_educ.dta"
append using "$data_root/working/het_occ2010/occ2010_het_gender.dta"
append using "$data_root/working/het_occ2010/occ2010_het_region.dta"
append using "$data_root/working/het_occ2010/occ2010_het_race.dta"

*** Checking
br year month occ2010 split_type log_emp

br year month occ2010 split_type demployed

drop prop_educ_hs_or_less prop_educ_college_or_more
save "$data_root/working/het_occ2010/occ2010_het_all.dta", replace

						
********************************************************************************************************************
*************************************** Creating Averages for 6 Month Periods **************************************
********************************************************************************************************************

********************************************* P4T (Oct 2024 - March 2025); Age *******************************************

******* Age *******
use "$data_root/working/het_occ2010/occ2010_het_all.dta", clear

* Keep P4T 
keep if ((year == 2025 & (month == 1 | month == 2 | month == 3)) | (year == 2024 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "age"

bysort occ2010 agegroup year month: gen byte group_months = _n == 1
bysort occ2010 agegroup: egen n_months = total(group_months)

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010 agegroup)


* Rename variables to specify they are from P4T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P4T_age
}

save "$data_root/working/het_occ2010/P4T_age.dta", replace

********************************************* P2T (Oct 2022 - March 2023); Age *******************************************

******* Age *******
use "$data_root/working/het_occ2010/occ2010_het_all.dta", clear

* Keep P2T 
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "age"

bysort occ2010 agegroup year month: gen byte group_months = _n == 1
bysort occ2010 agegroup: egen n_months = total(group_months)

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010 agegroup)


* Rename variables to specify they are from P2T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P2T_age
}

save "$data_root/working/het_occ2010/P2T_age.dta", replace
merge 1:1 occ2010 agegroup using "$data_root/working/het_occ2010/P4T_age.dta"
br occ2010 agegroup _merge if _merge == 1 | _merge == 2


gen split_type = "age"
drop _merge
save "$data_root/working/het_occ2010/main_age.dta", replace


********************************************* P4T (Oct 2024 - March 2025); Educ *******************************************

use "$data_root/working/het_occ2010/occ2010_het_all.dta", clear

* Keep P4T 
keep if ((year == 2025 & (month == 1 | month == 2 | month == 3)) | (year == 2024 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "educ"


* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010 educ_group)


* Rename variables to specify they are from P4T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P4T_educ
}

save "$data_root/working/het_occ2010/P4T_educ.dta", replace

********************************************* P2T (Oct 2022 - March 2023); Educ *******************************************

use "$data_root/working/het_occ2010/occ2010_het_all.dta", clear

* Keep P2T 
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "educ"

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010 educ_group)


* Rename variables to specify they are from P2T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P2T_educ
}

save "$data_root/working/het_occ2010/P2T_educ.dta", replace
merge 1:1 occ2010 educ_group using "$data_root/working/het_occ2010/P4T_educ.dta"
gen split_type = "educ"
drop _merge
save "$data_root/working/het_occ2010/main_educ.dta", replace

********************************************* P4T (Oct 2024 - March 2025); Sex *******************************************

use "$data_root/working/het_occ2010/occ2010_het_all.dta", clear

* Keep P4T 
keep if ((year == 2025 & (month == 1 | month == 2 | month == 3)) | (year == 2024 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "gender"

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010 sex)


* Rename variables to specify they are from P4T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P4T_sex
}

save "$data_root/working/het_occ2010/P4T_sex.dta", replace

********************************************* P2T (Oct 2022 - March 2023); Sex *******************************************

use "$data_root/working/het_occ2010/occ2010_het_all.dta", clear

* Keep P2T 
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "gender"

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010 sex)


* Rename variables to specify they are from P2T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P2T_sex
}

save "$data_root/working/het_occ2010/P2T_sex.dta", replace
merge 1:1 occ2010 sex using "$data_root/working/het_occ2010/P4T_sex.dta"
gen split_type = "sex"
drop _merge
save "$data_root/working/het_occ2010/main_sex.dta", replace

********************************************* P4T (Oct 2024 - March 2025); Region *******************************************

use "$data_root/working/het_occ2010/occ2010_het_all.dta", clear

* Keep P4T 
keep if ((year == 2025 & (month == 1 | month == 2 | month == 3)) | (year == 2024 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "region"

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010 region_major)


* Rename variables to specify they are from P4T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P4T_region
}

save "$data_root/working/het_occ2010/P4T_region.dta", replace

********************************************* P2T (Oct 2022 - March 2023); Region *******************************************

use "$data_root/working/het_occ2010/occ2010_het_all.dta", clear

* Keep P2T 
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "region"

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010 region_major)


* Rename variables to specify they are from P2T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P2T_region
}

save "$data_root/working/het_occ2010/P2T_region.dta", replace
merge 1:1 occ2010 region_major using "$data_root/working/het_occ2010/P4T_region.dta"
gen split_type = "region"
drop _merge
save "$data_root/working/het_occ2010/main_region.dta", replace

********************************************* P4T (Oct 2024 - March 2025); Region V2 *******************************************

use "$data_root/working/het_occ2010/occ2010_het_region_group.dta", clear

* Keep P4T 
keep if ((year == 2025 & (month == 1 | month == 2 | month == 3)) | (year == 2024 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "region_group"

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_westC prop_eastC ///
prop_otherC prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010 region_group)


* Rename variables to specify they are from P4T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_westC prop_eastC ///
prop_otherC prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P4T_region
}

save "$data_root/working/het_occ2010/P4T_region_group.dta", replace

********************************************* P2T (Oct 2022 - March 2023); Region V2 *******************************************

use "$data_root/working/het_occ2010/occ2010_het_region_group.dta", clear

* Keep P2T 
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "region_group"

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_westC prop_eastC ///
prop_otherC prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010 region_group)


* Rename variables to specify they are from P2T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_westC prop_eastC ///
prop_otherC prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P2T_region
}

save "$data_root/working/het_occ2010/P2T_region_group.dta", replace
merge 1:1 occ2010 region_group using "$data_root/working/het_occ2010/P4T_region_group.dta"
gen split_type = "region"
drop _merge
save "$data_root/working/het_occ2010/main_region_group.dta", replace

********************************************* P4T (Oct 2024 - March 2025); Region V3 *******************************************

use "$data_root/working/het_occ2010/occ2010_het_region_rust.dta", clear

* Keep P4T 
keep if ((year == 2025 & (month == 1 | month == 2 | month == 3)) | (year == 2024 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "region_rust"

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_rust prop_nonrust ///
prop_educ_* prop_fem prop_male openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, by(occ2010 region_rust)


* Rename variables to specify they are from P4T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_rust prop_nonrust ///
prop_educ_* prop_fem prop_male openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P4T_region
}

save "$data_root/working/het_occ2010/P4T_region_rust.dta", replace

********************************************* P2T (Oct 2022 - March 2023); Region V3 *******************************************

use "$data_root/working/het_occ2010/occ2010_het_region_rust.dta", clear

* Keep P2T 
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "region_rust"

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_rust prop_nonrust ///
prop_educ_* prop_fem prop_male openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, by(occ2010 region_rust)


* Rename variables to specify they are from P2T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_rust prop_nonrust ///
prop_educ_* prop_fem prop_male openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P2T_region
}

save "$data_root/working/het_occ2010/P2T_region_rust.dta", replace
merge 1:1 occ2010 region_rust using "$data_root/working/het_occ2010/P4T_region_rust.dta"
gen split_type = "region_rust"
drop _merge
save "$data_root/working/het_occ2010/main_region_rust.dta", replace

********************************************* P4T (Oct 2024 - March 2025); Race *******************************************

use "$data_root/working/het_occ2010/occ2010_het_all.dta", clear

* Keep P4T 
keep if ((year == 2025 & (month == 1 | month == 2 | month == 3)) | (year == 2024 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "race"


* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010 race_group)


* Rename variables to specify they are from P4T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P4T_race
}

save "$data_root/working/het_occ2010/P4T_race.dta", replace

********************************************* P2T (Oct 2022 - March 2023); Race *******************************************

use "$data_root/working/het_occ2010/occ2010_het_all.dta", clear

* Keep P2T 
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "race"

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010 race_group)


* Rename variables to specify they are from P2T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_pacific prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P2T_race
}

save "$data_root/working/het_occ2010/P2T_race.dta", replace
merge 1:1 occ2010 race_group using "$data_root/working/het_occ2010/P4T_race.dta"
gen split_type = "race"
drop _merge
save "$data_root/working/het_occ2010/main_race.dta", replace


********************************************* P4T (Oct 2024 - March 2025); Industry *******************************************

use "$data_root/working/het_occ2010/occ2010_het_ind1990.dta", clear

* Keep P4T 
keep if ((year == 2025 & (month == 1 | month == 2 | month == 3)) | (year == 2024 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "ind1990"


* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010 ind1990_group)


* Rename variables to specify they are from P4T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P4T_ind
}

save "$data_root/working/het_occ2010/P4T_ind.dta", replace

********************************************* P2T (Oct 2022 - March 2023); Industry *******************************************

use "$data_root/working/het_occ2010/occ2010_het_ind1990.dta", clear

* Keep P2T 
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
keep if split_type == "ind1990"

* Collapse to occupation-level averages for outcome and control variables
collapse (mean) demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean, ///
by(occ2010 ind1990_group)


* Rename variables to specify they are from P2T
foreach var of varlist demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_northeast prop_midwest ///
prop_south prop_west prop_educ_* prop_fem prop_male ///
openai* claude* EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
    rename `var' `var'_P2T_ind
}

save "$data_root/working/het_occ2010/P2T_ind.dta", replace
merge 1:1 occ2010 ind1990_group using "$data_root/working/het_occ2010/P4T_ind.dta"
gen split_type = "ind1990"
drop _merge
save "$data_root/working/het_occ2010/main_ind.dta", replace

*******************************************************************************************************************************************
********************************************************** Computing Differences **********************************************************
*******************************************************************************************************************************************

******************************************************************* Age *******************************************************************
use "$data_root/working/het_occ2010/main_age.dta", clear
rename openai*_occ2010_P2T_age openai*_occ2010
rename claude*_occ2010_P2T_age claude*_occ2010
foreach model in openai claude {
	gen d_`model'_S2_S1 = `model'2_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S1 = `model'3_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S2 = `model'3_occ2010 - `model'2_occ2010
}

* Creating P2T - P4T Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_26less prop_age_26to55 prop_age_55plus ///
prop_white prop_black prop_asian prop_other prop_northeast prop_midwest prop_south prop_west prop_male ///
prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime EW_2010_Base log_EW_base EW_2010_clean ///
log_EW_clean {
	gen d_`var'_P2T4T_age = `var'_P4T_age - `var'_P2T_age
}
save "$data_root/working/het_occ2010/diff_age.dta", replace

******************************************************************* Educ ******************************************************************
use "$data_root/working/het_occ2010/main_educ.dta", clear
rename openai*_occ2010_P2T_educ openai*_occ2010
rename claude*_occ2010_P2T_educ claude*_occ2010
foreach model in openai claude {
	gen d_`model'_S2_S1 = `model'2_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S1 = `model'3_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S2 = `model'3_occ2010 - `model'2_occ2010
}

* Creating P2T - P4T Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_26less prop_age_26to55 prop_age_55plus ///
prop_white prop_black prop_asian prop_other prop_northeast prop_midwest prop_south prop_west prop_male ///
prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime EW_2010_Base log_EW_base EW_2010_clean ///
log_EW_clean {
	gen d_`var'_P2T_P4T_educ = `var'_P4T_educ - `var'_P2T_educ
}
save "$data_root/working/het_occ2010/diff_educ.dta", replace

******************************************************************* Sex *******************************************************************
use "$data_root/working/het_occ2010/main_sex.dta", clear
rename openai*_occ2010_P2T_sex openai*_occ2010
rename claude*_occ2010_P2T_sex claude*_occ2010
foreach model in openai claude {
	gen d_`model'_S2_S1 = `model'2_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S1 = `model'3_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S2 = `model'3_occ2010 - `model'2_occ2010
}

* Creating P2T - P4T Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_26less prop_age_26to55 prop_age_55plus ///
prop_white prop_black prop_asian prop_other prop_northeast prop_midwest prop_south prop_west prop_male ///
prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime EW_2010_Base log_EW_base EW_2010_clean ///
log_EW_clean {
	gen d_`var'_P2T_P4T_sex = `var'_P4T_sex - `var'_P2T_sex
}
save "$data_root/working/het_occ2010/diff_sex.dta", replace

******************************************************************* Region ****************************************************************
use "$data_root/working/het_occ2010/main_region.dta", clear
rename openai*_occ2010_P2T_region openai*_occ2010
rename claude*_occ2010_P2T_region claude*_occ2010
foreach model in openai claude {
	gen d_`model'_S2_S1 = `model'2_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S1 = `model'3_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S2 = `model'3_occ2010 - `model'2_occ2010
}

* Creating P2T - P4T Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_26less prop_age_26to55 prop_age_55plus ///
prop_white prop_black prop_asian prop_other prop_northeast prop_midwest prop_south prop_west prop_male ///
prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime EW_2010_Base log_EW_base EW_2010_clean ///
log_EW_clean {
	gen d_`var'_P2T_P4T_reg = `var'_P4T_region - `var'_P2T_region
}

save "$data_root/working/het_occ2010/diff_region.dta", replace

******************************************************************* Region V2 ****************************************************************
use "$data_root/working/het_occ2010/main_region_group.dta", clear
rename openai*_occ2010_P2T_region openai*_occ2010
rename claude*_occ2010_P2T_region claude*_occ2010
foreach model in openai claude {
	gen d_`model'_S2_S1 = `model'2_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S1 = `model'3_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S2 = `model'3_occ2010 - `model'2_occ2010
}

* Creating P2T - P4T Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_26less prop_age_26to55 prop_age_55plus ///
prop_white prop_black prop_asian prop_other prop_westC prop_eastC prop_otherC prop_male ///
prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime EW_2010_Base log_EW_base EW_2010_clean ///
log_EW_clean {
	gen d_`var'_P2T_P4T_reg = `var'_P4T_region - `var'_P2T_region
}

save "$data_root/working/het_occ2010/diff_region_group.dta", replace

******************************************************************* Region V3 ****************************************************************
use "$data_root/working/het_occ2010/main_region_rust.dta", clear
rename openai*_occ2010_P2T_region openai*_occ2010
rename claude*_occ2010_P2T_region claude*_occ2010
foreach model in openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5 {
	replace `model'_occ2010 = `model'_occ2010_P4T_region if missing(`model'_occ2010)
}

foreach model in openai claude {
	gen d_`model'_S2_S1 = `model'2_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S1 = `model'3_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S2 = `model'3_occ2010 - `model'2_occ2010
}

* Creating P2T - P4T Outcomes & Controls
foreach var in demployed Dunemp unemp_rate ahrswork1 ahrsworkt log_emp other_job new_wrk_acts ahrswork2 fulltime ///
prop_age_26less prop_age_26to55 prop_age_55plus prop_white prop_black prop_asian prop_other prop_rust prop_nonrust ///
prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem prop_male EW_2010_Base log_EW_base EW_2010_clean log_EW_clean {
	gen d_`var'_P2T_P4T_reg = `var'_P4T_region - `var'_P2T_region
}

save "$data_root/working/het_occ2010/diff_region_rust.dta", replace


******************************************************************* Race ******************************************************************
use "$data_root/working/het_occ2010/main_race.dta", clear
rename openai*_occ2010_P2T_race openai*_occ2010
rename claude*_occ2010_P2T_race claude*_occ2010
foreach model in openai claude {
	gen d_`model'_S2_S1 = `model'2_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S1 = `model'3_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S2 = `model'3_occ2010 - `model'2_occ2010
}

* Creating P2T - P4T Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_26less prop_age_26to55 prop_age_55plus ///
prop_white prop_black prop_asian prop_other prop_northeast prop_midwest prop_south prop_west prop_male ///
prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime EW_2010_Base log_EW_base EW_2010_clean ///
log_EW_clean {
	gen d_`var'_P2T_P4T_race = `var'_P4T_race - `var'_P2T_race
}

save "$data_root/working/het_occ2010/diff_race.dta", replace

******************************************************************* Und1990 ******************************************************************
use "$data_root/working/het_occ2010/main_ind.dta", clear
rename openai*_occ2010_P2T_ind openai*_occ2010
rename claude*_occ2010_P2T_ind claude*_occ2010
foreach model in openai claude {
	gen d_`model'_S2_S1 = `model'2_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S1 = `model'3_occ2010 - `model'1_occ2010
	gen d_`model'_S3_S2 = `model'3_occ2010 - `model'2_occ2010
}

* Creating P2T - P4T Outcomes & Controls
foreach var in demployed log_emp Dunemp unemp_rate ahrswork1 ahrsworkt ahrswork2 prop_age_26less prop_age_26to55 prop_age_55plus ///
prop_white prop_black prop_asian prop_other prop_northeast prop_midwest prop_south prop_west prop_male ///
prop_educ_q1 prop_educ_q2 prop_educ_q3 prop_educ_q4 prop_fem other_job new_wrk_acts fulltime EW_2010_Base log_EW_base EW_2010_clean ///
log_EW_clean {
	gen d_`var'_P2T_P4T_ind = `var'_P4T_ind - `var'_P2T_ind
}

save "$data_root/working/het_occ2010/diff_ind.dta", replace

*******************************************************************************************************************************************
************************************************************ Computing Weights ************************************************************
*******************************************************************************************************************************************

*************************************************************** P2T (Age) **************************************************************** 
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
label value occ2010
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month agegroup)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010 agegroup)
count if tag == 6
list occ2010 agegroup tag if tag < 6
restore

*** Define the list of combinations and tags ***
clear
input occ2010 agegroup tag
100 1 3
130 1 5
150 1 2
300 1 3
360 1 3
360 3 4
500 1 2
510 1 3
510 2 5
600 1 4
820 1 3
830 1 5
860 1 5
900 3 4
930 1 2
950 3 5
1100 1 3
1300 1 4
1320 1 5
1400 1 3
1440 1 1
1440 3 2
1450 1 5
1520 3 3
1540 1 5
1600 1 1
1600 3 4
1640 1 4
1650 1 3
1700 1 2
1710 3 3
1720 1 4
1740 1 4
1800 1 2
1800 3 4
1830 1 3
1840 1 5
1840 3 5
1900 1 5
1910 1 5
1920 3 5
2020 3 5
2050 1 5
2440 1 3
2440 3 5
2740 1 4
2740 2 4
2800 1 4
2800 3 1
2840 1 5
2900 1 4
3000 1 5
3010 1 4
3030 1 5
3060 1 1
3140 1 3
3140 3 3
3200 3 4
3210 1 2
3210 3 5
3220 1 2
3310 1 5
3520 3 5
3610 1 5
3700 1 2
3700 3 5
3730 1 2
3750 1 4
3900 1 1
3900 3 4
3910 1 5
3940 1 5
3940 3 5
4240 1 5
4340 3 5
4400 1 4
4420 2 5
4640 3 3
4900 1 4
4900 3 4
4930 1 3
4930 3 4
4940 1 1
4940 3 4
5010 1 4
5010 3 5
5020 3 3
5140 1 5
5150 1 4
5220 1 4
5230 1 2
5250 1 1
5260 1 5
5340 3 2
5500 1 2
5500 3 4
5530 1 4
5530 3 4
5560 1 4
5820 1 5
5820 3 5
5900 3 3
5910 1 4
5910 3 1
5920 1 4
6005 3 5
6010 1 4
6040 1 5
6100 1 5
6100 3 5
6120 1 5
6120 2 5
6130 1 5
6360 3 5
6400 3 5
6460 1 1
6460 3 5
6660 1 3
6700 1 4
6710 3 3
6720 1 5
6740 1 3
6740 3 4
6800 1 3
6820 3 3
6830 1 4
6840 3 4
7010 1 5
7030 1 2
7030 3 3
7040 1 4
7040 3 3
7100 1 3
7100 3 3
7120 3 3
7130 1 5
7130 3 4
7160 3 4
7240 1 5
7240 3 5
7320 1 4
7350 1 1
7360 1 5
7430 1 3
7510 1 2
7510 3 5
7540 1 2
7560 1 2
7610 1 5
7730 2 4
7740 3 4
7830 1 4
7830 3 2
7850 1 4
7850 2 4
7850 3 3
7900 3 5
7920 1 5
8000 1 2
8010 1 1
8010 2 4
8040 1 2
8040 3 2
8100 1 1
8100 3 3
8130 1 4
8250 1 2
8250 3 3
8310 1 2
8310 2 5
8320 1 5
8330 2 4
8330 3 2
8350 1 3
8420 3 5
8460 1 3
8460 3 2
8500 1 5
8510 1 1
8510 2 5
8510 3 4
8530 3 1
8540 1 5
8540 3 5
8550 1 4
8550 3 5
8600 1 5
8610 1 4
8620 1 5
8630 1 5
8640 1 5
8640 3 5
8710 1 5
8720 1 1
8720 3 2
8730 1 1
8730 2 5
8730 3 4
8750 1 5
8830 3 4
8850 1 1
8910 2 3
8910 3 3
8920 1 5
8920 3 5
8930 1 2
8930 3 5
8940 1 2
8940 3 3
9040 1 1
9040 3 5
9200 1 1
9240 1 4
9240 3 5
9260 1 4
9260 3 5
9300 1 2
9300 3 2
9310 1 2
9310 3 5
9360 3 5
9410 1 1
9420 1 3
9510 1 4
9510 3 5
9560 1 4
9630 3 5
9650 1 2
9720 3 4
end

gen n_missing = 6 - tag

* ---- Step 2: Append missing rows to your current data in memory ----
tempfile missing_rows
save `missing_rows'

use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
label value occ2010
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month agegroup)

* Loop over each row in the missing data and insert appropriate number of missing rows
preserve
use `missing_rows', clear
gen count = 0
expand n_missing
drop tag n_missing

tempfile to_append
save `to_append', replace
restore

append using `to_append'


gen tag = 1
preserve
collapse (sum) tag, by(occ2010 agegroup)
count if tag == 6
list occ2010 tag if tag < 6 | tag > 6
restore

collapse (mean) count, by (occ2010 agegroup)
rename count freq_wt_P2T_age

merge 1:1 occ2010 agegroup using "$data_root/working/het_occ2010/diff_age.dta"
br if _merge == 2
*** 7 occupation groups don't appear in P2T. The occupations don't recieve differenced outcomes.
drop _merge

*** Adding task indices ***
merge m:1 occ2010 using "$data_root/Cleaned/task_indices_occ2010.dta"
label values occ2010
br if _merge == 1

*** As before, missing task indices for financial analysts, Entertainers and Performers, Sports and Related Workers, All Other, Emergency Medical Technicians and Paramedics, Medical Records and Health Information Technicians, Supervisors, Protective Service Workers, All Other, Sales Representatives, Services, All Other, Fishing and hunting workers, and Taxi Drivers and Chauffeurs.

save "$data_root/Cleaned/het_occ2010/het_ageV1.dta", replace

*************************************************************** P2T (Educ) *************************************************************** 
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
label value occ2010
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month educ_group)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010 educ_group)
count if tag == 6
list occ2010 educ_group tag if tag < 6
restore

*** Define the list of combinations and tags ***
clear
input occ2010 educ_group tag
100 1 2
110 1 3
130 1 2
150 1 2
230 1 5
300 1 2
360 2 1
420 1 4
510 2 4
510 3 4
510 4 3
520 1 5
520 4 5
530 1 5
540 1 5
560 1 3
600 1 3
700 1 2
710 1 3
720 1 2
730 1 4
820 2 5
900 2 3
900 4 4
910 1 3
930 1 2
940 1 4
1000 1 4
1010 1 1
1020 1 5
1100 1 2
1240 1 3
1300 1 1
1420 1 1
1420 2 5
1440 3 4
1440 4 3
1450 2 5
1460 1 1
1520 1 1
1520 2 5
1520 4 4
1530 1 3
1540 4 4
1550 1 5
1560 1 3
1560 4 2
1650 3 4
1700 3 3
1710 2 1
1710 3 3
1800 3 4
1900 1 5
1900 4 3
1910 4 5
1920 1 4
1960 1 4
2020 1 1
2040 1 5
2100 1 3
2150 1 4
2200 1 3
2330 1 4
2440 3 5
2700 1 3
2740 2 2
2740 3 4
2740 4 2
2750 1 5
2760 1 2
2760 4 5
2800 4 2
2850 1 1
2860 1 4
2900 1 3
2910 1 4
2920 1 5
2920 4 5
3000 3 5
3050 2 5
3140 3 5
3150 2 5
3160 1 1
3200 2 4
3200 4 3
3210 3 5
3210 4 5
3220 4 5
3230 2 4
3240 1 4
3310 1 3
3320 1 2
3400 1 2
3510 4 5
3520 1 1
3520 4 1
3530 1 3
3610 4 3
3620 4 2
3630 1 5
3640 4 3
3700 4 4
3720 1 2
3730 1 5
3730 4 3
3740 1 3
3750 1 3
3750 4 2
3800 1 4
3900 3 1
3900 4 4
3940 1 3
3940 3 2
3940 4 1
4050 4 5
4130 4 4
4140 4 1
4150 4 1
4210 4 2
4240 1 2
4240 3 5
4240 4 1
4320 1 5
4340 1 5
4400 4 4
4420 1 5
4420 3 3
4420 4 2
4430 4 3
4500 3 5
4500 4 1
4510 4 5
4520 4 5
4530 3 5
4530 4 3
4540 1 1
4640 4 5
4740 1 4
4740 4 4
4750 4 2
4800 1 1
4810 1 5
4830 4 5
4840 1 5
4900 1 1
4900 3 5
4900 4 4
4930 4 5
4940 1 2
4940 4 2
4950 1 4
4950 4 5
5010 3 4
5020 3 5
5100 3 5
5100 4 4
5150 4 5
5160 1 3
5160 4 4
5165 1 5
5220 1 1
5220 4 4
5230 3 4
5230 4 5
5250 4 4
5260 1 5
5300 1 5
5300 4 4
5310 1 4
5310 4 5
5320 4 5
5330 1 3
5340 3 5
5340 4 3
5350 1 5
5350 4 2
5360 1 1
5360 4 5
5410 4 2
5420 1 3
5420 4 4
5500 4 1
5530 3 3
5540 1 2
5540 4 1
5560 1 2
5560 3 5
5600 1 4
5610 4 5
5630 4 2
5810 1 3
5820 4 2
5840 1 1
5840 4 5
5850 1 4
5850 3 4
5850 4 2
5900 1 1
5900 4 4
5910 2 1
5910 3 4
5920 4 5
6005 3 5
6005 4 3
6010 3 4
6040 3 4
6040 4 1
6100 1 2
6100 4 2
6120 2 4
6120 3 5
6120 4 2
6200 4 5
6210 1 2
6210 3 1
6240 4 2
6250 3 5
6320 4 2
6330 3 5
6330 4 4
6360 1 1
6400 3 2
6420 4 5
6460 3 1
6520 1 3
6520 3 5
6520 4 4
6530 1 4
6530 3 2
6530 4 3
6600 3 4
6660 1 1
6660 4 5
6700 1 3
6700 3 4
6700 4 2
6710 1 5
6710 3 5
6720 3 1
6740 1 3
6800 3 1
6820 1 3
6820 4 2
6830 3 1
6840 1 5
6840 3 5
6940 1 5
6940 3 5
6940 4 2
7010 4 4
7020 1 5
7020 4 4
7030 3 5
7040 1 1
7040 3 4
7100 3 1
7100 4 1
7120 1 1
7120 3 5
7120 4 2
7130 1 4
7130 3 3
7140 1 2
7140 4 3
7150 4 3
7160 1 2
7200 4 5
7210 4 2
7240 1 5
7240 3 5
7300 1 3
7300 3 1
7315 4 2
7320 1 5
7330 4 5
7350 1 2
7350 3 2
7360 1 4
7410 4 1
7420 1 4
7420 4 3
7430 1 4
7430 4 2
7510 1 1
7510 3 4
7510 4 1
7540 1 1
7540 3 1
7540 4 4
7560 2 5
7720 1 5
7720 4 1
7730 4 1
7740 3 2
7800 4 4
7810 4 1
7830 1 2
7830 2 4
7830 3 4
7830 4 1
7840 3 3
7900 1 5
7900 4 1
7920 1 2
7920 3 4
7950 1 4
7950 3 2
7950 4 4
8000 1 1
8010 2 4
8030 4 1
8040 3 2
8100 1 5
8130 1 3
8140 4 1
8220 4 4
8230 4 2
8250 3 4
8250 4 3
8300 4 2
8310 1 5
8310 3 1
8320 4 5
8330 1 1
8330 2 3
8330 3 1
8350 1 1
8420 1 4
8420 3 4
8450 1 3
8450 2 5
8450 3 1
8450 4 1
8460 1 4
8500 1 3
8500 3 2
8510 1 3
8510 2 2
8510 3 5
8510 4 1
8540 1 4
8540 3 2
8550 1 2
8550 3 2
8550 4 2
8600 4 5
8610 4 4
8620 1 2
8620 3 5
8620 4 4
8630 1 1
8640 1 4
8650 3 5
8650 4 1
8710 3 2
8720 1 4
8720 3 4
8730 2 5
8730 3 3
8750 1 5
8750 4 4
8760 1 1
8760 4 2
8800 4 5
8810 3 5
8810 4 2
8830 4 4
8910 2 3
8910 3 3
8920 1 5
8920 3 5
8930 1 2
8930 3 1
8940 1 3
8950 1 5
8950 4 2
9030 1 4
9040 4 3
9050 1 3
9050 4 5
9200 4 3
9240 1 2
9240 4 5
9260 3 4
9260 4 3
9300 1 2
9300 3 3
9310 4 5
9350 3 4
9350 4 2
9360 4 1
9410 1 5
9410 4 3
9420 1 1
9420 4 1
9510 3 4
9560 1 4
9600 4 3
9630 1 5
9630 3 4
9630 4 2
9640 4 3
9720 3 4
9750 3 3
end


gen n_missing = 6 - tag
gen count = 0
expand n_missing
drop tag n_missing

tempfile to_add
save `to_add'

use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
label values occ2010
gen count = 1
collapse (sum) count, by (occ2010 month educ_group)
append using `to_add'

gen tag = 1
preserve
collapse (sum) tag, by(occ2010 educ_group)
count if tag == 6
list occ2010 educ_group tag if tag < 6 | tag > 6
restore

collapse (mean) count, by (occ2010 educ_group)
rename count freq_wt_P2T_educ

merge 1:1 occ2010 educ_group using "$data_root/working/het_occ2010/diff_educ.dta"
br if _merge == 2
*** 70 occupation-education groups don't appear in P2T. The occupations don't recieve differenced outcomes.
drop _merge

*** Adding task indices ***
merge m:1 occ2010 using "$data_root/Cleaned/task_indices_occ2010.dta"
label values occ2010
br if _merge == 1

*** As before, missing task indices for financial analysts, Entertainers and Performers, Sports and Related Workers, All Other, Emergency Medical Technicians and Paramedics, Medical Records and Health Information Technicians, Supervisors, Protective Service Workers, All Other, Sales Representatives, Services, All Other, Fishing and hunting workers, and Taxi Drivers and Chauffeurs.

save "$data_root/Cleaned/het_occ2010/het_educV1.dta", replace

*************************************************************** P2T (Sex) **************************************************************** 
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
label value occ2010
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month sex)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010 sex)
count if tag == 6
list occ2010 sex tag if tag < 6
restore

*** Define the list of combinations and tags ***
clear
input occ2010 sex tag
510 1 5
510 2 4
900 2 2
1440 2 3
1450 2 5
1710 2 2
2740 1 4
2740 2 4
3120 2 2
3140 1 3
3200 1 1
3230 1 5
3520 1 4
3720 2 4
3900 1 3
4930 2 4
4940 1 4
5010 1 5
5340 1 2
5360 1 5
5820 1 3
5910 2 5
6100 2 5
6120 1 5
6120 2 3
6130 2 2
6210 2 2
6220 2 3
6250 2 4
6330 2 2
6360 2 1
6400 2 4
6530 2 3
6600 2 2
6660 2 4
6720 2 3
6730 2 1
6765 2 3
6800 2 1
6820 2 1
6830 2 1
6840 2 3
6940 2 4
7020 2 5
7100 2 1
7120 2 1
7130 2 4
7160 2 5
7210 2 5
7220 2 5
7240 2 1
7260 2 1
7320 2 5
7360 2 5
7410 2 4
7420 2 4
7430 2 3
7510 2 5
7540 2 4
7610 2 2
7730 2 1
7830 2 5
7850 2 4
7900 2 4
8000 2 4
8010 1 4
8040 2 2
8100 2 5
8130 2 4
8250 2 2
8330 1 2
8330 2 4
8450 2 3
8460 2 4
8500 2 5
8510 1 5
8510 2 4
8530 2 2
8540 2 5
8550 2 3
8600 2 5
8610 2 2
8620 2 3
8630 2 2
8720 2 2
8730 1 5
8730 2 3
8830 1 3
8910 1 3
8910 2 3
8920 2 2
9200 2 5
9240 2 3
9260 2 3
9300 2 3
9350 2 5
9410 2 4
9420 2 5
9510 2 1
end


gen n_missing = 6 - tag
gen count = 0
expand n_missing
drop tag n_missing

tempfile to_add

save `to_add'


use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
label value occ2010
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month sex)
append using `to_add'

gen tag = 1
preserve
collapse (sum) tag, by(occ2010 sex)
count if tag == 6
list occ2010 sex tag if tag < 6 | tag > 6
restore

collapse (mean) count, by (occ2010 sex)
rename count freq_wt_P2T_sex

merge 1:1 occ2010 sex using "$data_root/working/het_occ2010/diff_sex.dta"
br if _merge == 2
*** 12 occupations-sex cells don't appear in P2T, all of which are female. The occupations don't recieve differenced outcomes.
drop _merge

*** Adding task indices ***
merge m:1 occ2010 using "$data_root/Cleaned/task_indices_occ2010.dta"
label values occ2010
br if _merge == 1

*** As before, missing task indices for financial analysts, Entertainers and Performers, Sports and Related Workers, All Other, Emergency Medical Technicians and Paramedics, Medical Records and Health Information Technicians, Supervisors, Protective Service Workers, All Other, Sales Representatives, Services, All Other, Fishing and hunting workers, and Taxi Drivers and Chauffeurs.

save "$data_root/Cleaned/het_occ2010/het_sexV1.dta", replace

************************************************************** P2T (Region) ************************************************************** 
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
label value occ2010
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month region_major)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010 region_major)
count if tag == 6
list occ2010 region_major tag if tag < 6
restore

*** Define the list of combinations and tags ***
clear
input occ2010 region_major tag
360 1 5
500 1 4
500 2 5
510 1 4
510 2 1
510 3 2
510 4 3
810 2 5
900 1 4
900 2 2
900 3 4
900 4 2
1200 3 4
1200 4 5
1400 2 5
1420 1 4
1440 1 3
1440 3 4
1440 4 3
1450 1 5
1520 2 5
1520 4 5
1600 3 5
1700 2 4
1700 3 4
1710 1 3
1710 2 2
1710 3 4
1710 4 3
1720 2 4
1800 1 4
1800 2 4
1800 4 5
1830 1 3
1840 1 4
1840 2 4
1910 1 4
2440 1 5
2440 2 5
2440 4 5
2740 1 3
2740 2 2
2740 3 2
2740 4 2
2760 2 5
2800 1 2
2800 2 4
2800 3 5
2920 2 5
3000 1 5
3040 1 5
3120 2 3
3120 4 2
3140 2 5
3140 4 4
3200 1 2
3200 2 2
3200 4 5
3210 1 5
3210 2 5
3210 4 4
3260 2 1
3610 1 5
3730 1 5
3750 1 2
3900 3 2
3900 4 5
3940 2 1
4400 2 5
4420 1 5
4420 2 5
4420 3 4
4460 4 4
4540 2 4
4900 1 3
4900 2 5
4900 3 4
4930 1 5
4930 2 4
4940 1 4
4940 2 3
4940 4 5
5010 4 5
5020 2 4
5020 3 4
5150 4 5
5340 1 1
5340 2 5
5340 3 5
5340 4 2
5360 1 5
5500 1 4
5530 1 5
5530 4 4
5820 1 5
5850 4 4
5900 1 4
5900 4 4
5910 1 4
5910 3 1
5920 1 3
6010 1 3
6010 4 4
6040 1 3
6040 2 5
6100 1 4
6100 2 5
6120 1 1
6120 2 2
6120 3 5
6120 4 3
6130 2 4
6210 1 5
6210 2 5
6330 1 5
6360 3 5
6460 1 1
6460 2 5
6460 3 1
6600 1 5
6600 2 5
6600 4 2
6710 1 4
6710 4 4
6720 1 4
6720 3 4
6740 1 5
6740 2 1
6765 1 5
6800 1 3
6800 2 5
6800 4 5
6820 1 1
6820 2 5
6830 1 1
6830 2 3
6830 4 4
6940 1 4
7030 1 2
7030 2 5
7030 3 5
7030 4 4
7040 1 5
7040 2 5
7040 3 5
7040 4 3
7100 1 3
7100 2 4
7100 4 1
7120 1 3
7120 2 4
7130 1 5
7160 4 5
7240 1 5
7300 1 2
7300 4 4
7320 2 3
7350 2 4
7360 1 3
7510 1 2
7540 1 3
7540 2 4
7560 1 5
7560 3 4
7610 1 4
7610 2 1
7610 3 5
7610 4 5
7730 1 1
7730 2 4
7730 3 4
7740 1 3
7740 2 5
7740 3 4
7740 4 5
7830 1 5
7830 3 5
7830 4 5
7840 1 5
7850 1 2
7850 2 5
7850 3 5
7920 4 5
7950 1 2
8000 1 2
8000 4 1
8010 1 1
8010 2 4
8040 1 4
8100 1 1
8250 1 5
8250 2 5
8250 4 4
8310 1 5
8310 2 3
8310 3 5
8310 4 3
8330 1 3
8330 2 3
8330 3 2
8330 4 3
8420 2 4
8420 4 2
8450 1 3
8450 2 4
8450 4 3
8460 2 1
8460 4 1
8500 2 4
8500 4 5
8510 1 2
8510 2 4
8510 3 1
8510 4 5
8530 1 5
8530 4 3
8550 2 3
8550 3 4
8550 4 5
8600 1 4
8600 4 5
8630 1 4
8710 1 4
8720 1 5
8720 2 3
8720 3 4
8720 4 5
8730 1 3
8730 2 4
8730 3 5
8730 4 4
8750 1 5
8830 1 5
8830 4 4
8850 1 1
8850 4 5
8910 1 1
8910 4 3
8920 2 5
8920 3 3
8930 1 5
8930 2 4
8940 1 3
8940 2 3
8940 3 3
8940 4 2
9040 2 5
9200 1 2
9240 1 4
9260 1 3
9260 2 4
9260 4 5
9300 1 2
9300 3 4
9310 2 1
9310 4 5
9350 2 3
9350 3 5
9360 1 5
9410 1 5
9410 2 4
9420 2 3
9560 3 5
9560 4 5
9630 1 4
9630 2 3
9650 1 1
9650 2 5
end


gen n_missing = 6 - tag
gen count = 0
expand n_missing
drop tag n_missing

tempfile to_add

save `to_add'


use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
label value occ2010
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month region_major)
append using `to_add'

gen tag = 1
preserve
collapse (sum) tag, by(occ2010 region_major)
count if tag == 6
list occ2010 region_major tag if tag < 6 | tag > 6
restore

collapse (mean) count, by (occ2010 region_major)
rename count freq_wt_P2T_region

merge 1:1 occ2010 region_major using "$data_root/working/het_occ2010/diff_region.dta"
br if _merge == 2
*** 21 occupations-region cells don't appear in P2T. The occupations don't recieve differenced outcomes.
drop _merge

*** Adding task indices ***
merge m:1 occ2010 using "$data_root/Cleaned/task_indices_occ2010.dta"
label values occ2010
br if _merge == 1

*** As before, missing task indices for financial analysts, Entertainers and Performers, Sports and Related Workers, All Other, Emergency Medical Technicians and Paramedics, Medical Records and Health Information Technicians, Supervisors, Protective Service Workers, All Other, Sales Representatives, Services, All Other, Fishing and hunting workers, and Taxi Drivers and Chauffeurs.

save "$data_root/Cleaned/het_occ2010/het_regionV1.dta", replace

************************************************************** P2T (Region V2) ************************************************************** 
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
label value occ2010
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month region_group)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010 region_group)
count if tag == 6
list occ2010 region_group tag if tag < 6
restore

*** Define the list of combinations and tags ***
clear
input occ2010 region_group tag
360 1 5
500 1 4
500 2 5
510 2 4
510 3 5
600 1 5
820 1 3
900 1 1
1200 1 3
1310 2 3
1420 1 5
1420 2 4
1440 1 3
1440 2 5
1440 3 2
1450 2 5
1600 1 4
1700 1 4
1710 1 2
1710 2 3
1710 3 5
1800 1 2
1830 1 5
1830 2 3
1910 1 5
1910 2 5
1920 1 5
2050 1 4
2440 1 2
2740 1 2
2740 2 3
2740 3 4
2800 1 5
2800 2 3
2860 1 5
3000 2 5
3040 1 5
3040 2 5
3120 1 2
3120 3 3
3140 1 2
3140 2 1
3200 1 2
3200 2 2
3210 1 4
3210 2 5
3220 1 4
3530 1 5
3610 1 3
3610 2 5
3720 1 3
3750 1 3
3750 2 5
3900 1 2
3940 1 5
4420 2 5
4420 3 5
4460 1 4
4640 1 5
4900 2 4
4940 1 4
4940 2 4
5010 1 5
5020 1 5
5150 1 5
5230 1 5
5340 2 1
5500 1 5
5500 2 4
5530 1 4
5530 2 5
5820 1 5
5820 2 5
5850 1 4
5900 1 3
5900 2 5
5910 2 5
5920 1 4
5920 2 4
6010 1 4
6120 2 5
6210 2 5
6330 2 5
6360 1 5
6400 1 4
6460 1 4
6460 2 1
6530 1 3
6600 2 5
6710 1 2
6710 2 5
6720 1 3
6720 2 4
6740 2 5
6800 1 1
6800 2 3
6820 1 2
6820 2 1
6830 2 1
6940 1 5
6940 2 4
7030 1 2
7030 2 2
7040 1 2
7040 2 5
7100 2 3
7160 1 5
7240 1 3
7240 2 5
7300 1 4
7300 2 4
7360 1 4
7360 2 4
7430 1 2
7510 1 2
7510 2 3
7540 2 3
7560 1 4
7560 2 5
7560 3 4
7610 1 1
7610 2 4
7730 2 1
7740 1 5
7740 2 3
7830 1 4
7830 2 5
7830 3 5
7850 2 2
7920 1 5
7950 1 3
8000 1 1
8000 2 2
8010 2 1
8010 3 4
8040 2 4
8100 1 3
8100 2 1
8130 1 2
8250 1 4
8250 2 5
8310 2 5
8330 2 3
8330 3 4
8420 1 2
8420 2 2
8450 2 5
8460 2 5
8460 3 5
8500 1 4
8510 1 5
8510 2 2
8510 3 4
8530 2 5
8540 1 3
8550 1 2
8600 1 4
8630 1 5
8630 2 5
8650 1 5
8710 1 4
8710 2 5
8720 2 5
8720 3 5
8730 2 4
8730 3 5
8750 2 5
8830 1 4
8830 2 5
8850 1 2
8850 2 4
8910 2 1
8910 3 3
8920 1 3
8930 2 5
8940 1 2
8940 3 3
9200 1 5
9200 2 4
9240 2 4
9260 1 4
9260 2 3
9300 2 2
9300 3 4
9310 1 5
9350 3 5
9360 1 5
9410 1 5
9510 1 5
9560 1 1
9650 2 1
end


gen n_missing = 6 - tag
gen count = 0
expand n_missing
drop tag n_missing

tempfile to_add

save `to_add'


use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
label value occ2010
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month region_group)
append using `to_add'

gen tag = 1
preserve
collapse (sum) tag, by(occ2010 region_group)
count if tag == 6
list occ2010 region_group tag if tag < 6 | tag > 6
restore

collapse (mean) count, by (occ2010 region_group)
rename count freq_wt_P2T_region

merge 1:1 occ2010 region_group using "$data_root/working/het_occ2010/diff_region_group.dta"
br if _merge == 2
*** 18 occupations-region cells don't appear in P2T. The occupations don't recieve differenced outcomes.
drop _merge

*** Adding task indices ***
merge m:1 occ2010 using "$data_root/Cleaned/task_indices_occ2010.dta"
label values occ2010
br if _merge == 1

*** As before, missing task indices for financial analysts, Entertainers and Performers, Sports and Related Workers, All Other, Emergency Medical Technicians and Paramedics, Medical Records and Health Information Technicians, Supervisors, Protective Service Workers, All Other, Sales Representatives, Services, All Other, Fishing and hunting workers, and Taxi Drivers and Chauffeurs.

save "$data_root/Cleaned/het_occ2010/het_regionV2_group.dta", replace

************************************************************** P2T (Region V3) ************************************************************** 
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
label value occ2010
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month region_rust)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010 region_rust)
count if tag == 6
list occ2010 region_rust tag if tag < 6
restore

*** Define the list of combinations and tags ***
clear
input occ2010 region_rust tag
360 1 5
510 0 5
510 1 3
900 0 5
900 1 4
1520 1 5
1700 1 5
1710 1 2
1800 1 5
1840 1 4
2020 1 5
2740 0 4
2740 1 3
2800 1 3
3120 0 4
3200 1 1
3260 1 5
3750 1 4
4240 1 5
4400 1 5
4900 1 1
4930 1 4
4940 1 5
5020 1 5
5340 1 3
5500 1 4
5530 1 4
5850 1 4
5910 0 1
5910 1 4
5920 1 5
6010 1 4
6040 1 5
6100 1 3
6120 1 1
6210 1 2
6240 1 3
6360 1 4
6460 1 5
6600 1 5
6710 1 3
6720 1 5
6740 1 5
6800 1 4
6820 1 5
6830 0 5
7040 1 3
7120 1 5
7130 1 5
7160 1 4
7240 1 5
7350 1 3
7540 1 5
7610 1 3
7730 0 4
7730 1 4
7740 1 5
7850 0 5
7850 1 5
8010 0 4
8010 1 2
8250 1 5
8310 1 4
8330 0 3
8330 1 3
8420 1 4
8450 1 4
8460 1 1
8510 1 1
8550 1 3
8720 0 5
8720 1 5
8730 0 4
8730 1 5
8830 1 5
8910 0 3
8920 1 5
8930 1 4
8940 0 5
8940 1 5
9040 1 5
9260 1 5
9300 1 2
9310 1 2
9350 1 4
9410 1 5
9420 1 4
9560 1 5
9650 1 1
end


gen n_missing = 6 - tag
gen count = 0
expand n_missing
drop tag n_missing

tempfile to_add

save `to_add'


use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
label value occ2010
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month region_rust)
append using `to_add'

gen tag = 1
preserve
collapse (sum) tag, by(occ2010 region_rust)
count if tag == 6
list occ2010 region_rust tag if tag < 6 | tag > 6
restore

collapse (mean) count, by (occ2010 region_rust)
rename count freq_wt_P2T_region

merge 1:1 occ2010 region_rust using "$data_root/working/het_occ2010/diff_region_rust.dta" 
br if _merge == 2
*** 5 occupations-region cells don't appear in P2T. The occupations don't recieve differenced outcomes.
drop _merge

*** Adding task indices ***
merge m:1 occ2010 using "$data_root/Cleaned/task_indices_occ2010.dta"
label values occ2010
br if _merge == 1

*** As before, missing task indices for financial analysts, Entertainers and Performers, Sports and Related Workers, All Other, Emergency Medical Technicians and Paramedics, Medical Records and Health Information Technicians, Supervisors, Protective Service Workers, All Other, Sales Representatives, Services, All Other, Fishing and hunting workers, and Taxi Drivers and Chauffeurs.

save "$data_root/Cleaned/het_occ2010/het_regionV2_rust.dta", replace



************************************************************** P2T (Race) ************************************************************** 
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
label value occ2010
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month race_group)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010 race_group)
count if tag == 6
list occ2010 race_group tag if tag < 6
restore

*** Define the list of combinations and tags ***
clear
input occ2010 race_group tag
100 4 5
140 4 2
150 4 5
300 4 4
360 2 2
360 3 3
360 4 4
500 2 5
500 3 3
510 1 5
510 2 4
520 2 4
540 4 4
560 4 3
600 2 2
600 3 5
600 4 4
700 4 4
720 3 5
810 2 3
810 3 5
820 3 3
830 2 4
830 4 3
850 4 5
860 3 2
860 4 4
900 2 4
900 3 1
900 4 2
930 3 2
930 4 2
940 4 2
950 4 5
1010 4 5
1060 4 4
1100 4 1
1200 2 4
1220 4 1
1300 4 3
1310 2 1
1310 3 1
1320 2 4
1320 4 5
1350 2 4
1350 4 4
1410 4 1
1420 2 1
1420 3 5
1430 4 4
1440 2 2
1440 3 1
1440 4 1
1450 3 3
1460 4 5
1520 2 3
1540 2 5
1540 4 1
1550 4 4
1560 2 3
1600 3 2
1600 4 1
1610 2 5
1610 4 5
1640 2 3
1640 4 2
1650 4 4
1700 3 4
1710 4 2
1720 4 4
1740 2 5
1740 3 5
1740 4 1
1760 4 5
1800 2 2
1800 4 1
1820 3 4
1820 4 5
1830 2 2
1830 3 2
1830 4 5
1840 2 3
1900 2 5
1900 3 3
1900 4 3
1910 2 4
1910 3 5
1920 2 3
2020 3 5
2050 3 2
2050 4 3
2140 4 4
2330 4 5
2400 2 4
2400 3 4
2400 4 5
2430 3 5
2440 2 5
2440 3 3
2700 4 2
2740 1 4
2750 4 3
2760 3 3
2760 4 2
2800 2 3
2800 3 4
2810 4 5
2840 4 4
2850 2 5
2850 4 1
2860 4 2
2910 4 4
2920 2 4
2920 3 5
2920 4 3
3000 2 4
3000 3 5
3000 4 4
3010 2 2
3010 4 1
3030 4 3
3040 3 5
3050 4 4
3110 2 4
3110 4 4
3120 3 5
3140 3 3
3150 2 4
3150 3 5
3150 4 1
3200 2 1
3210 2 4
3210 3 1
3230 4 2
3250 2 5
3250 3 2
3250 4 1
3260 2 1
3260 4 1
3310 4 4
3500 4 5
3510 2 5
3510 4 3
3520 2 4
3520 4 4
3530 4 2
3540 4 5
3610 2 4
3610 3 1
3610 4 2
3620 2 3
3620 3 3
3620 4 3
3630 2 5
3630 4 3
3700 4 1
3710 3 2
3710 4 1
3720 2 3
3720 3 3
3730 3 2
3730 4 3
3740 3 4
3740 4 4
3750 2 5
3750 3 1
3900 2 2
3910 3 3
3910 4 3
3940 2 4
3940 3 2
3940 4 3
4120 4 4
4200 4 5
4210 3 4
4240 3 5
4240 4 2
4340 2 1
4350 3 5
4400 4 4
4420 2 4
4420 3 1
4420 4 2
4460 2 5
4460 3 2
4460 4 5
4500 4 4
4510 4 5
4530 3 5
4530 4 4
4540 2 1
4540 3 5
4540 4 4
4640 2 5
4640 3 3
4640 4 2
4740 3 4
4740 4 4
4750 4 5
4800 3 4
4800 4 4
4820 4 2
4830 2 4
4830 3 5
4900 2 2
4900 3 4
4900 4 2
4930 2 5
4930 3 3
4940 3 1
4950 2 5
4950 3 1
4950 4 3
5010 3 4
5020 2 1
5020 3 4
5020 4 3
5100 3 4
5140 4 3
5150 2 2
5150 3 4
5220 3 2
5220 4 4
5230 2 5
5230 3 5
5250 4 5
5260 4 3
5300 4 3
5310 3 5
5320 2 4
5320 3 5
5320 4 1
5330 3 5
5340 2 3
5340 3 3
5350 4 1
5360 3 5
5410 3 5
5420 3 5
5420 4 3
5500 2 4
5500 3 4
5500 4 5
5520 4 2
5530 2 4
5530 3 1
5530 4 1
5540 4 5
5560 4 3
5630 2 5
5630 4 1
5810 4 4
5820 2 5
5820 3 4
5820 4 3
5840 4 4
5850 4 3
5900 3 3
5910 1 4
5910 2 1
5920 3 2
6005 2 3
6005 3 3
6040 2 3
6040 4 1
6100 3 3
6120 2 2
6120 3 2
6130 2 5
6130 3 2
6200 4 5
6220 2 3
6220 3 1
6220 4 1
6240 2 4
6240 3 5
6240 4 5
6250 3 2
6250 4 3
6330 2 5
6330 3 3
6330 4 5
6360 2 1
6360 4 4
6400 2 2
6420 3 4
6440 4 5
6460 2 1
6460 4 1
6515 3 5
6515 4 4
6520 2 5
6530 2 4
6530 3 4
6530 4 3
6600 2 1
6600 3 2
6660 3 5
6660 4 3
6710 2 1
6710 3 1
6720 2 4
6720 3 2
6720 4 1
6730 4 4
6740 2 2
6765 2 5
6765 4 2
6800 2 2
6840 2 5
6840 3 5
6940 2 5
6940 4 4
7000 2 5
7000 3 5
7010 4 4
7020 3 4
7020 4 3
7030 2 3
7030 3 1
7030 4 3
7040 3 1
7100 3 3
7120 2 5
7120 3 4
7130 2 5
7130 3 5
7130 4 1
7140 4 3
7150 2 4
7150 3 4
7150 4 3
7160 2 2
7220 2 3
7220 3 5
7220 4 4
7240 2 2
7240 3 3
7260 2 3
7260 3 4
7260 4 2
7300 4 1
7320 2 1
7350 2 5
7350 3 3
7360 3 1
7360 4 2
7410 3 3
7410 4 3
7420 3 4
7420 4 5
7430 2 4
7430 4 1
7510 2 1
7510 3 4
7510 4 1
7560 2 1
7610 1 5
7610 2 1
7610 3 5
7730 1 5
7730 2 3
7740 3 4
7740 4 1
7800 4 4
7830 2 1
7830 3 1
7830 4 3
7840 3 5
7840 4 2
7850 2 3
7900 2 5
7900 3 5
7900 4 5
7920 2 3
7920 3 3
7950 4 4
8000 2 2
8000 4 2
8010 1 4
8040 2 4
8100 2 2
8100 4 1
8230 4 3
8250 2 3
8250 3 4
8300 3 5
8300 4 3
8310 2 4
8310 4 1
8320 3 5
8320 4 4
8330 1 4
8350 2 3
8450 3 1
8460 1 4
8460 2 5
8460 3 1
8500 2 1
8510 1 5
8510 2 1
8510 3 3
8510 4 1
8530 2 1
8540 2 4
8550 4 3
8600 4 1
8610 2 4
8610 3 5
8610 4 4
8620 3 3
8630 2 5
8630 3 1
8630 4 1
8640 3 1
8640 4 4
8650 3 5
8650 4 3
8710 3 5
8710 4 1
8720 2 1
8730 1 5
8730 2 1
8750 3 5
8750 4 1
8760 2 4
8800 4 5
8810 4 5
8830 2 1
8850 2 4
8850 3 2
8910 1 3
8910 4 1
8920 3 4
8920 4 1
8930 3 3
8950 2 5
8950 3 5
8950 4 4
9030 2 4
9040 2 3
9040 3 4
9050 4 1
9200 3 2
9200 4 4
9240 2 4
9240 3 3
9240 4 2
9260 2 5
9260 3 1
9260 4 2
9300 2 3
9310 2 3
9310 3 1
9310 4 1
9350 4 1
9360 2 4
9360 3 2
9410 4 2
9420 2 4
9420 3 5
9510 2 5
9510 4 1
9560 4 1
9610 4 5
9630 2 3
9630 3 1
9650 2 2
9650 3 3
9720 3 1
9750 3 1
9750 4 1

end

gen n_missing = 6 - tag
gen count = 0
expand n_missing
drop tag n_missing

tempfile to_add

save `to_add'


use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
label value occ2010
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month race_group)
append using `to_add'

gen tag = 1
preserve
collapse (sum) tag, by(occ2010 race_group)
count if tag == 6
list occ2010 race_group tag if tag < 6 | tag > 6
restore

collapse (mean) count, by (occ2010 race_group)
rename count freq_wt_P2T_race

merge 1:1 occ2010 race_group using "$data_root/working/het_occ2010/diff_race.dta"
br if _merge == 2
*** 208 occupations-race cells don't appear in P2T. The occupations don't recieve differenced outcomes.
drop _merge

*** Adding task indices ***
merge m:1 occ2010 using "$data_root/Cleaned/task_indices_occ2010.dta"
label values occ2010
br if _merge == 1

*** As before, missing task indices for financial analysts, Entertainers and Performers, Sports and Related Workers, All Other, Emergency Medical Technicians and Paramedics, Medical Records and Health Information Technicians, Supervisors, Protective Service Workers, All Other, Sales Representatives, Services, All Other, Fishing and hunting workers, and Taxi Drivers and Chauffeurs.

save "$data_root/Cleaned/het_occ2010/het_raceV1.dta", replace


************************************************************** P2T (Ind1990) ************************************************************** 
use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
label value occ2010
label value ind1990_group
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month ind1990_group)
gen tag = 1

preserve
collapse (sum) tag, by(occ2010 ind1990_group)
count if tag == 6
list occ2010 ind1990_group tag if tag < 6
restore

*** Define the list of combinations and tags ***
clear
input occ2010 ind1990_group tag
100      1              5
110      1              5
110      6              5
130      1              4
140      6              3
150      1              5
150      6              5
160      1              4
205      2              5
205      3              3
205      4              4
205      5              1
220      1              3
220      4              2
230      4              3
230      5              1
230      6              4
300      6              4
310      2              3
310      5              2
350      2              5
350      4              4
360      2              1
360      3              2
360      5              3
410      1              5
410      6              4
420      2              1
420      4              4
420      5              3
420      6              5
500      3              5
500      5              4
500      7              4
510      1              1
510      3              1
510      4              5
510      5              3
510      7              1
520      2              4
520      3              3
520      5              5
520      6              2
520      7              3
530      1              5
530      6              4
540      2              2
560      6              4
600      1              3
600      5              5
600      7              5
700      1              4
700      6              2
710      1              4
720      1              4
720      2              2
720      4              5
730      1              2
810      1              1
810      2              2
810      7              2
820      4              4
830      3              4
830      4              2
830      7              2
840      1              1
850      1              3
850      2              5
850      3              3
850      4              2
860      3              2
860      4              4
860      7              3
900      5              5
910      3              5
910      4              1
910      6              1
930      4              1
930      5              5
930      7              4
940      2              2
940      3              5
940      4              3
940      5              4
950      2              3
950      4              4
1020     1              1
1050     1              4
1050     6              5
1100     1              3
1100     6              2
1220     1              2
1220     4              4
1240     6              5
1300     4              3
1300     6              2
1310     2              4
1310     4              1
1310     5              4
1320     4              1
1320     5              2
1350     3              4
1350     4              3
1360     5              4
1400     4              5
1410     1              1
1430     1              1
1430     4              2
1430     6              2
1440     3              5
1440     7              3
1450     3              1
1460     1              5
1460     6              4
1520     2              2
1520     3              4
1520     7              1
1530     1              3
1530     6              5
1540     1              3
1540     4              3
1540     5              4
1550     6              4
1560     1              2
1560     5              2
1560     6              4
1600     1              2
1600     2              2
1600     3              5
1600     4              4
1600     5              2
1610     6              4
1640     2              5
1640     4              4
1650     4              3
1700     3              4
1700     5              1
1700     6              4
1710     2              1
1710     7              2
1720     1              4
1720     3              5
1720     4              3
1720     5              4
1740     1              4
1740     2              3
1740     4              3
1740     5              4
1760     1              2
1760     4              4
1760     6              1
1820     5              1
1830     1              2
1830     2              5
1830     5              2
1830     6              1
1840     2              5
1840     6              1
1900     3              2
1900     6              4
1910     1              4
1910     4              3
1910     5              2
1920     1              1
1920     4              4
1920     6              3
1960     4              5
1960     6              5
2000     2              2
2000     4              4
2010     6              4
2020     2              3
2020     4              4
2020     5              2
2040     3              2
2040     4              1
2040     5              1
2140     1              4
2140     2              5
2140     4              4
2140     6              4
2150     1              3
2150     2              5
2150     6              2
2200     2              2
2200     3              3
2200     5              2
2300     3              3
2300     4              4
2300     5              1
2310     2              2
2310     3              4
2310     4              5
2310     5              5
2310     6              2
2320     3              3
2320     4              4
2320     5              3
2330     2              1
2330     3              4
2330     4              2
2330     5              3
2340     1              3
2400     2              2
2400     3              3
2400     4              1
2400     5              3
2400     6              1
2430     4              1
2430     5              2
2430     6              4
2440     3              1
2540     5              4
2550     1              1
2550     5              5
2550     6              3
2600     1              3
2600     3              4
2630     1              4
2700     2              5
2700     4              3
2720     1              2
2720     5              5
2740     6              4
2740     7              4
2750     3              3
2750     5              5
2760     3              2
2760     4              2
2760     7              2
2800     4              1
2800     6              2
2800     7              4
2810     1              2
2810     4              3
2825     1              1
2825     6              5
2840     3              4
2840     4              3
2840     6              3
2860     1              2
2860     2              3
2860     4              1
2860     6              3
2900     4              4
2910     2              5
2910     3              3
2910     4              4
2910     7              4
2920     1              2
2920     2              4
2920     4              1
3000     5              2
3010     2              1
3010     3              3
3010     5              1
3030     2              2
3030     5              4
3030     6              5
3040     4              5
3060     1              1
3060     2              4
3060     4              1
3060     6              1
3110     2              2
3110     3              5
3110     4              2
3110     5              1
3120     3              2
3130     2              5
3130     6              1
3140     4              3
3150     3              4
3150     6              2
3160     2              5
3160     5              4
3160     6              4
3200     3              1
3210     2              2
3210     3              4
3210     6              4
3220     2              3
3220     4              5
3220     5              1
3230     2              1
3230     3              4
3230     4              1
3230     5              2
3230     6              3
3240     2              1
3240     3              4
3240     4              1
3240     5              2
3250     4              2
3250     5              3
3250     6              5
3250     7              3
3260     2              2
3260     3              1
3260     6              2
3300     2              1
3300     3              4
3300     4              5
3300     5              2
3310     3              1
3310     4              1
3320     1              2
3320     2              4
3320     3              5
3320     4              1
3400     1              1
3400     2              5
3400     6              4
3410     2              5
3410     5              4
3500     1              1
3500     2              4
3500     4              4
3510     2              2
3510     3              4
3510     4              1
3520     3              3
3530     2              3
3530     5              2
3540     1              2
3600     1              3
3600     2              4
3600     4              5
3620     4              1
3620     5              4
3620     6              1
3630     3              3
3640     2              1
3640     3              5
3640     5              2
3650     6              3
3710     2              1
3710     6              2
3710     7              4
3720     2              1
3730     2              3
3730     6              5
3740     1              5
3740     2              3
3740     5              1
3740     7              5
3750     1              5
3750     2              4
3750     4              4
3750     5              4
3800     1              1
3800     2              2
3800     5              3
3800     6              1
3800     7              3
3820     1              1
3820     4              5
3820     5              3
3820     6              2
3900     3              2
3900     6              5
3900     7              4
3910     2              2
3910     4              2
3910     6              4
3910     7              5
3930     1              2
3940     7              5
3950     1              2
3950     2              4
3950     4              1
3950     5              3
4000     1              4
4010     1              2
4010     2              5
4010     5              2
4030     1              1
4030     2              5
4030     3              5
4030     5              5
4040     1              2
4040     5              2
4050     1              1
4050     2              5
4050     5              2
4050     6              5
4110     2              5
4110     3              4
4120     2              4
4140     2              2
4140     3              1
4140     5              2
4150     2              4
4150     3              2
4150     5              3
4150     7              2
4200     1              1
4200     2              5
4200     3              5
4210     3              4
4210     4              2
4220     1              4
4230     2              3
4240     1              2
4240     2              3
4240     3              1
4320     2              1
4340     3              5
4340     4              3
4350     2              4
4350     3              3
4400     3              1
4400     4              1
4400     7              1
4420     7              5
4430     2              3
4430     3              4
4430     4              3
4430     5              2
4460     7              3
4500     2              2
4500     7              2
4510     2              1
4510     3              1
4510     5              3
4520     3              2
4520     5              1
4520     7              5
4530     7              5
4540     1              1
4600     5              1
4610     1              3
4610     2              5
4610     4              4
4620     1              1
4620     2              1
4620     4              2
4620     5              5
4640     2              3
4640     6              3
4700     1              4
4720     1              3
4740     2              3
4740     4              5
4750     2              5
4750     3              2
4750     5              3
4760     3              4
4760     5              5
4760     7              5
4800     4              5
4800     6              1
4800     7              5
4810     1              2
4810     2              5
4810     3              5
4810     4              1
4810     7              3
4820     1              4
4820     2              1
4820     4              2
4830     2              1
4830     6              5
4840     4              2
4850     6              4
4900     2              2
4900     3              4
4900     4              5
4900     6              5
4900     7              5
4920     3              5
4920     6              2
4920     7              4
4930     3              4
4930     7              3
4940     3              2
4940     4              5
4940     6              2
4940     7              2
4950     2              3
4950     3              1
4950     5              1
4950     7              2
5010     2              5
5010     3              4
5010     4              2
5010     6              1
5020     2              3
5020     3              2
5020     4              3
5100     2              3
5100     4              2
5110     6              4
5140     1              4
5140     6              4
5150     1              4
5150     3              4
5150     5              5
5150     6              1
5150     7              3
5160     3              2
5160     4              2
5160     7              1
5165     4              2
5220     2              1
5220     4              2
5220     5              2
5220     7              4
5230     2              2
5230     3              3
5230     6              1
5250     4              3
5250     5              5
5260     4              5
5260     6              4
5300     3              1
5300     5              4
5300     7              1
5310     2              3
5310     4              4
5310     6              1
5320     5              4
5330     1              2
5330     6              2
5340     2              3
5350     1              1
5350     5              5
5350     6              3
5350     7              5
5360     1              2
5410     5              4
5410     7              5
5420     2              3
5420     4              2
5420     6              3
5500     4              4
5500     7              2
5510     1              2
5520     1              3
5520     6              2
5530     4              1
5530     5              1
5600     1              5
5600     5              5
5610     1              2
5610     6              4
5620     1              4
5620     6              4
5630     1              4
5630     5              5
5630     6              3
5630     7              2
5810     1              4
5810     6              3
5820     1              3
5820     2              3
5820     3              5
5820     5              5
5820     6              1
5840     2              2
5840     4              4
5850     4              1
5900     2              2
5900     6              1
5910     2              4
5910     3              1
5920     2              4
5920     4              2
5920     7              5
5940     6              4
6005     6              3
6010     1              3
6010     2              2
6010     4              4
6010     7              4
6040     2              5
6040     7              2
6050     2              5
6050     3              1
6050     5              1
6050     7              5
6100     3              3
6100     6              5
6120     1              5
6120     2              1
6120     3              5
6120     7              5
6130     1              2
6130     3              3
6130     4              5
6130     7              1
6200     3              5
6200     5              4
6200     6              3
6210     3              4
6210     5              2
6210     7              4
6220     1              2
6220     4              1
6230     1              3
6240     7              2
6250     1              3
6250     3              2
6260     1              2
6260     6              4
6260     7              2
6320     4              4
6320     5              4
6320     6              2
6320     7              3
6330     5              2
6330     7              1
6355     1              5
6360     4              4
6360     5              1
6420     1              1
6420     3              3
6420     6              5
6420     7              5
6440     1              5
6440     6              2
6515     3              2
6515     4              4
6515     5              3
6520     4              1
6520     5              3
6530     1              2
6530     3              3
6530     4              1
6530     7              4
6600     3              1
6600     5              1
6600     7              2
6660     5              4
6700     5              3
6710     1              4
6710     3              1
6710     4              1
6720     1              1
6720     7              3
6730     1              4
6730     4              1
6730     5              1
6730     6              2
6730     7              4
6740     1              5
6765     1              1
6765     3              5
6765     5              2
6765     7              1
6800     3     2
6820     3     1
6830     1     4
6830     3     1
6840     2     1
6840     4     1
6940     2     4
7000     1     5
7010     1     1
7020     1     1
7020     4     4
7020     6     3
7030     7     3
7040     1     2
7040     2     5
7040     3     4
7040     4     1
7040     5     4
7040     6     2
7040     7     2
7100     5     2
7120     2     4
7120     5     4
7120     6     1
7130     2     3
7130     4     2
7130     7     4
7140     6     1
7140     7     5
7150     1     1
7150     2     5
7150     3     3
7150     6     1
7160     2     1
7160     7     1
7200     7     5
7210     7     4
7220     6     4
7220     7     2
7240     1     4
7240     2     4
7240     3     1
7240     6     4
7240     7     3
7260     2     1
7260     3     3
7260     7     1
7300     4     5
7300     5     3
7315     6     2
7320     2     3
7350     1     3
7350     4     1
7350     6     1
7350     7     2
7360     1     2
7360     3     5
7360     4     2
7360     5     4
7360     7     2
7410     1     1
7410     5     5
7420     5     4
7420     7     2
7430     3     5
7510     5     2
7510     7     1
7540     3     4
7540     4     2
7560     1     1
7560     2     5
7560     3     2
7560     4     3
7560     6     3
7560     7     4
7610     2     2
7610     3     1
7610     4     4
7610     5     4
7610     7     1
7630     1     1
7700     1     4
7700     5     5
7700     7     5
7720     3     1
7720     5     1
7720     7     1
7730     2     5
7730     4     2
7730     6     4
7730     7     1
7740     7     1
7750     1     2
7800     3     2
7800     5     2
7800     6     5
7800     7     2
7810     1     2
7810     3     3
7810     7     2
7830     1     1
7840     3     1
7840     5     1
7840     7     2
7850     2     4
7850     4     4
7900     1     2
7900     4     1
7900     5     3
7900     7     1
7950     3     4
7950     4     1
8000     4     2
8000     5     4
8010     2     4
8030     1     1
8030     3     3
8030     7     5
8100     4     4
8130     3     3
8130     5     2
8140     7     4
8220     1     1
8220     4     3
8220     5     4
8220     7     1
8230     3     1
8230     4     5
8250     3     3
8250     5     3
8250     6     1
8250     7     3
8300     2     1
8300     3     2
8300     5     2
8320     3     1
8320     5     4
8320     6     5
8320     7     3
8330     2     4
8330     5     2
8350     1     1
8350     6     2
8350     7     1
8450     5     4
8460     4     5
8500     5     5
8510     2     4
8510     5     5
8550     1     1
8550     4     2
8550     5     3
8550     6     1
8600     2     2
8600     5     1
8610     4     4
8610     6     5
8620     1     2
8620     7     2
8630     4     2
8630     5     1
8630     7     5
8640     1     5
8640     3     5
8640     4     4
8640     7     2
8650     3     2
8650     4     4
8650     5     4
8710     5     4
8710     7     4
8720     1     4
8720     6     3
8730     1     3
8730     2     5
8730     4     2
8730     7     1
8740     6     2
8750     5     3
8750     7     2
8760     3     1
8760     4     3
8760     5     5
8800     1     5
8800     4     3
8800     5     2
8800     7     3
8810     1     1
8810     3     2
8830     2     4
8830     4     4
8830     7     3
8910     2     3
8910     3     3
8920     7     1
8930     3     3
8930     7     2
8940     4     2
8940     5     3
8950     1     2
8950     6     2
9000     1     3
9000     5     5
9000     6     4
9030     1     1
9030     2     2
9030     4     1
9030     5     4
9040     5     4
9040     7     3
9050     4     2
9050     7     5
9100     1     1
9100     2     4
9100     4     2
9100     6     5
9140     2     4
9140     4     4
9140     5     4
9140     7     4
9200     1     4
9200     2     5
9200     4     1
9200     5     1
9240     2     3
9240     6     1
9240     7     1
9260     2     4
9260     7     1
9300     3     4
9300     5     2
9300     6     2
9310     1     1
9310     2     2
9310     5     4
9310     6     3
9350     7     3
9360     7     1
9410     1     3
9410     2     4
9410     4     4
9410     5     1
9420     2     5
9420     4     3
9420     5     2
9420     7     3
9510     1     3
9510     4     3
9510     7     2
9560     3     3
9560     4     5
9600     6     2
9600     7     5
9610     1     5
9610     6     4
9610     7     4
9630     1     3
9630     7     1
9640     1     5
9650     2     2
9650     3     5
9720     4     5
9720     5     4
9750     1     4
9750     4     5
9750     5     1
9750     6     1
9750     7     2
end

gen n_missing = 6 - tag
gen count = 0
expand n_missing
drop tag n_missing

tempfile to_add

save `to_add'


use "$data_root/Working/cps_2010_2025_occ2010_individ_het.dta", clear
label value occ2010
keep if ((year == 2023 & (month == 1 | month == 2 | month == 3)) | (year == 2022 & (month == 10 | month == 11 | month == 12)))
gen count = 1
collapse (sum) count, by (occ2010 month ind1990_group)
append using `to_add'

gen tag = 1
preserve
collapse (sum) tag, by(occ2010 ind1990_group)
count if tag == 6
list occ2010 ind1990_group tag if tag < 6 | tag > 6
restore

collapse (mean) count, by (occ2010 ind1990_group)
rename count freq_wt_P2T_ind

merge 1:1 occ2010 ind1990_group using "$data_root/working/het_occ2010/diff_ind.dta"
br if _merge == 2
*** 211 occupations-race cells don't appear in P2T. The occupations don't recieve differenced outcomes.
drop _merge

*** Adding task indices ***
merge m:1 occ2010 using "$data_root/Cleaned/task_indices_occ2010.dta"
label values occ2010
br if _merge == 1

*** As before, missing task indices for financial analysts, Entertainers and Performers, Sports and Related Workers, All Other, Emergency Medical Technicians and Paramedics, Medical Records and Health Information Technicians, Supervisors, Protective Service Workers, All Other, Sales Representatives, Services, All Other, Fishing and hunting workers, and Taxi Drivers and Chauffeurs.

save "$data_root/Cleaned/het_occ2010/het_indV1.dta", replace


*******************************************************************************************************************************************
*************************************************************** Age Analysis **************************************************************
*******************************************************************************************************************************************
use "$data_root/Cleaned/het_occ2010/het_ageV1.dta", clear
gen exp_x_26less_oa = d_openai_S3_S1 * prop_age_26less_P2T_age
gen exp_x_26to55_oa = d_openai_S3_S1 * prop_age_26to55_P2T_age
gen exp_x_55plus_oa = d_openai_S3_S1 * prop_age_55plus_P2T_age

gen exp_x_26less_c = d_claude_S3_S1 * prop_age_26less_P2T_age
gen exp_x_26to55_c = d_claude_S3_S1 * prop_age_26to55_P2T_age
gen exp_x_55plus_c = d_claude_S3_S1 * prop_age_55plus_P2T_age

foreach outcome in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	replace `outcome'_P2T4T_age = `outcome'_P2T4T_age * 100
}
save "$data_root/Cleaned/het_occ2010/het_ageV1.dta", replace

*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_ageV1.dta", clear

local outcomes d_log_emp_P2T4T_age d_unemp_rate_P2T4T_age d_ahrswork1_P2T4T_age d_ahrswork2_P2T4T_age d_ahrsworkt_P2T4T_age ///
d_other_job_P2T4T_age d_fulltime_P2T4T_age
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30less_P2T_age exp_x_30less_oa prop_age_50plus_P2T_age ///
	exp_x_50plus_oa [aweight = freq_wt_P2T_age], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_age" {
        outreg2 using "$export_root/June/txt/Het/age_A.txt", keep(d_openai_S3_S1 prop_age_30less_P2T_age exp_x_30less_oa prop_age_50plus_P2T_age exp_x_50plus_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/age_A.txt", keep(d_openai_S3_S1 prop_age_30less_P2T_age exp_x_30less_oa prop_age_50plus_P2T_age exp_x_50plus_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30less_P2T_age exp_x_30less_c prop_age_50plus_P2T_age ///
	exp_x_50plus_c [aweight = freq_wt_P2T_age], vce(robust)
	outreg2 using "$export_root/June/txt/Het/age_A.txt", keep(d_claude_S3_S1 prop_age_30less_P2T_age exp_x_30less_c prop_age_50plus_P2T_age exp_x_50plus_c) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_ageV1.dta", clear

local outcomes d_log_emp_P2T4T_age d_unemp_rate_P2T4T_age d_ahrswork1_P2T4T_age d_ahrswork2_P2T4T_age d_ahrsworkt_P2T4T_age ///
d_other_job_P2T4T_age d_fulltime_P2T4T_age

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_30less_P2T_age exp_x_30less_oa prop_age_50plus_P2T_age ///
	exp_x_50plus_oa prop_black_P2T_age prop_asian_P2T_age prop_native_P2T_age prop_mixed_other_P2T_age prop_pacific_P2T_age ///
    prop_educ_q1_P2T_age prop_educ_q2_P2T_age prop_educ_q3_P2T_age prop_midwest_P2T_age ///
    prop_northeast_P2T_age prop_west_P2T_age prop_fem_P2T_age [aweight = freq_wt_P2T_age], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_age" {
        outreg2 using "$export_root/June/txt/Het/age_B.txt", keep(d_openai_S3_S1 prop_age_30less_P2T_age exp_x_30less_oa prop_age_50plus_P2T_age exp_x_50plus_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/age_B.txt", keep(d_openai_S3_S1 prop_age_30less_P2T_age exp_x_30less_oa prop_age_50plus_P2T_age exp_x_50plus_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_30less_P2T_age exp_x_30less_c prop_age_50plus_P2T_age ///
	exp_x_50plus_c prop_black_P2T_age prop_asian_P2T_age prop_native_P2T_age prop_mixed_other_P2T_age prop_pacific_P2T_age ///
    prop_educ_q1_P2T_age prop_educ_q2_P2T_age prop_educ_q3_P2T_age prop_midwest_P2T_age ///
    prop_northeast_P2T_age prop_west_P2T_age prop_fem_P2T_age [aweight = freq_wt_P2T_age], vce(robust)
	outreg2 using "$export_root/June/txt/Het/age_B.txt", keep(d_claude_S3_S1 prop_age_30less_P2T_age exp_x_30less_c prop_age_50plus_P2T_age exp_x_50plus_c) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_ageV1.dta", clear

local outcomes d_log_emp_P2T4T_age d_unemp_rate_P2T4T_age d_ahrswork1_P2T4T_age d_ahrswork2_P2T4T_age d_ahrsworkt_P2T4T_age ///
d_other_job_P2T4T_age d_fulltime_P2T4T_age
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30less_P2T_age exp_x_30less_oa prop_age_50plus_P2T_age ///
	exp_x_50plus_oa prop_black_P2T_age prop_asian_P2T_age prop_native_P2T_age prop_mixed_other_P2T_age prop_pacific_P2T_age ///
    prop_educ_q1_P2T_age prop_educ_q2_P2T_age prop_educ_q3_P2T_age prop_midwest_P2T_age ///
    prop_northeast_P2T_age prop_west_P2T_age prop_fem_P2T_age [aweight = freq_wt_P2T_age], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_age" {
        outreg2 using "$export_root/June/txt/Het/age_C.txt", keep(d_openai_S3_S1 prop_age_30less_P2T_age exp_x_30less_oa prop_age_50plus_P2T_age exp_x_50plus_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/age_C.txt", keep(d_openai_S3_S1 prop_age_30less_P2T_age exp_x_30less_oa prop_age_50plus_P2T_age exp_x_50plus_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_30less_P2T_age exp_x_30less_c prop_age_50plus_P2T_age ///
	exp_x_50plus_c prop_black_P2T_age prop_asian_P2T_age prop_native_P2T_age prop_mixed_other_P2T_age prop_pacific_P2T_age ///
    prop_educ_q1_P2T_age prop_educ_q2_P2T_age prop_educ_q3_P2T_age prop_midwest_P2T_age ///
    prop_northeast_P2T_age prop_west_P2T_age prop_fem_P2T_age [aweight = freq_wt_P2T_age], vce(robust)
	outreg2 using "$export_root/June/txt/Het/age_C.txt", keep(d_claude_S3_S1 prop_age_30less_P2T_age exp_x_30less_c prop_age_50plus_P2T_age exp_x_50plus_c) nocons append
}

*******************************************************************************************************************************************
************************************************************** Educ Analysis **************************************************************
*******************************************************************************************************************************************
use "$data_root/Cleaned/het_occ2010/het_educV1.dta", clear
gen exp_x_educq2_oa = d_openai_S3_S1 * prop_educ_q2_P2T_educ
gen exp_x_educq3_oa = d_openai_S3_S1 * prop_educ_q3_P2T_educ
gen exp_x_educq4_oa = d_openai_S3_S1 * prop_educ_q4_P2T_educ

gen exp_x_educq2_c = d_claude_S3_S1 * prop_educ_q2_P2T_educ
gen exp_x_educq3_c = d_claude_S3_S1 * prop_educ_q3_P2T_educ
gen exp_x_educq4_c = d_claude_S3_S1 * prop_educ_q4_P2T_educ

foreach outcome in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	replace `outcome'_P2T_P4T_educ = `outcome'_P2T_P4T_educ * 100
}

foreach outcome in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	rename `outcome'_P2T_P4T_educ `outcome'_P2T4T_educ
}
save "$data_root/Cleaned/het_occ2010/het_educV1.dta", replace

*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_educV1.dta", clear

local outcomes d_log_emp_P2T4T_educ d_unemp_rate_P2T4T_educ d_ahrswork1_P2T4T_educ d_ahrswork2_P2T4T_educ d_ahrsworkt_P2T4T_educ ///
d_other_job_P2T4T_educ d_fulltime_P2T4T_educ
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_educ_q2_P2T_educ exp_x_educq2_oa prop_educ_q3_P2T_educ exp_x_educq3_oa prop_educ_q4_P2T_educ ///
	exp_x_educq4_oa [aweight = freq_wt_P2T_educ], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_educ" {
        outreg2 using "$export_root/June/txt/Het/educ_A.txt", keep(d_openai_S3_S1 prop_educ_q2_P2T_educ exp_x_educq2_oa prop_educ_q3_P2T_educ exp_x_educq3_oa prop_educ_q4_P2T_educ exp_x_educq4_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/educ_A.txt", keep(d_openai_S3_S1 prop_educ_q2_P2T_educ exp_x_educq2_oa prop_educ_q3_P2T_educ exp_x_educq3_oa prop_educ_q4_P2T_educ exp_x_educq4_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_educ_q2_P2T_educ exp_x_educq2_c prop_educ_q3_P2T_educ exp_x_educq3_c prop_educ_q4_P2T_educ ///
	exp_x_educq4_c [aweight = freq_wt_P2T_educ], vce(robust)
	outreg2 using "$export_root/June/txt/Het/educ_A.txt", keep(d_claude_S3_S1 prop_educ_q2_P2T_educ exp_x_educq2_c prop_educ_q3_P2T_educ exp_x_educq3_c prop_educ_q4_P2T_educ exp_x_educq4_c) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_educV1.dta", clear

local outcomes d_log_emp_P2T4T_educ d_unemp_rate_P2T4T_educ d_ahrswork1_P2T4T_educ d_ahrswork2_P2T4T_educ d_ahrsworkt_P2T4T_educ ///
d_other_job_P2T4T_educ d_fulltime_P2T4T_educ

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_educ_q2_P2T_educ exp_x_educq2_oa prop_educ_q3_P2T_educ exp_x_educq3_oa prop_educ_q4_P2T_educ ///
	exp_x_educq4_oa prop_age_30less_P2T_educ prop_age_50plus_P2T_educ prop_black_P2T_educ prop_asian_P2T_educ prop_native_P2T_educ ///
	prop_mixed_other_P2T_educ prop_pacific_P2T_educ prop_midwest_P2T_educ ///
    prop_northeast_P2T_educ prop_west_P2T_educ prop_fem_P2T_educ [aweight = freq_wt_P2T_educ], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_educ" {
        outreg2 using "$export_root/June/txt/Het/educ_B.txt", keep(d_openai_S3_S1 prop_educ_q2_P2T_educ exp_x_educq2_oa prop_educ_q3_P2T_educ exp_x_educq3_oa prop_educ_q4_P2T_educ exp_x_educq4_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/educ_B.txt", keep(d_openai_S3_S1 prop_educ_q2_P2T_educ exp_x_educq2_oa prop_educ_q3_P2T_educ exp_x_educq3_oa prop_educ_q4_P2T_educ exp_x_educq4_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_educ_q2_P2T_educ exp_x_educq2_c prop_educ_q3_P2T_educ exp_x_educq3_c prop_educ_q4_P2T_educ ///
	exp_x_educq4_c prop_age_30less_P2T_educ prop_age_50plus_P2T_educ prop_black_P2T_educ prop_asian_P2T_educ prop_native_P2T_educ ///
	prop_mixed_other_P2T_educ prop_pacific_P2T_educ prop_midwest_P2T_educ ///
    prop_northeast_P2T_educ prop_west_P2T_educ prop_fem_P2T_educ [aweight = freq_wt_P2T_educ], vce(robust)
	outreg2 using "$export_root/June/txt/Het/educ_B.txt", keep(d_claude_S3_S1 prop_educ_q2_P2T_educ exp_x_educq2_c prop_educ_q3_P2T_educ exp_x_educq3_c prop_educ_q4_P2T_educ exp_x_educq4_c) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_educV1.dta", clear

local outcomes d_log_emp_P2T4T_educ d_unemp_rate_P2T4T_educ d_ahrswork1_P2T4T_educ d_ahrswork2_P2T4T_educ d_ahrsworkt_P2T4T_educ ///
d_other_job_P2T4T_educ d_fulltime_P2T4T_educ
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_educ_q2_P2T_educ exp_x_educq2_oa prop_educ_q3_P2T_educ ///
	exp_x_educq3_oa prop_educ_q4_P2T_educ ///
	exp_x_educq4_oa prop_age_30less_P2T_educ prop_age_50plus_P2T_educ prop_black_P2T_educ prop_asian_P2T_educ prop_native_P2T_educ ///
	prop_mixed_other_P2T_educ prop_pacific_P2T_educ prop_midwest_P2T_educ ///
    prop_northeast_P2T_educ prop_west_P2T_educ prop_fem_P2T_educ [aweight = freq_wt_P2T_educ], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_educ" {
        outreg2 using "$export_root/June/txt/Het/educ_C.txt", keep(d_openai_S3_S1 prop_educ_q2_P2T_educ exp_x_educq2_oa prop_educ_q3_P2T_educ exp_x_educq3_oa prop_educ_q4_P2T_educ exp_x_educq4_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/educ_C.txt", keep(d_openai_S3_S1 prop_educ_q2_P2T_educ exp_x_educq2_oa prop_educ_q3_P2T_educ exp_x_educq3_oa prop_educ_q4_P2T_educ exp_x_educq4_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_educ_q2_P2T_educ exp_x_educq2_c prop_educ_q3_P2T_educ ///
	exp_x_educq3_c prop_educ_q4_P2T_educ ///
	exp_x_educq4_c prop_age_30less_P2T_educ prop_age_50plus_P2T_educ prop_black_P2T_educ prop_asian_P2T_educ prop_native_P2T_educ ///
	prop_mixed_other_P2T_educ prop_pacific_P2T_educ prop_midwest_P2T_educ ///
    prop_northeast_P2T_educ prop_west_P2T_educ prop_fem_P2T_educ [aweight = freq_wt_P2T_educ], vce(robust)
	outreg2 using "$export_root/June/txt/Het/educ_C.txt", keep(d_claude_S3_S1 prop_educ_q2_P2T_educ exp_x_educq2_c prop_educ_q3_P2T_educ exp_x_educq3_c prop_educ_q4_P2T_educ exp_x_educq4_c) nocons append
}

*******************************************************************************************************************************************
************************************************************** Sex Analysis **************************************************************
*******************************************************************************************************************************************
use "$data_root/Cleaned/het_occ2010/het_sexV1.dta", clear
gen exp_x_fem_oa = d_openai_S3_S1 * prop_fem_P2T_sex
gen exp_x_fem_c = d_claude_S3_S1 * prop_fem_P2T_sex



foreach outcome in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	replace `outcome'_P2T_P4T_sex = `outcome'_P2T_P4T_sex * 100
}

foreach outcome in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	rename `outcome'_P2T_P4T_sex `outcome'_P2T4T_sex
}
save "$data_root/Cleaned/het_occ2010/het_sexV1.dta", replace

*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_sexV1.dta", clear

local outcomes d_log_emp_P2T4T_sex d_unemp_rate_P2T4T_sex d_ahrswork1_P2T4T_sex d_ahrswork2_P2T4T_sex d_ahrsworkt_P2T4T_sex ///
d_other_job_P2T4T_sex d_fulltime_P2T4T_sex
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_fem_P2T_sex exp_x_fem_oa [aweight = freq_wt_P2T_sex], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_sex" {
        outreg2 using "$export_root/June/txt/Het/sex_A.txt", keep(d_openai_S3_S1 prop_fem_P2T_sex exp_x_fem_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/sex_A.txt", keep(d_openai_S3_S1 prop_fem_P2T_sex exp_x_fem_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_fem_P2T_sex exp_x_fem_c [aweight = freq_wt_P2T_sex], vce(robust)
	outreg2 using "$export_root/June/txt/Het/sex_A.txt", keep(d_claude_S3_S1 prop_fem_P2T_sex exp_x_fem_c) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_sexV1.dta", clear

local outcomes d_log_emp_P2T4T_sex d_unemp_rate_P2T4T_sex d_ahrswork1_P2T4T_sex d_ahrswork2_P2T4T_sex d_ahrsworkt_P2T4T_sex ///
d_other_job_P2T4T_sex d_fulltime_P2T4T_sex

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_fem_P2T_sex exp_x_fem_oa prop_educ_q2_P2T_sex prop_educ_q3_P2T_sex prop_educ_q4_P2T_sex ///
	prop_age_30less_P2T_sex prop_age_50plus_P2T_sex prop_black_P2T_sex prop_asian_P2T_sex prop_native_P2T_sex ///
	prop_mixed_other_P2T_sex prop_pacific_P2T_sex prop_midwest_P2T_sex ///
    prop_northeast_P2T_sex prop_west_P2T_sex [aweight = freq_wt_P2T_sex], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_sex" {
        outreg2 using "$export_root/June/txt/Het/sex_B.txt", keep(d_openai_S3_S1 prop_fem_P2T_sex exp_x_fem_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/sex_B.txt", keep(d_openai_S3_S1 prop_fem_P2T_sex exp_x_fem_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_fem_P2T_sex exp_x_fem_c prop_educ_q2_P2T_sex prop_educ_q3_P2T_sex prop_educ_q4_P2T_sex ///
	prop_age_30less_P2T_sex prop_age_50plus_P2T_sex prop_black_P2T_sex prop_asian_P2T_sex prop_native_P2T_sex ///
	prop_mixed_other_P2T_sex prop_pacific_P2T_sex prop_midwest_P2T_sex ///
    prop_northeast_P2T_sex prop_west_P2T_sex [aweight = freq_wt_P2T_sex], vce(robust)
	
	outreg2 using "$export_root/June/txt/Het/sex_B.txt", keep(d_claude_S3_S1 prop_fem_P2T_sex exp_x_fem_c) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_sexV1.dta", clear

local outcomes d_log_emp_P2T4T_sex d_unemp_rate_P2T4T_sex d_ahrswork1_P2T4T_sex d_ahrswork2_P2T4T_sex d_ahrsworkt_P2T4T_sex ///
d_other_job_P2T4T_sex d_fulltime_P2T4T_sex
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_sex exp_x_fem_oa prop_educ_q2_P2T_sex prop_educ_q3_P2T_sex ///
	prop_educ_q4_P2T_sex prop_age_30less_P2T_sex prop_age_50plus_P2T_sex prop_black_P2T_sex prop_asian_P2T_sex prop_native_P2T_sex ///
	prop_mixed_other_P2T_sex prop_pacific_P2T_sex prop_midwest_P2T_sex ///
    prop_northeast_P2T_sex prop_west_P2T_sex [aweight = freq_wt_P2T_sex], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_sex" {
        outreg2 using "$export_root/June/txt/Het/sex_C.txt", keep(d_openai_S3_S1 prop_fem_P2T_sex exp_x_fem_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/sex_C.txt", keep(d_openai_S3_S1 prop_fem_P2T_sex exp_x_fem_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_sex exp_x_fem_c prop_educ_q2_P2T_sex prop_educ_q3_P2T_sex ///
	prop_educ_q4_P2T_sex prop_age_30less_P2T_sex prop_age_50plus_P2T_sex prop_black_P2T_sex prop_asian_P2T_sex prop_native_P2T_sex ///
	prop_mixed_other_P2T_sex prop_pacific_P2T_sex prop_midwest_P2T_sex ///
    prop_northeast_P2T_sex prop_west_P2T_sex [aweight = freq_wt_P2T_sex], vce(robust)
	outreg2 using "$export_root/June/txt/Het/sex_C.txt", keep(d_claude_S3_S1 prop_fem_P2T_sex exp_x_fem_c) nocons append
}



*******************************************************************************************************************************************
*********************************************************** Sex Analysis (Male) ***********************************************************
*******************************************************************************************************************************************
use "$data_root/Cleaned/het_occ2010/het_sexV1.dta", clear
gen exp_x_male_oa = d_openai_S3_S1 * prop_male_P2T_sex
gen exp_x_male_c = d_claude_S3_S1 * prop_male_P2T_sex

save "$data_root/Cleaned/het_occ2010/het_sexV1.dta", replace

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_sexV1.dta", clear

local outcomes d_log_emp_P2T4T_sex d_unemp_rate_P2T4T_sex d_ahrswork1_P2T4T_sex d_ahrswork2_P2T4T_sex d_ahrsworkt_P2T4T_sex ///
d_other_job_P2T4T_sex d_fulltime_P2T4T_sex
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_male_oa prop_male_P2T_sex NR_CA NR_CI RC RM NRMP offshore prop_educ_q2_P2T_sex prop_educ_q3_P2T_sex ///
	prop_educ_q4_P2T_sex prop_age_26less_P2T_sex prop_age_55plus_P2T_sex prop_black_P2T_sex prop_asian_P2T_sex prop_other_P2T_sex ///
	prop_midwest_P2T_sex ///
    prop_northeast_P2T_sex prop_west_P2T_sex [aweight = freq_wt_P2T_sex], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_sex" {
        outreg2 using "$export_root/June/txt/6_26/sex_C.txt", keep(d_openai_S3_S1 exp_x_male_oa prop_male_P2T_sex) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_26/sex_C.txt", keep(d_openai_S3_S1 exp_x_male_oa prop_male_P2T_sex) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_male_c prop_male_P2T_sex NR_CA NR_CI RC RM NRMP offshore prop_educ_q2_P2T_sex prop_educ_q3_P2T_sex ///
	prop_educ_q4_P2T_sex prop_age_26less_P2T_sex prop_age_55plus_P2T_sex prop_black_P2T_sex prop_asian_P2T_sex prop_other_P2T_sex ///
	prop_midwest_P2T_sex ///
    prop_northeast_P2T_sex prop_west_P2T_sex [aweight = freq_wt_P2T_sex], vce(robust)
	outreg2 using "$export_root/June/txt/6_26/sex_C.txt", keep(d_claude_S3_S1 exp_x_male_c prop_male_P2T_sex) nocons append
}




*******************************************************************************************************************************************
************************************************************* Region Analysis *************************************************************
*******************************************************************************************************************************************
use "$data_root/Cleaned/het_occ2010/het_regionV1.dta", clear
gen exp_x_northeast_oa = d_openai_S3_S1 * prop_northeast_P2T_region
gen exp_x_midwest_oa = d_openai_S3_S1 * prop_midwest_P2T_region
gen exp_x_south_oa = d_openai_S3_S1 * prop_south_P2T_region
gen exp_x_west_oa = d_openai_S3_S1 * prop_west_P2T_region

gen exp_x_northeast_c = d_claude_S3_S1 * prop_northeast_P2T_region
gen exp_x_midwest_c = d_claude_S3_S1 * prop_midwest_P2T_region
gen exp_x_south_c = d_claude_S3_S1 * prop_south_P2T_region
gen exp_x_west_c = d_claude_S3_S1 * prop_west_P2T_region


foreach outcome in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	replace `outcome'_P2T_P4T_reg = `outcome'_P2T_P4T_reg * 100
}

foreach outcome in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	rename `outcome'_P2T_P4T_reg `outcome'_P2T4T_region
}
save "$data_root/Cleaned/het_occ2010/het_regionV1.dta", replace

*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_regionV1.dta", clear

local outcomes d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_northeast_P2T_region exp_x_northeast_oa prop_midwest_P2T_region exp_x_midwest_oa ///
	prop_west_P2T_region exp_x_west_oa [aweight = freq_wt_P2T_region], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/region_A.txt", keep(d_openai_S3_S1 prop_northeast_P2T_region exp_x_northeast_oa prop_midwest_P2T_region exp_x_midwest_oa prop_west_P2T_region exp_x_west_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/region_A.txt", keep(d_openai_S3_S1 prop_northeast_P2T_region exp_x_northeast_oa prop_midwest_P2T_region exp_x_midwest_oa prop_west_P2T_region exp_x_west_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_northeast_P2T_region exp_x_northeast_c prop_midwest_P2T_region exp_x_midwest_c prop_west_P2T_region ///
	exp_x_west_c [aweight = freq_wt_P2T_region], vce(robust)
	outreg2 using "$export_root/June/txt/Het/region_A.txt", keep(d_claude_S3_S1 prop_northeast_P2T_region exp_x_northeast_c prop_midwest_P2T_region exp_x_midwest_c prop_west_P2T_region exp_x_west_c) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_regionV1.dta", clear

local outcomes d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_northeast_P2T_region exp_x_northeast_oa prop_midwest_P2T_region exp_x_midwest_oa ///
	prop_west_P2T_region exp_x_west_oa prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_30less_P2T_region prop_age_50plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_native_P2T_region ///
	prop_mixed_other_P2T_region prop_pacific_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/region_B.txt", keep(d_openai_S3_S1 prop_northeast_P2T_region exp_x_northeast_oa prop_midwest_P2T_region exp_x_midwest_oa prop_west_P2T_region exp_x_west_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/region_B.txt", keep(d_openai_S3_S1 prop_northeast_P2T_region exp_x_northeast_oa prop_midwest_P2T_region exp_x_midwest_oa prop_west_P2T_region exp_x_west_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_northeast_P2T_region exp_x_northeast_c prop_midwest_P2T_region exp_x_midwest_c ///
	prop_west_P2T_region exp_x_west_c prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_30less_P2T_region prop_age_50plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_native_P2T_region ///
	prop_mixed_other_P2T_region prop_pacific_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
	
	outreg2 using "$export_root/June/txt/Het/region_B.txt", keep(d_claude_S3_S1 prop_northeast_P2T_region exp_x_northeast_c prop_midwest_P2T_region exp_x_midwest_c prop_west_P2T_region exp_x_west_c ) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_regionV1.dta", clear

local outcomes d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_northeast_P2T_region exp_x_northeast_oa prop_midwest_P2T_region ///
	exp_x_midwest_oa ///
	prop_west_P2T_region exp_x_west_oa prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_30less_P2T_region prop_age_50plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_native_P2T_region ///
	prop_mixed_other_P2T_region prop_pacific_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/region_C.txt", keep(d_openai_S3_S1 prop_northeast_P2T_region exp_x_northeast_oa prop_midwest_P2T_region exp_x_midwest_oa prop_west_P2T_region exp_x_west_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/region_C.txt", keep(d_openai_S3_S1 prop_northeast_P2T_region exp_x_northeast_oa prop_midwest_P2T_region exp_x_midwest_oa prop_west_P2T_region exp_x_west_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_northeast_P2T_region exp_x_northeast_c prop_midwest_P2T_region ///
	exp_x_midwest_c ///
	prop_west_P2T_region exp_x_west_c prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_30less_P2T_region prop_age_50plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_native_P2T_region ///
	prop_mixed_other_P2T_region prop_pacific_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
	outreg2 using "$export_root/June/txt/Het/region_C.txt", keep(d_claude_S3_S1 prop_northeast_P2T_region exp_x_northeast_c prop_midwest_P2T_region exp_x_midwest_c prop_west_P2T_region exp_x_west_c ) nocons append
}



*******************************************************************************************************************************************
************************************************************* Race Analysis *************************************************************
*******************************************************************************************************************************************
use "$data_root/Cleaned/het_occ2010/het_raceV1.dta", clear
gen exp_x_white_oa = d_openai_S3_S1 * prop_white_P2T_race
gen exp_x_black_oa = d_openai_S3_S1 * prop_black_P2T_race
gen exp_x_asian_oa = d_openai_S3_S1 * prop_asian_P2T_race
gen exp_x_other_oa = d_openai_S3_S1 * prop_other_P2T_race


gen exp_x_white_c = d_claude_S3_S1 * prop_white_P2T_race
gen exp_x_black_c = d_claude_S3_S1 * prop_black_P2T_race
gen exp_x_asian_c = d_claude_S3_S1 * prop_asian_P2T_race
gen exp_x_other_c = d_claude_S3_S1 * prop_other_P2T_race


foreach outcome in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	replace `outcome'_P2T_P4T_race = `outcome'_P2T_P4T_race * 100
}

foreach outcome in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	rename `outcome'_P2T_P4T_race `outcome'_P2T4T_race
}
save "$data_root/Cleaned/het_occ2010/het_raceV1.dta", replace

*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_raceV1.dta", clear

local outcomes d_log_emp_P2T4T_race d_unemp_rate_P2T4T_race d_ahrswork1_P2T4T_race d_ahrswork2_P2T4T_race ///
d_ahrsworkt_P2T4T_race d_other_job_P2T4T_race d_fulltime_P2T4T_race
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_white_P2T_race exp_x_white_oa prop_black_P2T_race exp_x_black_oa ///
	prop_asian_P2T_race exp_x_asian_oa [aweight = freq_wt_P2T_race], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_race" {
        outreg2 using "$export_root/June/txt/Het/race_A.txt", keep(d_openai_S3_S1 prop_white_P2T_race exp_x_white_oa prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race exp_x_asian_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/race_A.txt", keep(d_openai_S3_S1 prop_white_P2T_race exp_x_white_oa prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race exp_x_asian_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_white_P2T_race exp_x_white_c prop_black_P2T_race exp_x_black_c prop_asian_P2T_race exp_x_asian_c ///
	[aweight = freq_wt_P2T_race], vce(robust)
	outreg2 using "$export_root/June/txt/Het/race_A.txt", keep(d_claude_S3_S1 prop_white_P2T_race exp_x_white_c prop_black_P2T_race exp_x_black_c prop_asian_P2T_race exp_x_asian_c) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_raceV1.dta", clear

local outcomes d_log_emp_P2T4T_race d_unemp_rate_P2T4T_race d_ahrswork1_P2T4T_race d_ahrswork2_P2T4T_race ///
d_ahrsworkt_P2T4T_race d_other_job_P2T4T_race d_fulltime_P2T4T_race

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_white_P2T_race exp_x_white_oa prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race ///
	exp_x_asian_oa prop_northeast_P2T_race prop_midwest_P2T_race ///
	prop_west_P2T_race prop_fem_P2T_race prop_educ_q2_P2T_race prop_educ_q3_P2T_race prop_educ_q4_P2T_race ///
	prop_age_30less_P2T_race prop_age_50plus_P2T_race [aweight = freq_wt_P2T_race], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_race" {
        outreg2 using "$export_root/June/txt/Het/race_B.txt", keep(d_openai_S3_S1 prop_white_P2T_race exp_x_white_oa prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race exp_x_asian_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/race_B.txt", keep(d_openai_S3_S1 prop_white_P2T_race exp_x_white_oa prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race exp_x_asian_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_white_P2T_race exp_x_white_c prop_black_P2T_race exp_x_black_c prop_asian_P2T_race ///
	exp_x_asian_c prop_northeast_P2T_race prop_midwest_P2T_race ///
	prop_west_P2T_race prop_fem_P2T_race prop_educ_q2_P2T_race prop_educ_q3_P2T_race prop_educ_q4_P2T_race ///
	prop_age_30less_P2T_race prop_age_50plus_P2T_race [aweight = freq_wt_P2T_race], vce(robust)
	
	outreg2 using "$export_root/June/txt/Het/race_B.txt", keep(d_claude_S3_S1 prop_white_P2T_race exp_x_white_c prop_black_P2T_race exp_x_black_c prop_asian_P2T_race exp_x_asian_c) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_raceV1.dta", clear

local outcomes d_log_emp_P2T4T_race d_unemp_rate_P2T4T_race d_ahrswork1_P2T4T_race d_ahrswork2_P2T4T_race ///
d_ahrsworkt_P2T4T_race d_other_job_P2T4T_race d_fulltime_P2T4T_race

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_white_P2T_race exp_x_white_oa prop_black_P2T_race exp_x_black_oa ///
	prop_asian_P2T_race exp_x_asian_oa prop_northeast_P2T_race prop_midwest_P2T_race ///
	prop_west_P2T_race prop_fem_P2T_race prop_educ_q2_P2T_race prop_educ_q3_P2T_race prop_educ_q4_P2T_race ///
	prop_age_30less_P2T_race prop_age_50plus_P2T_race [aweight = freq_wt_P2T_race], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_race" {
        outreg2 using "$export_root/June/txt/Het/race_C.txt", keep(d_openai_S3_S1 prop_white_P2T_race exp_x_white_oa prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race exp_x_asian_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/race_C.txt", keep(d_openai_S3_S1 prop_white_P2T_race exp_x_white_oa prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race exp_x_asian_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_white_P2T_race exp_x_white_c prop_black_P2T_race exp_x_black_c ///
	prop_asian_P2T_race exp_x_asian_c prop_northeast_P2T_race prop_midwest_P2T_race ///
	prop_west_P2T_race prop_fem_P2T_race prop_educ_q2_P2T_race prop_educ_q3_P2T_race prop_educ_q4_P2T_race ///
	prop_age_30less_P2T_race prop_age_50plus_P2T_race [aweight = freq_wt_P2T_race], vce(robust)
	
	outreg2 using "$export_root/June/txt/Het/race_C.txt", keep(d_claude_S3_S1 prop_white_P2T_race exp_x_white_c prop_black_P2T_race exp_x_black_c prop_asian_P2T_race exp_x_asian_c) nocons append
}

*******************************************************************************************************************************************
************************************************************** Age (26 & 55) **************************************************************
*******************************************************************************************************************************************


*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_ageV1.dta", clear

local outcomes d_log_emp_P2T4T_age d_unemp_rate_P2T4T_age d_ahrswork1_P2T4T_age d_ahrswork2_P2T4T_age d_ahrsworkt_P2T4T_age ///
d_other_job_P2T4T_age d_fulltime_P2T4T_age
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_26less_P2T_age exp_x_26less_oa prop_age_55plus_P2T_age exp_x_55plus_oa ///
	[aweight = freq_wt_P2T_age], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_age" {
        outreg2 using "$export_root/June/txt/Het/age_A_v2.txt", keep(d_openai_S3_S1 prop_age_26less_P2T_age exp_x_26less_oa prop_age_55plus_P2T_age exp_x_55plus_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/age_A_v2.txt", keep(d_openai_S3_S1 prop_age_26less_P2T_age exp_x_26less_oa prop_age_55plus_P2T_age exp_x_55plus_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_26less_P2T_age exp_x_26less_c prop_age_55plus_P2T_age exp_x_55plus_c [aweight = freq_wt_P2T_age], ///
	vce(robust)
	outreg2 using "$export_root/June/txt/Het/age_A_v2.txt", keep(d_claude_S3_S1 prop_age_26less_P2T_age exp_x_26less_c prop_age_55plus_P2T_age exp_x_55plus_c) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_ageV1.dta", clear

local outcomes d_log_emp_P2T4T_age d_unemp_rate_P2T4T_age d_ahrswork1_P2T4T_age d_ahrswork2_P2T4T_age d_ahrsworkt_P2T4T_age ///
d_other_job_P2T4T_age d_fulltime_P2T4T_age

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_age_26less_P2T_age exp_x_26less_oa prop_age_55plus_P2T_age exp_x_55plus_oa ///
	prop_black_P2T_age prop_asian_P2T_age prop_other_P2T_age ///
    prop_educ_q1_P2T_age prop_educ_q2_P2T_age prop_educ_q3_P2T_age prop_midwest_P2T_age ///
    prop_northeast_P2T_age prop_west_P2T_age prop_fem_P2T_age [aweight = freq_wt_P2T_age], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_age" {
        outreg2 using "$export_root/June/txt/Het/age_B_v2.txt", keep(d_openai_S3_S1 prop_age_26less_P2T_age exp_x_26less_oa prop_age_55plus_P2T_age exp_x_55plus_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/age_B_v2.txt", keep(d_openai_S3_S1 prop_age_26less_P2T_age exp_x_26less_oa prop_age_55plus_P2T_age exp_x_55plus_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_age_26less_P2T_age exp_x_26less_c prop_age_55plus_P2T_age exp_x_55plus_c ///
	prop_black_P2T_age prop_asian_P2T_age prop_other_P2T_age ///
    prop_educ_q1_P2T_age prop_educ_q2_P2T_age prop_educ_q3_P2T_age prop_midwest_P2T_age ///
    prop_northeast_P2T_age prop_west_P2T_age prop_fem_P2T_age [aweight = freq_wt_P2T_age], vce(robust)
	outreg2 using "$export_root/June/txt/Het/age_B_v2.txt", keep(d_claude_S3_S1 prop_age_26less_P2T_age exp_x_26less_c prop_age_55plus_P2T_age exp_x_55plus_c) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_ageV1.dta", clear

local outcomes d_log_emp_P2T4T_age d_unemp_rate_P2T4T_age d_ahrswork1_P2T4T_age d_ahrswork2_P2T4T_age d_ahrsworkt_P2T4T_age ///
d_other_job_P2T4T_age d_fulltime_P2T4T_age
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_26less_P2T_age exp_x_26less_oa  ///
	prop_age_55plus_P2T_age exp_x_55plus_oa prop_black_P2T_age prop_asian_P2T_age prop_other_P2T_age ///
    prop_educ_q1_P2T_age prop_educ_q2_P2T_age prop_educ_q3_P2T_age prop_midwest_P2T_age ///
    prop_northeast_P2T_age prop_west_P2T_age prop_fem_P2T_age [aweight = freq_wt_P2T_age], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_age" {
        outreg2 using "$export_root/June/txt/Het/age_C_v2.txt", keep(d_openai_S3_S1 prop_age_26less_P2T_age exp_x_26less_oa prop_age_55plus_P2T_age exp_x_55plus_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/age_C_v2.txt", keep(d_openai_S3_S1 prop_age_26less_P2T_age exp_x_26less_oa prop_age_55plus_P2T_age exp_x_55plus_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_age_26less_P2T_age exp_x_26less_c  ///
	prop_age_55plus_P2T_age exp_x_55plus_c prop_black_P2T_age prop_asian_P2T_age prop_other_P2T_age ///
    prop_educ_q1_P2T_age prop_educ_q2_P2T_age prop_educ_q3_P2T_age prop_midwest_P2T_age ///
    prop_northeast_P2T_age prop_west_P2T_age prop_fem_P2T_age [aweight = freq_wt_P2T_age], vce(robust)
	outreg2 using "$export_root/June/txt/Het/age_C_v2.txt", keep(d_claude_S3_S1 prop_age_26less_P2T_age exp_x_26less_c prop_age_55plus_P2T_age exp_x_55plus_c) nocons append
}

*******************************************************************************************************************************************
************************************************************** BA or more **************************************************************
*******************************************************************************************************************************************
use "$data_root/Cleaned/het_occ2010/het_educV1.dta", clear

gen ba_or_more = educ_group == 3 | educ_group == 4
collapse (mean) d_log_emp_P2T4T_educ d_unemp_rate_P2T4T_educ d_ahrswork1_P2T4T_educ ///
    d_ahrswork2_P2T4T_educ d_ahrsworkt_P2T4T_educ d_other_job_P2T4T_educ d_fulltime_P2T4T_educ ///
    prop_* freq_wt_P2T_educ d_openai_S3_S1 d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore, by(occ2010 ba_or_more)

gen exp_x_ba_or_more_oa = d_openai_S3_S1 * ba_or_more
gen exp_x_ba_or_more_c = d_claude_S3_S1 * ba_or_more

save "$data_root/Cleaned/het_occ2010/het_educV2.dta", replace

*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_educV2.dta", clear

local outcomes d_log_emp_P2T4T_educ d_unemp_rate_P2T4T_educ d_ahrswork1_P2T4T_educ d_ahrswork2_P2T4T_educ d_ahrsworkt_P2T4T_educ ///
d_other_job_P2T4T_educ d_fulltime_P2T4T_educ
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 ba_or_more exp_x_ba_or_more_oa [aweight = freq_wt_P2T_educ], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_educ" {
        outreg2 using "$export_root/June/txt/Het/educ_A_ba_or_more.txt", keep(d_openai_S3_S1 ba_or_more exp_x_ba_or_more_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/educ_A_ba_or_more.txt", keep(d_openai_S3_S1 ba_or_more exp_x_ba_or_more_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 ba_or_more exp_x_ba_or_more_c [aweight = freq_wt_P2T_educ], vce(robust)
	outreg2 using "$export_root/June/txt/Het/educ_A_ba_or_more.txt", keep(d_claude_S3_S1 ba_or_more exp_x_ba_or_more_c) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_educV2.dta", clear

local outcomes d_log_emp_P2T4T_educ d_unemp_rate_P2T4T_educ d_ahrswork1_P2T4T_educ d_ahrswork2_P2T4T_educ d_ahrsworkt_P2T4T_educ ///
d_other_job_P2T4T_educ d_fulltime_P2T4T_educ

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 ba_or_more exp_x_ba_or_more_oa prop_age_26less_P2T_educ prop_age_55plus_P2T_educ prop_black_P2T_educ ///
	prop_asian_P2T_educ prop_other_P2T_educ prop_midwest_P2T_educ ///
    prop_northeast_P2T_educ prop_west_P2T_educ prop_fem_P2T_educ [aweight = freq_wt_P2T_educ], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_educ" {
        outreg2 using "$export_root/June/txt/Het/educ_B_ba_or_more.txt", keep(d_openai_S3_S1 ba_or_more exp_x_ba_or_more_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/educ_B_ba_or_more.txt", keep(d_openai_S3_S1 ba_or_more exp_x_ba_or_more_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 ba_or_more exp_x_ba_or_more_c prop_age_26less_P2T_educ prop_age_55plus_P2T_educ prop_black_P2T_educ ///
	prop_asian_P2T_educ prop_other_P2T_educ prop_midwest_P2T_educ ///
    prop_northeast_P2T_educ prop_west_P2T_educ prop_fem_P2T_educ [aweight = freq_wt_P2T_educ], vce(robust)
	outreg2 using "$export_root/June/txt/Het/educ_B_ba_or_more.txt", keep(d_claude_S3_S1 ba_or_more exp_x_ba_or_more_c) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_educV2.dta", clear

local outcomes d_log_emp_P2T4T_educ d_unemp_rate_P2T4T_educ d_ahrswork1_P2T4T_educ d_ahrswork2_P2T4T_educ d_ahrsworkt_P2T4T_educ ///
d_other_job_P2T4T_educ d_fulltime_P2T4T_educ
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore ba_or_more exp_x_ba_or_more_oa ///
	prop_age_26less_P2T_educ prop_age_55plus_P2T_educ prop_black_P2T_educ ///
	prop_asian_P2T_educ prop_other_P2T_educ prop_midwest_P2T_educ ///
    prop_northeast_P2T_educ prop_west_P2T_educ prop_fem_P2T_educ [aweight = freq_wt_P2T_educ], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_educ" {
        outreg2 using "$export_root/June/txt/Het/educ_C_ba_or_more.txt", keep(d_openai_S3_S1 ba_or_more exp_x_ba_or_more_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/educ_C_ba_or_more.txt", keep(d_openai_S3_S1 ba_or_more exp_x_ba_or_more_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore ba_or_more exp_x_ba_or_more_c prop_age_26less_P2T_educ prop_age_55plus_P2T_educ ///
	prop_black_P2T_educ prop_asian_P2T_educ prop_other_P2T_educ prop_midwest_P2T_educ ///
    prop_northeast_P2T_educ prop_west_P2T_educ prop_fem_P2T_educ [aweight = freq_wt_P2T_educ], vce(robust)
	outreg2 using "$export_root/June/txt/Het/educ_C_ba_or_more.txt", keep(d_claude_S3_S1 ba_or_more exp_x_ba_or_more_c) nocons append
}

*******************************************************************************************************************************************
************************************************************** More than BA **************************************************************
*******************************************************************************************************************************************
use "$data_root/Cleaned/het_occ2010/het_educV1.dta", clear

gen more_than_ba = educ_group == 4
collapse (mean) d_log_emp_P2T4T_educ d_unemp_rate_P2T4T_educ d_ahrswork1_P2T4T_educ ///
    d_ahrswork2_P2T4T_educ d_ahrsworkt_P2T4T_educ d_other_job_P2T4T_educ d_fulltime_P2T4T_educ ///
    prop_* freq_wt_P2T_educ d_openai_S3_S1 d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore, by(occ2010 more_than_ba)

gen exp_x_more_than_ba_oa = d_openai_S3_S1 * more_than_ba
gen exp_x_more_than_ba_c = d_claude_S3_S1 * more_than_ba

save "$data_root/Cleaned/het_occ2010/het_educV3.dta", replace

*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_educV3.dta", clear

local outcomes d_log_emp_P2T4T_educ d_unemp_rate_P2T4T_educ d_ahrswork1_P2T4T_educ d_ahrswork2_P2T4T_educ d_ahrsworkt_P2T4T_educ ///
d_other_job_P2T4T_educ d_fulltime_P2T4T_educ
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 more_than_ba exp_x_more_than_ba_oa [aweight = freq_wt_P2T_educ], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_educ" {
        outreg2 using "$export_root/June/txt/Het/educ_A_more_than_ba.txt", keep(d_openai_S3_S1 more_than_ba exp_x_more_than_ba_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/educ_A_more_than_ba.txt", keep(d_openai_S3_S1 more_than_ba exp_x_more_than_ba_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 more_than_ba exp_x_more_than_ba_c [aweight = freq_wt_P2T_educ], vce(robust)
	outreg2 using "$export_root/June/txt/Het/educ_A_more_than_ba.txt", keep(d_claude_S3_S1 more_than_ba exp_x_more_than_ba_c) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_educV3.dta", clear

local outcomes d_log_emp_P2T4T_educ d_unemp_rate_P2T4T_educ d_ahrswork1_P2T4T_educ d_ahrswork2_P2T4T_educ d_ahrsworkt_P2T4T_educ ///
d_other_job_P2T4T_educ d_fulltime_P2T4T_educ

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 more_than_ba exp_x_more_than_ba_oa prop_age_26less_P2T_educ prop_age_55plus_P2T_educ prop_black_P2T_educ ///
	prop_asian_P2T_educ prop_other_P2T_educ prop_midwest_P2T_educ ///
    prop_northeast_P2T_educ prop_west_P2T_educ prop_fem_P2T_educ [aweight = freq_wt_P2T_educ], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_educ" {
        outreg2 using "$export_root/June/txt/Het/educ_B_more_than_ba.txt", keep(d_openai_S3_S1 more_than_ba exp_x_more_than_ba_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/educ_B_more_than_ba.txt", keep(d_openai_S3_S1 more_than_ba exp_x_more_than_ba_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 more_than_ba exp_x_more_than_ba_c prop_age_26less_P2T_educ prop_age_55plus_P2T_educ prop_black_P2T_educ ///
	prop_asian_P2T_educ prop_other_P2T_educ prop_midwest_P2T_educ ///
    prop_northeast_P2T_educ prop_west_P2T_educ prop_fem_P2T_educ [aweight = freq_wt_P2T_educ], vce(robust)
	outreg2 using "$export_root/June/txt/Het/educ_B_more_than_ba.txt", keep(d_claude_S3_S1 more_than_ba exp_x_more_than_ba_c) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_educV3.dta", clear

local outcomes d_log_emp_P2T4T_educ d_unemp_rate_P2T4T_educ d_ahrswork1_P2T4T_educ d_ahrswork2_P2T4T_educ d_ahrsworkt_P2T4T_educ ///
d_other_job_P2T4T_educ d_fulltime_P2T4T_educ
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore more_than_ba exp_x_more_than_ba_oa ///
	prop_age_26less_P2T_educ prop_age_55plus_P2T_educ prop_black_P2T_educ ///
	prop_asian_P2T_educ prop_other_P2T_educ prop_midwest_P2T_educ ///
    prop_northeast_P2T_educ prop_west_P2T_educ prop_fem_P2T_educ [aweight = freq_wt_P2T_educ], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_educ" {
        outreg2 using "$export_root/June/txt/Het/educ_C_more_than_ba.txt", keep(d_openai_S3_S1 more_than_ba exp_x_more_than_ba_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/educ_C_more_than_ba.txt", keep(d_openai_S3_S1 more_than_ba exp_x_more_than_ba_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore more_than_ba exp_x_more_than_ba_c prop_age_26less_P2T_educ prop_age_55plus_P2T_educ ///
	prop_black_P2T_educ prop_asian_P2T_educ prop_other_P2T_educ prop_midwest_P2T_educ ///
    prop_northeast_P2T_educ prop_west_P2T_educ prop_fem_P2T_educ [aweight = freq_wt_P2T_educ], vce(robust)
	outreg2 using "$export_root/June/txt/Het/educ_C_more_than_ba.txt", keep(d_claude_S3_S1 more_than_ba exp_x_more_than_ba_c) nocons append
}


*******************************************************************************************************************************************
************************************************************* Race Analysis *************************************************************
*******************************************************************************************************************************************


*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_raceV1.dta", clear

local outcomes d_log_emp_P2T4T_race d_unemp_rate_P2T4T_race d_ahrswork1_P2T4T_race d_ahrswork2_P2T4T_race ///
d_ahrsworkt_P2T4T_race d_other_job_P2T4T_race d_fulltime_P2T4T_race
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race exp_x_asian_oa prop_other_P2T_race exp_x_other_oa ///
	[aweight = freq_wt_P2T_race], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_race" {
        outreg2 using "$export_root/June/txt/Het/race_A_v2.txt", keep(d_openai_S3_S1 prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race exp_x_asian_oa prop_other_P2T_race exp_x_other_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/race_A_v2.txt", keep(d_openai_S3_S1 prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race exp_x_asian_oa prop_other_P2T_race exp_x_other_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_black_P2T_race exp_x_black_c prop_asian_P2T_race exp_x_asian_c prop_other_P2T_race exp_x_other_c ///
	[aweight = freq_wt_P2T_race], vce(robust)
	outreg2 using "$export_root/June/txt/Het/race_A_v2.txt", keep(d_claude_S3_S1 prop_black_P2T_race exp_x_black_c prop_asian_P2T_race exp_x_asian_c prop_other_P2T_race exp_x_other_c ) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_raceV1.dta", clear

local outcomes d_log_emp_P2T4T_race d_unemp_rate_P2T4T_race d_ahrswork1_P2T4T_race d_ahrswork2_P2T4T_race ///
d_ahrsworkt_P2T4T_race d_other_job_P2T4T_race d_fulltime_P2T4T_race

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race exp_x_asian_oa prop_other_P2T_race exp_x_other_oa ///
	prop_northeast_P2T_race prop_midwest_P2T_race ///
	prop_west_P2T_race prop_fem_P2T_race prop_educ_q2_P2T_race prop_educ_q3_P2T_race prop_educ_q4_P2T_race ///
	prop_age_26less_P2T_race prop_age_55plus_P2T_race [aweight = freq_wt_P2T_race], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_race" {
        outreg2 using "$export_root/June/txt/Het/race_B_v2.txt", keep(d_openai_S3_S1 prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race exp_x_asian_oa prop_other_P2T_race exp_x_other_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/race_B_v2.txt", keep(d_openai_S3_S1 prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race exp_x_asian_oa prop_other_P2T_race exp_x_other_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_black_P2T_race exp_x_black_c prop_asian_P2T_race exp_x_asian_c prop_other_P2T_race exp_x_other_c ///
	prop_northeast_P2T_race prop_midwest_P2T_race ///
	prop_west_P2T_race prop_fem_P2T_race prop_educ_q2_P2T_race prop_educ_q3_P2T_race prop_educ_q4_P2T_race ///
	prop_age_26less_P2T_race prop_age_55plus_P2T_race [aweight = freq_wt_P2T_race], vce(robust)
	
	outreg2 using "$export_root/June/txt/Het/race_B_v2.txt", keep(d_claude_S3_S1 prop_black_P2T_race exp_x_black_c prop_asian_P2T_race exp_x_asian_c prop_other_P2T_race exp_x_other_c ) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_raceV1.dta", clear

local outcomes d_log_emp_P2T4T_race d_unemp_rate_P2T4T_race d_ahrswork1_P2T4T_race d_ahrswork2_P2T4T_race ///
d_ahrsworkt_P2T4T_race d_other_job_P2T4T_race d_fulltime_P2T4T_race

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race exp_x_asian_oa ///
	prop_other_P2T_race exp_x_other_oa prop_northeast_P2T_race prop_midwest_P2T_race ///
	prop_west_P2T_race prop_fem_P2T_race prop_educ_q2_P2T_race prop_educ_q3_P2T_race prop_educ_q4_P2T_race ///
	prop_age_26less_P2T_race prop_age_55plus_P2T_race [aweight = freq_wt_P2T_race], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_race" {
        outreg2 using "$export_root/June/txt/Het/race_C_v2.txt", keep(d_openai_S3_S1 prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race exp_x_asian_oa prop_other_P2T_race exp_x_other_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/race_C_v2.txt", keep(d_openai_S3_S1 prop_black_P2T_race exp_x_black_oa prop_asian_P2T_race exp_x_asian_oa prop_other_P2T_race exp_x_other_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_black_P2T_race exp_x_black_c prop_asian_P2T_race exp_x_asian_c ///
	prop_other_P2T_race exp_x_other_c prop_northeast_P2T_race prop_midwest_P2T_race ///
	prop_west_P2T_race prop_fem_P2T_race prop_educ_q2_P2T_race prop_educ_q3_P2T_race prop_educ_q4_P2T_race ///
	prop_age_26less_P2T_race prop_age_55plus_P2T_race [aweight = freq_wt_P2T_race], vce(robust)
	
	outreg2 using "$export_root/June/txt/Het/race_C_v2.txt", keep(d_claude_S3_S1 prop_black_P2T_race exp_x_black_c prop_asian_P2T_race exp_x_asian_c prop_other_P2T_race exp_x_other_c) nocons append
}

*******************************************************************************************************************************************
************************************************************* Region Analysis *************************************************************
*******************************************************************************************************************************************
use "$data_root/Cleaned/het_occ2010/het_regionV2_group.dta", clear
gen exp_x_westC_oa = d_openai_S3_S1 * prop_westC_P2T_region
gen exp_x_eastC_oa = d_openai_S3_S1 * prop_eastC_P2T_region


gen exp_x_westC_c = d_claude_S3_S1 * prop_westC_P2T_region
gen exp_x_eastC_c = d_claude_S3_S1 * prop_eastC_P2T_region


foreach outcome in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	replace `outcome'_P2T_P4T_reg = `outcome'_P2T_P4T_reg * 100
}

foreach outcome in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	rename `outcome'_P2T_P4T_reg `outcome'_P2T4T_region
}
save "$data_root/Cleaned/het_occ2010/het_regionV2.dta", replace

*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_regionV2.dta", clear

local outcomes d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_westC_P2T_region exp_x_westC_oa prop_eastC_P2T_region exp_x_eastC_oa [aweight = freq_wt_P2T_region], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/region_A_v2.txt", keep(d_openai_S3_S1 prop_westC_P2T_region exp_x_westC_oa prop_eastC_P2T_region exp_x_eastC_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/region_A_v2.txt", keep(d_openai_S3_S1 prop_westC_P2T_region exp_x_westC_oa prop_eastC_P2T_region exp_x_eastC_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_westC_P2T_region exp_x_westC_c prop_eastC_P2T_region exp_x_eastC_c [aweight = freq_wt_P2T_region], vce(robust)
	outreg2 using "$export_root/June/txt/Het/region_A_v2.txt", keep(d_claude_S3_S1 prop_westC_P2T_region exp_x_westC_c prop_eastC_P2T_region exp_x_eastC_c) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_regionV2.dta", clear

local outcomes d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1  prop_westC_P2T_region exp_x_westC_oa prop_eastC_P2T_region exp_x_eastC_oa ///
	prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/region_B_v2.txt", keep(d_openai_S3_S1 prop_westC_P2T_region exp_x_westC_oa prop_eastC_P2T_region exp_x_eastC_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/region_B_v2.txt", keep(d_openai_S3_S1 prop_westC_P2T_region exp_x_westC_oa prop_eastC_P2T_region exp_x_eastC_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_westC_P2T_region exp_x_westC_c prop_eastC_P2T_region exp_x_eastC_c ///
	prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
	
	outreg2 using "$export_root/June/txt/Het/region_B_v2.txt", keep(d_claude_S3_S1 prop_westC_P2T_region exp_x_westC_c prop_eastC_P2T_region exp_x_eastC_c) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_regionV2.dta", clear

local outcomes d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore  prop_westC_P2T_region exp_x_westC_oa prop_eastC_P2T_region exp_x_eastC_oa prop_fem_P2T_region ///
	prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/region_C_v2.txt", keep(d_openai_S3_S1 prop_westC_P2T_region exp_x_westC_oa prop_eastC_P2T_region exp_x_eastC_oa) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/region_C_v2.txt", keep(d_openai_S3_S1 prop_westC_P2T_region exp_x_westC_oa prop_eastC_P2T_region exp_x_eastC_oa) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_westC_P2T_region exp_x_westC_c prop_eastC_P2T_region exp_x_eastC_c ///
	prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region  [aweight = freq_wt_P2T_region], vce(robust)
	outreg2 using "$export_root/June/txt/Het/region_C_v2.txt", keep(d_claude_S3_S1 prop_westC_P2T_region exp_x_westC_c prop_eastC_P2T_region exp_x_eastC_c) nocons append
}


save "$data_root/Cleaned/het_occ2010/het_indV1.dta", replace

*******************************************************************************************************************************************
************************************************************* Ind 1 Analysis *************************************************************
*******************************************************************************************************************************************
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear
foreach outcome in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	replace `outcome'_P2T_P4T_ind = `outcome'_P2T_P4T_ind * 100
}

foreach outcome in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	rename `outcome'_P2T_P4T_ind `outcome'_P2T4T_ind
}


save "$data_root/Cleaned/het_occ2010/het_indV1.dta", replace

*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if ind1990_group == 1 [aweight = freq_wt_P2T_ind], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_A_v1.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_A_v1.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if ind1990_group == 1 [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/Het/ind_A_v1.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 1 [aweight = freq_wt_P2T_ind], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_B_v1.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_B_v1.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 1 [aweight = freq_wt_P2T_ind], vce(robust)
	
	outreg2 using "$export_root/June/txt/Het/ind_B_v1.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 1 [aweight = freq_wt_P2T_ind], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_C_v1.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_C_v1.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 1 [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/Het/ind_C_v1.txt", keep(d_claude_S3_S1) nocons append
}

*******************************************************************************************************************************************
************************************************************* Ind 2 Analysis *************************************************************
*******************************************************************************************************************************************

*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if ind1990_group == 2 [aweight = freq_wt_P2T_ind], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_A_v2.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_A_v2.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if ind1990_group == 2 [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/Het/ind_A_v2.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 2 [aweight = freq_wt_P2T_ind], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_B_v2.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_B_v2.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 2 [aweight = freq_wt_P2T_ind], vce(robust)
	
	outreg2 using "$export_root/June/txt/Het/ind_B_v2.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 2 [aweight = freq_wt_P2T_ind], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_C_v2.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_C_v2.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 2 [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/Het/ind_C_v2.txt", keep(d_claude_S3_S1) nocons append
}

*******************************************************************************************************************************************
************************************************************* Ind 3 Analysis *************************************************************
*******************************************************************************************************************************************

*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if ind1990_group == 3 [aweight = freq_wt_P2T_ind], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_A_v3.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_A_v3.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if ind1990_group == 3 [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/Het/ind_A_v3.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 3 [aweight = freq_wt_P2T_ind], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_B_v3.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_B_v3.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 3 [aweight = freq_wt_P2T_ind], vce(robust)
	
	outreg2 using "$export_root/June/txt/Het/ind_B_v3.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 3 [aweight = freq_wt_P2T_ind], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_C_v3.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_C_v3.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 3 [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/Het/ind_C_v3.txt", keep(d_claude_S3_S1) nocons append
}

*******************************************************************************************************************************************
************************************************************* Ind 4 Analysis *************************************************************
*******************************************************************************************************************************************

*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if ind1990_group == 4 [aweight = freq_wt_P2T_ind], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_A_v4.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_A_v4.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if ind1990_group == 4 [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/Het/ind_A_v4.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 4 [aweight = freq_wt_P2T_ind], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_B_v4.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_B_v4.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 4 [aweight = freq_wt_P2T_ind], vce(robust)
	
	outreg2 using "$export_root/June/txt/Het/ind_B_v4.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 4 [aweight = freq_wt_P2T_ind], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_C_v4.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_C_v4.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 4 [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/Het/ind_C_v4.txt", keep(d_claude_S3_S1) nocons append
}

*******************************************************************************************************************************************
************************************************************* Ind 5 Analysis *************************************************************
*******************************************************************************************************************************************

*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if ind1990_group == 5 [aweight = freq_wt_P2T_ind], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_A_v5.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_A_v5.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if ind1990_group == 5 [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/Het/ind_A_v5.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 5 [aweight = freq_wt_P2T_ind], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_B_v5.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_B_v5.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 5 [aweight = freq_wt_P2T_ind], vce(robust)
	
	outreg2 using "$export_root/June/txt/Het/ind_B_v5.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 5 [aweight = freq_wt_P2T_ind], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_C_v5.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_C_v5.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 5 [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/Het/ind_C_v5.txt", keep(d_claude_S3_S1) nocons append
}

*******************************************************************************************************************************************
************************************************************* Ind 6 Analysis *************************************************************
*******************************************************************************************************************************************

*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if ind1990_group == 6 [aweight = freq_wt_P2T_ind], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_A_v6.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_A_v6.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if ind1990_group == 6 [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/Het/ind_A_v6.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 6 [aweight = freq_wt_P2T_ind], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_B_v6.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_B_v6.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 6 [aweight = freq_wt_P2T_ind], vce(robust)
	
	outreg2 using "$export_root/June/txt/Het/ind_B_v6.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 6 [aweight = freq_wt_P2T_ind], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/Het/ind_C_v6.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_C_v6.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 6 [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/Het/ind_C_v6.txt", keep(d_claude_S3_S1) nocons append
}

*******************************************************************************************************************************************
************************************************************* Ind 7 Analysis *************************************************************
*******************************************************************************************************************************************

*** Baseline Model
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 if ind1990_group == 7 [aweight = freq_wt_P2T_ind], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_ind" {
        outreg2 using "$export_root/June/txt/Het/ind_A_v7.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_A_v7.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 if ind1990_group == 7 [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/Het/ind_A_v7.txt", keep(d_claude_S3_S1) nocons append
}

*** W/ Demographic Controls
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 7 [aweight = freq_wt_P2T_ind], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_ind" {
        outreg2 using "$export_root/June/txt/Het/ind_B_v7.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_B_v7.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 7 [aweight = freq_wt_P2T_ind], vce(robust)
	
	outreg2 using "$export_root/June/txt/Het/ind_B_v7.txt", keep(d_claude_S3_S1) nocons append
}

* W/ Demographic + Task Index Controls
use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 7 [aweight = freq_wt_P2T_ind], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_ind" {
        outreg2 using "$export_root/June/txt/Het/ind_C_v7.txt", keep(d_openai_S3_S1) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/Het/ind_C_v7.txt", keep(d_openai_S3_S1) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind if ind1990_group == 7 [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/Het/ind_C_v7.txt", keep(d_claude_S3_S1) nocons append
}

*******************************************************************************************************************************************
******************************************************* FIRE-Professional Analysis ********************************************************
*******************************************************************************************************************************************

use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear
gen fire_prof = inlist(ind1990_group, 5, 6, 7)
collapse (mean) d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind d_claude_S3_S1 freq_wt_P2T_ind d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind ///
	d_ahrswork2_P2T4T_ind d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind, by(occ2010 fire_prof)

gen exp_x_fire_prof_oa = d_openai_S3_S1 * fire_prof
gen exp_x_fire_prof_c = d_claude_S3_S1 * fire_prof

*** Baseline Model

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_fire_prof_oa fire_prof [aweight = freq_wt_P2T_ind], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_ind" {
        outreg2 using "$export_root/June/txt/6_23/fire_prof_a.txt", keep(d_openai_S3_S1 exp_x_fire_prof_oa fire_prof) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/fire_prof_a.txt", keep(d_openai_S3_S1 exp_x_fire_prof_oa fire_prof) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_fire_prof_c fire_prof [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/6_23/fire_prof_a.txt", keep(d_claude_S3_S1 exp_x_fire_prof_c fire_prof) nocons append
}

*** W/ Demographic Controls

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_fire_prof_oa fire_prof prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind [aweight = freq_wt_P2T_ind], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_ind" {
        outreg2 using "$export_root/June/txt/6_23/fire_prof_b.txt", keep(d_openai_S3_S1 exp_x_fire_prof_oa fire_prof) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/fire_prof_b.txt", keep(d_openai_S3_S1 exp_x_fire_prof_oa fire_prof) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_fire_prof_c fire_prof prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind [aweight = freq_wt_P2T_ind], vce(robust)
	
	outreg2 using "$export_root/June/txt/6_23/fire_prof_b.txt", keep(d_claude_S3_S1 exp_x_fire_prof_c fire_prof) nocons append
}

* W/ Demographic + Task Index Controls

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_fire_prof_oa fire_prof NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind ///
	prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind [aweight = freq_wt_P2T_ind], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_ind" {
        outreg2 using "$export_root/June/txt/6_23/fire_prof_c.txt", keep(d_openai_S3_S1 exp_x_fire_prof_oa fire_prof) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/fire_prof_c.txt", keep(d_openai_S3_S1 exp_x_fire_prof_oa fire_prof) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_fire_prof_c fire_prof NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind ///
	prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using  "$export_root/June/txt/6_23/fire_prof_c.txt", keep(d_claude_S3_S1 exp_x_fire_prof_c fire_prof) nocons append
}

*******************************************************************************************************************************************
******************************************************* Services Analysis ********************************************************
*******************************************************************************************************************************************

use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear
gen services = inlist(ind1990_group, 6, 7)
collapse (mean) d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind d_claude_S3_S1 freq_wt_P2T_ind d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind ///
	d_ahrswork2_P2T4T_ind d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind, by(occ2010 services)

gen exp_x_services_oa = d_openai_S3_S1 * services
gen exp_x_services_c = d_claude_S3_S1 * services

*** Baseline Model

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_services_oa services [aweight = freq_wt_P2T_ind], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_ind" {
        outreg2 using "$export_root/June/txt/6_23/services_a.txt", keep(d_openai_S3_S1 exp_x_services_oa services) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/services_a.txt", keep(d_openai_S3_S1 exp_x_services_oa services) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_services_c services [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/6_23/services_a.txt", keep(d_claude_S3_S1 exp_x_services_c services) nocons append
}

*** W/ Demographic Controls

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_services_oa services prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind [aweight = freq_wt_P2T_ind], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_ind" {
        outreg2 using "$export_root/June/txt/6_23/services_b.txt", keep(d_openai_S3_S1 exp_x_services_oa services) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/services_b.txt", keep(d_openai_S3_S1 exp_x_services_oa services) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_services_c services prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind [aweight = freq_wt_P2T_ind], vce(robust)
	
	outreg2 using "$export_root/June/txt/6_23/services_b.txt", keep(d_claude_S3_S1 exp_x_services_c services) nocons append
}

* W/ Demographic + Task Index Controls

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_services_oa services NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind ///
	prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind [aweight = freq_wt_P2T_ind], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_ind" {
        outreg2 using "$export_root/June/txt/6_23/services_c.txt", keep(d_openai_S3_S1 exp_x_services_oa services) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/services_c.txt", keep(d_openai_S3_S1 exp_x_services_oa services) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_services_c services NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind ///
	prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using  "$export_root/June/txt/6_23/services_c.txt", keep(d_claude_S3_S1 exp_x_services_c services) nocons append
}

*******************************************************************************************************************************************
******************************************************* Fire Analysis ********************************************************
*******************************************************************************************************************************************

use "$data_root/Cleaned/het_occ2010/het_indV1.dta", clear
gen fire = ind1990_group == 5
collapse (mean) d_openai_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind d_claude_S3_S1 freq_wt_P2T_ind d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind ///
	d_ahrswork2_P2T4T_ind d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind, by(occ2010 fire)

gen exp_x_fire_oa = d_openai_S3_S1 * fire
gen exp_x_fire_c = d_claude_S3_S1 * fire

*** Baseline Model

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_fire_oa fire [aweight = freq_wt_P2T_ind], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_ind" {
        outreg2 using "$export_root/June/txt/6_23/fire_a.txt", keep(d_openai_S3_S1 exp_x_fire_oa fire) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/fire_a.txt", keep(d_openai_S3_S1 exp_x_fire_oa fire) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_fire_c fire [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using "$export_root/June/txt/6_23/fire_a.txt", keep(d_claude_S3_S1 exp_x_fire_c fire) nocons append
}

*** W/ Demographic Controls

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_fire_oa fire prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind [aweight = freq_wt_P2T_ind], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_ind" {
        outreg2 using "$export_root/June/txt/6_23/fire_b.txt", keep(d_openai_S3_S1 exp_x_fire_oa fire) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/fire_b.txt", keep(d_openai_S3_S1 exp_x_fire_oa fire) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_fire_c fire prop_fem_P2T_ind prop_educ_q2_P2T_ind prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind [aweight = freq_wt_P2T_ind], vce(robust)
	
	outreg2 using "$export_root/June/txt/6_23/fire_b.txt", keep(d_claude_S3_S1 exp_x_fire_c fire) nocons append
}

* W/ Demographic + Task Index Controls

local outcomes d_log_emp_P2T4T_ind d_unemp_rate_P2T4T_ind d_ahrswork1_P2T4T_ind d_ahrswork2_P2T4T_ind ///
d_ahrsworkt_P2T4T_ind d_other_job_P2T4T_ind d_fulltime_P2T4T_ind

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_fire_oa fire NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind ///
	prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind [aweight = freq_wt_P2T_ind], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_ind" {
        outreg2 using "$export_root/June/txt/6_23/fire_c.txt", keep(d_openai_S3_S1 exp_x_fire_oa fire) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/fire_c.txt", keep(d_openai_S3_S1 exp_x_fire_oa fire) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_fire_c fire NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_ind prop_educ_q2_P2T_ind ///
	prop_educ_q3_P2T_ind prop_educ_q4_P2T_ind ///
	prop_age_26less_P2T_ind prop_age_55plus_P2T_ind prop_black_P2T_ind prop_asian_P2T_ind prop_other_P2T_ind prop_west_P2T_ind ///
	prop_midwest_P2T_ind prop_northeast_P2T_ind [aweight = freq_wt_P2T_ind], vce(robust)
	outreg2 using  "$export_root/June/txt/6_23/fire_c.txt", keep(d_claude_S3_S1 exp_x_fire_c fire) nocons append
}

*******************************************************************************************************************************************
************************************************************ Coastal Analysis *************************************************************
*******************************************************************************************************************************************

use "$data_root/Cleaned/het_occ2010/het_regionV2.dta", clear
gen coast = inlist(region_group, 1, 2)

collapse (mean) d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_westC_P2T_region prop_eastC_P2T_region ///
	prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region prop_age_26less_P2T_region ///
	prop_age_55plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region d_openai_S3_S1 ///
	freq_wt_P2T_region d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
	d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region, by (occ2010 coast)


gen exp_x_coast_oa = d_openai_S3_S1 * coast
gen exp_x_coast_c = d_claude_S3_S1 * coast


*** Baseline Model

local outcomes d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_coast_oa coast [aweight = freq_wt_P2T_region], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/6_23/coast_A.txt", keep(d_openai_S3_S1 exp_x_coast_oa coast) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/coast_A.txt", keep(d_openai_S3_S1 exp_x_coast_oa coast) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_coast_c coast [aweight = freq_wt_P2T_region], vce(robust)
	outreg2 using "$export_root/June/txt/6_23/coast_A.txt", keep(d_claude_S3_S1 exp_x_coast_c coast) nocons append
}

*** W/ Demographic Controls

local outcomes d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_coast_oa coast ///
	prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/6_23/coast_B.txt", keep(d_openai_S3_S1 exp_x_coast_oa coast) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/coast_B.txt", keep(d_openai_S3_S1 exp_x_coast_oa coast) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_coast_c coast ///
	prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
	
	outreg2 using "$export_root/June/txt/6_23/coast_B.txt", keep(d_claude_S3_S1 exp_x_coast_c coast) nocons append
}

* W/ Demographic + Task Index Controls

local outcomes d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_coast_oa coast NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_region ///
	prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/6_23/coast_C.txt", keep(d_openai_S3_S1 exp_x_coast_oa coast) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/coast_C.txt", keep(d_openai_S3_S1 exp_x_coast_oa coast) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_coast_c coast NR_CA NR_CI RC RM NRMP offshore ///
	prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region  [aweight = freq_wt_P2T_region], vce(robust)
	outreg2 using "$export_root/June/txt/6_23/coast_C.txt", keep(d_claude_S3_S1 exp_x_coast_c coast) nocons append
}

*******************************************************************************************************************************************
*********************************************************** Rust-Belt Analysis ************************************************************
*******************************************************************************************************************************************

use "$data_root/Cleaned/het_occ2010/het_regionV2_rust.dta", clear

gen exp_x_rust_oa = d_openai_S3_S1 * prop_rust_P2T_region
gen exp_x_nonrust_oa = d_openai_S3_S1 * prop_nonrust_P2T_region


gen exp_x_rust_c = d_claude_S3_S1 * prop_rust_P2T_region
gen exp_x_nonrust_c = d_claude_S3_S1 * prop_nonrust_P2T_region



foreach outcome in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	replace `outcome'_P2T_P4T_reg = `outcome'_P2T_P4T_reg * 100
}

foreach outcome in d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime {
	rename `outcome'_P2T_P4T_reg `outcome'_P2T4T_region
}
save "$data_root/Cleaned/het_occ2010/het_regionV2_rust.dta", replace

*** Baseline Model

local outcomes d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_rust_oa prop_rust_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/6_23/rust_A.txt", keep(d_openai_S3_S1 exp_x_rust_oa prop_rust_P2T_region) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/rust_A.txt", keep(d_openai_S3_S1 exp_x_rust_oa prop_rust_P2T_region) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_rust_c prop_rust_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
	outreg2 using "$export_root/June/txt/6_23/rust_A.txt", keep( d_claude_S3_S1 exp_x_rust_c prop_rust_P2T_region) nocons append
}

*** W/ Demographic Controls

local outcomes d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_rust_oa prop_rust_P2T_region ///
	prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/6_23/rust_B.txt", keep(d_openai_S3_S1 exp_x_rust_oa prop_rust_P2T_region) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/rust_B.txt", keep(d_openai_S3_S1 exp_x_rust_oa prop_rust_P2T_region) nocons append
    }
}

foreach y in `outcomes' {
	reg `y'  d_claude_S3_S1 exp_x_rust_c prop_rust_P2T_region ///
	prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
	
	outreg2 using "$export_root/June/txt/6_23/rust_B.txt", keep( d_claude_S3_S1 exp_x_rust_c prop_rust_P2T_region) nocons append
}

* W/ Demographic + Task Index Controls

local outcomes d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_rust_oa prop_rust_P2T_region NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_region ///
	prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/6_23/rust_C.txt", keep(d_openai_S3_S1 exp_x_rust_oa prop_rust_P2T_region) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/rust_C.txt", keep(d_openai_S3_S1 exp_x_rust_oa prop_rust_P2T_region) nocons append
    }
}

foreach y in `outcomes' {
	reg `y'  d_claude_S3_S1 exp_x_rust_c prop_rust_P2T_region NR_CA NR_CI RC RM NRMP offshore ///
	prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region  [aweight = freq_wt_P2T_region], vce(robust)
	outreg2 using "$export_root/June/txt/6_23/rust_C.txt", keep( d_claude_S3_S1 exp_x_rust_c prop_rust_P2T_region) nocons append
}

*******************************************************************************************************************************************
************************************************************* South Analysis *************************************************************
*******************************************************************************************************************************************
use "$data_root/Cleaned/het_occ2010/het_regionV1.dta", clear
gen south = (region_major == 3)
collapse(mean) d_claude_S3_S1 NR_CA NR_CI RC RM NRMP offshore prop_south_P2T_region prop_fem_P2T_region prop_educ_q2_P2T_region ///
prop_educ_q3_P2T_region prop_educ_q4_P2T_region prop_age_26less_P2T_region prop_age_55plus_P2T_region ///
prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region d_log_emp_P2T4T_region ///
d_unemp_rate_P2T4T_region  d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region ///
d_fulltime_P2T4T_region d_openai_S3_S1 freq_wt_P2T_region, by (occ2010 south)

gen exp_x_south_oa = d_openai_S3_S1 * south
gen exp_x_south_c = d_claude_S3_S1 * south


*** Baseline Model
local outcomes d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region
foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_south_oa south [aweight = freq_wt_P2T_region], vce(robust)
    
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/6_23/south_A.txt", keep(d_openai_S3_S1 exp_x_south_oa south) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/south_A.txt", keep(d_openai_S3_S1 exp_x_south_oa south) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_south_c south [aweight = freq_wt_P2T_region], vce(robust)
	outreg2 using "$export_root/June/txt/6_23/south_A.txt", keep(d_claude_S3_S1 exp_x_south_c south) nocons append
}

*** W/ Demographic Controls
local outcomes d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_south_oa south prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region ///
	[aweight = freq_wt_P2T_region], vce(robust)
   
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/6_23/south_B.txt", keep(d_openai_S3_S1 exp_x_south_oa south) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/south_B.txt", keep(d_openai_S3_S1 exp_x_south_oa south) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_south_c south prop_fem_P2T_region prop_educ_q2_P2T_region prop_educ_q3_P2T_region prop_educ_q4_P2T_region ///
	prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region prop_asian_P2T_region prop_other_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
	
	outreg2 using "$export_root/June/txt/6_23/south_B.txt", keep(d_claude_S3_S1 exp_x_south_c south) nocons append
}


* W/ Demographic + Task Index Controls
local outcomes d_log_emp_P2T4T_region d_unemp_rate_P2T4T_region d_ahrswork1_P2T4T_region d_ahrswork2_P2T4T_region ///
d_ahrsworkt_P2T4T_region d_other_job_P2T4T_region d_fulltime_P2T4T_region

foreach y in `outcomes' {
    reg `y' d_openai_S3_S1 exp_x_south_oa south NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_region prop_educ_q2_P2T_region ///
	prop_educ_q3_P2T_region prop_educ_q4_P2T_region prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region ///
	prop_asian_P2T_region prop_other_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
	
    if "`y'" == "d_log_emp_P2T4T_region" {
        outreg2 using "$export_root/June/txt/6_23/south_C.txt", keep(d_openai_S3_S1 exp_x_south_oa south) nocons replace
    }
    else {
        outreg2 using "$export_root/June/txt/6_23/south_C.txt", keep(d_openai_S3_S1 exp_x_south_oa south) nocons append
    }
}

foreach y in `outcomes' {
	reg `y' d_claude_S3_S1 exp_x_south_c south  NR_CA NR_CI RC RM NRMP offshore prop_fem_P2T_region prop_educ_q2_P2T_region ///
	prop_educ_q3_P2T_region prop_educ_q4_P2T_region prop_age_26less_P2T_region prop_age_55plus_P2T_region prop_black_P2T_region ///
	prop_asian_P2T_region prop_other_P2T_region [aweight = freq_wt_P2T_region], vce(robust)
	outreg2 using "$export_root/June/txt/6_23/south_C.txt", keep(d_claude_S3_S1 exp_x_south_c south) nocons append
}


