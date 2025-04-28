********************************************************************************************************************
*************************************************** Housekeeping ***************************************************
********************************************************************************************************************

*Jacob
global data_root = "/Users/jdomins2/Desktop/CPS_Work/Data"
global export_root = "/Users/jdomins2/Desktop/CPS_Work/Output"

**************************************** Non-Routine Cognitive: Analytical *****************************************
import delimited "$data_root/onet/NRCA/Analyzing_Data_or_Information.csv", clear
rename importance analyzing_data
drop level jobzone
save "$data_root/onet/NRCA/NR_Cog_Anayl.dta", replace

import delimited "$data_root/onet/NRCA/Interpreting_the_Meaning_of_Information_for_Others.csv", clear
rename importance interp_info_for_others
drop level jobzone
merge 1:1 code using "$data_root/onet/NRCA/NR_Cog_Anayl.dta"
drop _merge
save "$data_root/onet/NRCA/NR_Cog_Anayl.dta", replace

import delimited "$data_root/onet/NRCA/Thinking_Creatively.csv", clear
rename importance thinking_creatively
drop level jobzone
merge 1:1 code using "$data_root/onet/NRCA/NR_Cog_Anayl.dta"
drop _merge
save "$data_root/onet/NRCA/NR_Cog_Anayl.dta", replace


* Summing 3 measures *
gen NR_CA = analyzing_data + thinking_creatively + interp_info_for_others
sum NR_CA, det
*** Mean = 179.1035; SD = 42.81721 ***

* Standardizing *
replace NR_CA = (NR_CA - 179.1035) / 42.81721
sum NR_CA, det
save "$data_root/onet/NRCA/NR_Cog_Anayl.dta", replace

*************************************** Non-Routine Cognitive: Interpersonal ***************************************
import delimited "$data_root/onet/NRC-I/Establishing_and_Maintaining_Interpersonal_Relationships.csv", clear
rename importance estab_relations
drop level jobzone
save "$data_root/onet/NRC-I/NR_Cog_Interp.dta", replace

import delimited "$data_root/onet/NRC-I/Guiding_Directing_and_Motivating_Subordinates.csv", clear
rename importance GDM_subordinates
drop level jobzone
merge 1:1 code using "$data_root/onet/NRC-I/NR_Cog_Interp.dta"
drop _merge
save "$data_root/onet/NRC-I/NR_Cog_Interp.dta", replace

import delimited "$data_root/onet/NRC-I/Coaching_and_Developing_Others.csv", clear
rename importance coach_dev
drop level jobzone
merge 1:1 code using "$data_root/onet/NRC-I/NR_Cog_Interp.dta"
drop _merge
save "$data_root/onet/NRC-I/NR_Cog_Interp.dta", replace


* Summing 3 measures *
gen NR_CI = estab_relations + GDM_subordinates + coach_dev
sum NR_CI, det
*** Mean = 166.61895; SD = 36.94272 ***

* Standardizing *
replace NR_CI = (NR_CI - 166.6189) / 36.94272
sum NR_CI, det
save "$data_root/onet/NRC-I/NR_Cog_Interp.dta", replace

************************************************ Routine Cognitive *************************************************
import delimited "$data_root/onet/RC/Importance_of_Repeating_Same_Tasks.csv", clear
rename context rep_tasks
drop jobzone
save "$data_root/onet/RC/RC.dta", replace

import delimited "$data_root/onet/RC/Importance_of_Being_Exact_or_Accurate.csv", clear
rename context exact_acc
drop jobzone
merge 1:1 code using "$data_root/onet/RC/RC.dta"
drop _merge
save "$data_root/onet/RC/RC.dta", replace

*** Reverse Coded ***
import delimited "$data_root/onet/RC/Determine_Tasks_Priorities_and_Goals.csv", clear
rename context structure
gen structure_rev = 100 - structure
br structure structure_rev occupation

drop jobzone
merge 1:1 code using "$data_root/onet/RC/RC.dta"
drop _merge
save "$data_root/onet/RC/RC.dta", replace

* Summing 3 measures *
gen RC = rep_tasks + exact_acc + structure_rev
sum RC, det
*** Mean = 161.2594; SD = 27.80322 ***

* Standardizing *
replace RC = (RC - 161.2594) / 27.80322
sum RC, det
save "$data_root/onet/RC/RC.dta", replace

************************************************** Routine Manual **************************************************
import delimited "$data_root/onet/RM/Pace_Determined_by_Speed_of_Equipment.csv", clear
rename context pace_det_equip
drop jobzone
save "$data_root/onet/RM/RM.dta", replace

import delimited "$data_root/onet/RM/Controlling_Machines_and_Processes.csv", clear
rename importance control_machines
drop level jobzone
merge 1:1 code using "$data_root/onet/RM/RM.dta"
drop _merge
save "$data_root/onet/RM/RM.dta", replace

import delimited "$data_root/onet/RM/Spend_Time_Making_Repetitive_Motions.csv", clear
rename context rep_mot
drop jobzone
merge 1:1 code using "$data_root/onet/RM/RM.dta"
drop _merge
save "$data_root/onet/RM/RM.dta", replace

* Summing 3 measures *
gen RM = pace_det_equip + control_machines + rep_mot
sum RM, det
*** Mean = 119.818; SD = 56.26018 ***

* Normalizing *
replace RM = (RM - 119.818) / 56.26018
sum RM, det
save "$data_root/onet/RM/RM.dta", replace


******************************************** Non-routine Manual Physical ********************************************
import delimited "$data_root/onet/NRMP/Operating_Vehicles_Mechanized_Devices_or_Equipment.csv", clear
rename importance oper_equip
drop level jobzone
save "$data_root/onet/NRMP/NRMP", replace

import delimited "$data_root/onet/NRMP/Spend_Time_Using_Your_Hands_to_Handle_Control_or_Feel_Objects_Tools_or_Controls.csv", clear
rename context use_hands
drop jobzone
merge 1:1 code using "$data_root/onet/NRMP/NRMP"
drop _merge
save "$data_root/onet/NRMP/NRMP", replace

import delimited "$data_root/onet/NRMP/Manual_Dexterity.csv", clear
rename importance dexterity
drop level jobzone
merge 1:1 code using "$data_root/onet/NRMP/NRMP"
drop _merge
save "$data_root/onet/NRMP/NRMP", replace

import delimited "$data_root/onet/NRMP/Spatial_Orientation.csv", clear
rename importance spat_orientation
drop level jobzone
merge 1:1 code using "$data_root/onet/NRMP/NRMP"
drop _merge
save "$data_root/onet/NRMP/NRMP", replace

* Summing 3 measures *
gen NRMP = oper_equip + use_hands + dexterity + spat_orientation
sum NRMP, det
*** Mean = 145.8703; SD = 74.92973 ***

* Normalizing *
replace NRMP = (NRMP - 145.8703) / 74.92973
sum NRMP, det
save "$data_root/onet/NRMP/NRMP.dta", replace

************************************************** Offshorability **************************************************
*** Reverse Coded ***
import delimited "$data_root/onet/offshore/Face-to-Face_Discussions_with_Individuals_and_Within_Teams.csv", clear
rename context face_disc
replace face_disc = "." if face_disc == "Not available"
destring face_disc, replace
replace face_disc = 100 - face_disc 
drop jobzone
save "$data_root/onet/offshore/offshore.dta", replace

*** Reverse Coded ***
import delimited "$data_root/onet/offshore/Assisting_and_Caring_for_Others.csv", clear
rename importance caring_for_others
replace caring_for_others = 100 - caring_for_others
drop level jobzone
merge 1:1 code using "$data_root/onet/offshore/offshore.dta"
drop _merge
save "$data_root/onet/offshore/offshore.dta", replace

*** Reverse Coded ***
import delimited "$data_root/onet/offshore/Performing_for_or_Working_Directly_with_the_Public.csv", clear
rename importance work_w_pub
replace work_w_pub = 100 - work_w_pub
drop level jobzone
merge 1:1 code using "$data_root/onet/offshore/offshore.dta"
drop _merge
save "$data_root/onet/offshore/offshore.dta", replace

*** Reverse Coded ***
import delimited "$data_root/onet/offshore/Inspecting_Equipment_Structures_or_Materials.csv", clear
rename importance inspecting
replace inspecting = 100 - inspecting
drop level jobzone
merge 1:1 code using "$data_root/onet/offshore/offshore.dta"
drop _merge
save "$data_root/onet/offshore/offshore.dta", replace

*** Reverse Coded ***
import delimited "$data_root/onet/offshore/Handling_and_Moving_Objects.csv", clear
rename importance moving_obj
replace moving_obj = 100 - moving_obj
drop level jobzone
merge 1:1 code using "$data_root/onet/offshore/offshore.dta"
drop _merge
save "$data_root/onet/offshore/offshore.dta", replace

*** Reverse Coded and Weighted by 1/2 ***
import delimited "$data_root/onet/offshore/Repairing_and_Maintaining_Mechanical_Equipment.csv", clear
rename importance mech_equip
replace mech_equip = "." if mech_equip == "Not available"
destring mech_equip, replace
gen mech_equip_wt = (100 - mech_equip) * 0.5
br mech_equip mech_equip_wt
drop level jobzone
drop mech_equip
rename mech_equip_wt mech_equip
merge 1:1 code using "$data_root/onet/offshore/offshore.dta"
drop _merge
save "$data_root/onet/offshore/offshore.dta", replace

*** Reverse Coded and Weighted by 1/2 ***
import delimited "$data_root/onet/offshore/Repairing_and_Maintaining_Electronic_Equipment.csv", clear
rename importance elec_equip
gen elec_equip_wt = (100 - elec_equip) * 0.5
br elec_equip elec_equip_wt
drop level jobzone
drop elec_equip
rename elec_equip_wt elec_equip
merge 1:1 code using "$data_root/onet/offshore/offshore.dta"
drop _merge
save "$data_root/onet/offshore/offshore.dta", replace

* Summing 3 measures *
gen offshore = face_disc + caring_for_others + work_w_pub + inspecting + moving_obj + mech_equip + elec_equip
sum offshore, det
*** Mean = 282.4065; SD = 72.02838 ***

* Normalizing *
replace offshore = (offshore - 282.4065) / 72.02838 
sum offshore, det
save "$data_root/onet/offshore/offshore.dta", replace

********************************************* Merging All Onet Scores **********************************************
use "$data_root/onet/NRCA/NR_Cog_Anayl.dta", clear
merge 1:1 code using "$data_root/onet/NRC-I/NR_Cog_Interp.dta"
drop _merge

merge 1:1 code using "$data_root/onet/RC/RC.dta"
drop _merge

merge 1:1 code using "$data_root/onet/RM/RM.dta"
drop _merge

merge 1:1 code using "$data_root/onet/NRMP/NRMP.dta"
drop _merge

merge 1:1 code using "$data_root/onet/offshore/offshore.dta"
drop _merge

drop analyzing_data thinking_creatively interp_info_for_others estab_relations GDM_subordinates coach_dev rep_tasks exact_acc structure_rev pace_det_equip control_machines rep_mot oper_equip use_hands dexterity spat_orientation face_disc caring_for_others work_w_pub inspecting moving_obj mech_equip elec_equip

save "$data_root/Cleaned/AA_routine.dta", replace

********************************************* Aggregating to CPS Level *********************************************
use "$data_root/Cleaned/AA_routine.dta", clear
rename code onet_code
merge 1:m onet_code using "$crosswalk_root/onet_to_cps_crosswalk_cleaned.dta"
drop if _merge == 2
drop _merge

bysort soc_code cps_code (onet_code): gen num_valid_onet_codes = _N
gen onet_weight_valid = 1 / num_valid_onet_codes

foreach var in NR_CA NR_CI RC RM NRMP offshore {
	gen `var'_onet_wt = `var' * onet_weight_valid
}

collapse (sum) NR_CA_onet_wt NR_CI_onet_wt RC_onet_wt RM_onet_wt NRMP_onet_wt offshore_onet_wt, by(cps_code soc_code)
save "$data_root/Working/soc_AA_routine.dta", replace

import excel "/Users/jdomins2/Desktop/CPS_Work/Crosswalks/Online/BLS/employment_data_soc.xlsx", firstrow clear
duplicates list soc_code
list soc_code tot_emp if soc_code == "13-1020" | soc_code == "13-2020" | soc_code == "29-2010" | soc_code == "31-1120" | soc_code == "39-7010" | soc_code == "47-4090" | soc_code == "51-2090" 
duplicates drop soc_code, force


merge 1:m soc_code using "$data_root/Working/soc_AA_routine.dta"
drop if _merge == 1 | _merge == 2
drop _merge

egen tot_cps_emp = total(tot_emp), by(cps_code)
gen soc_wt = tot_emp/tot_cps_emp
br cps_code soc_code tot_emp tot_cps_emp soc_wt

rename NR_CA_onet_wt NR_CA
rename NR_CI_onet_wt NR_CI
rename RC_onet_wt RC
rename RM_onet_wt RM
rename NRMP_onet_wt NRMP
rename offshore_onet_wt offshore

foreach var in NR_CA NR_CI RC RM NRMP offshore {
	gen `var'_socwt = `var' * soc_wt
}

collapse (sum) NR_CA_socwt NR_CI_socwt RC_socwt RM_socwt NRMP_socwt offshore_socwt, by(cps_code)
rename NR_CA_socwt NR_CA
rename NR_CI_socwt NR_CI
rename RC_socwt RC
rename RM_socwt RM
rename NRMP_socwt NRMP
rename offshore_socwt offshore

save "$data_root/Working/soc_AA_routine.dta", replace

merge 1:m cps_code using "$data_root/Cleaned/monthly_cps_w_exp_v2.dta"

*** We are missing 15 unique CPS occupations (1021, 2755, 3401, 3402, 3515, 3725, 3946, 4840, 60, 6115, 705, 845, 9121, 9141, 9142); these occupations do not have work activity data. 


