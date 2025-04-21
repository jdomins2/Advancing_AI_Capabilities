* Name: CPS Het.
* Date Created: April 10, 2025
* Author:  Jacob Dominski


********************************************************************************************************************************
********************************************************* Housekeeping *********************************************************
********************************************************************************************************************************

*Jacob
global data_root = "/Users/jdomins2/Desktop/CPS_Work/Data"
global export_root = "/Users/jdomins2/Desktop/CPS_Work/Output"

use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear


* Exposure Quartiles for OpenAI and Claude Exposure Scores, stages 1, 3, & 5
foreach var in openai1 openai2 openai3 openai4 openai5 claude1 claude2 claude3 claude4 claude5{
	xtile q_`var' = `var', nquantiles(4)
}

gen educ_q1_interaction = prop_educ_q1_2022 * openai2
gen educ_q2_interaction = prop_educ_q2_2022 * openai2
gen educ_q3_interaction = prop_educ_q3_2022 * openai2
gen educ_q4_interaction = prop_educ_q4_2022 * openai2

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


foreach stage in 1 2 3 {
	foreach num in 1 2 3 4 {
			gen exp_q`num'_interaction_openai`stage' = DQ`num'_openai`stage' * openai`stage'
			gen exp_q`num'_interaction_claude`stage' = DQ`num'_claude`stage' * claude`stage'
	}
}

gen d_MBF = 1 if cps_code <= 960
gen d_prof = 1 if cps_code > 960 & cps_code <= 3550
gen d_serv = 1 if cps_code > 3550 & cps_code <= 4655
gen d_sales = 1 if cps_code > 4655 & cps_code <= 4965
gen d_office = 1 if cps_code > 4965 & cps_code <= 5940
gen d_FFF = 1 if cps_code > 5940 & cps_code <= 6130
gen d_construc = 1 if cps_code > 6130 & cps_code <= 6950
gen d_IMR = 1 if cps_code > 6950 & cps_code <= 7640
gen d_produc = 1 if cps_code > 7640 & cps_code <= 8990
gen d_TMM = 1 if cps_code > 8990 & cps_code <= 9760

foreach name in MBF prof serv sales office FFF construc IMR produc TMM {
	gen `name'_interaction = d_`name' * openai2
}

foreach name in MBF prof serv sales office FFF construc IMR produc TMM {
	replace `name'_interaction = 0 if missing(`name'_interaction)
}



save "$data_root/Cleaned/6M_LD_Stageexp.dta", replace

********************************************************************************************************************************
***************************************************** Broadest CPS Groups ******************************************************
********************************************************************************************************************************


*** Management, business, and financial occupations 0010-0960 ***
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear

local sources "openai claude"
local stages "1 2 3"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

foreach stage of local stages {
    local outpath "$export_root/April/TEX/Het2/6M_ld_s`stage'_MBFO.txt"
    foreach source of local sources {
        local exposure = "`source'`stage'"
        foreach outcome of local outcomes {
            reg `outcome' `exposure' if cps_code <= 960 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `exposure' `controls' if cps_code <= 960 [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", append
        }
    }
}

*** Professional and related occupations; 1005-3550 ***
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear

local sources "openai claude"
local stages "1 2 3"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

foreach stage of local stages {
    local outpath "$export_root/April/TEX/Het2/6M_ld_s`stage'_Prof.txt"
    foreach source of local sources {
        local exposure = "`source'`stage'"
        foreach outcome of local outcomes {
            reg `outcome' `exposure' if cps_code > 960 & cps_code <= 3550 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `exposure' `controls' if cps_code > 960 & cps_code <= 3550 [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", append
        }
    }
}

*** Service occupations 3601-4655 ***
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear

local sources "openai claude"
local stages "1 2 3"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

foreach stage of local stages {
    local outpath "$export_root/April/TEX/Het2/6M_ld_s`stage'_serv.txt"
    foreach source of local sources {
        local exposure = "`source'`stage'"
        foreach outcome of local outcomes {
            reg `outcome' `exposure' if cps_code > 3550 & cps_code <= 4655 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `exposure' `controls' if cps_code > 3550 & cps_code <= 4655  [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", append
        }
    }
}

*** Sales and related occupations 4700-4965 ***
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear

local sources "openai claude"
local stages "1 2 3"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

foreach stage of local stages {
    local outpath "$export_root/April/TEX/Het2/6M_ld_s`stage'_sales.txt"
    foreach source of local sources {
        local exposure = "`source'`stage'"
        foreach outcome of local outcomes {
            reg `outcome' `exposure' if cps_code > 4655 & cps_code <= 4965 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `exposure' `controls' if cps_code > 4655 & cps_code <= 4965  [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", append
        }
    }
}

*** Office and administrative support occupations 5000-5940 ***
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear

local sources "openai claude"
local stages "1 2 3"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

foreach stage of local stages {
    local outpath "$export_root/April/TEX/Het2/6M_ld_s`stage'_office.txt"
    foreach source of local sources {
        local exposure = "`source'`stage'"
        foreach outcome of local outcomes {
            reg `outcome' `exposure' if cps_code > 4965 & cps_code <= 5940 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `exposure' `controls' if cps_code > 4965 & cps_code <= 5940  [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", append
        }
    }
}


*** Farming, fishing, and forestry occupations 6005-6130 *** NOTE: Too few obs for controls
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear

local sources "openai claude"
local stages "1 2 3"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_educ_q1_2022 prop_educ_q3_2022 prop_midwest_2022 prop_fem_2022"

foreach stage of local stages {
    local outpath "$export_root/April/TEX/Het2/6M_ld_s`stage'_FFF.txt"
    foreach source of local sources {
        local exposure = "`source'`stage'"
        foreach outcome of local outcomes {
            reg `outcome' `exposure' if cps_code > 5940 & cps_code <= 6130 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `exposure' `controls' if cps_code > 5940 & cps_code <= 6130  [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", append
        }
    }
}

*** Construction and extraction occupations 6200-6950 ***
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear

local sources "openai claude"
local stages "1 2 3"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

foreach stage of local stages {
    local outpath "$export_root/April/TEX/Het2/6M_ld_s`stage'_construction.txt"
    foreach source of local sources {
        local exposure = "`source'`stage'"
        foreach outcome of local outcomes {
            reg `outcome' `exposure' if cps_code > 6130 & cps_code <= 6950 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `exposure' `controls' if cps_code > 6130 & cps_code <= 6950  [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", append
        }
    }
}

*** Installation, maintenance, and repair occupations 7000-7640 ***
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear

local sources "openai claude"
local stages "1 2 3"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

foreach stage of local stages {
    local outpath "$export_root/April/TEX/Het2/6M_ld_s`stage'_IMR.txt"
    foreach source of local sources {
        local exposure = "`source'`stage'"
        foreach outcome of local outcomes {
            reg `outcome' `exposure' if cps_code > 6950 & cps_code <= 7640 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `exposure' `controls' if cps_code > 6950 & cps_code <= 7640  [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", append
        }
    }
}

*** Production occupations 7700-8990 ***
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear

local sources "openai claude"
local stages "1 2 3"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

foreach stage of local stages {
    local outpath "$export_root/April/TEX/Het2/6M_ld_s`stage'_produc.txt"
    foreach source of local sources {
        local exposure = "`source'`stage'"
        foreach outcome of local outcomes {
            reg `outcome' `exposure' if cps_code > 7640 & cps_code <= 8990 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `exposure' `controls' if cps_code > 7640 & cps_code <= 8990  [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", append
        }
    }
}

*** Transportation and material moving occupations 9005-9760 ***
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear

local sources "openai claude"
local stages "1 2 3"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

foreach stage of local stages {
    local outpath "$export_root/April/TEX/Het2/6M_ld_s`stage'_TMM.txt"
    foreach source of local sources {
        local exposure "`source'`stage'"
        foreach outcome of local outcomes {
            reg `outcome' `exposure' if cps_code > 8990 & cps_code <= 9760 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `exposure' `controls' if cps_code > 8990 & cps_code <= 9760 [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", append
        }
    }
}

********************************************************************************************************************************
****************************************************** Exposure Quartiles ******************************************************
********************************************************************************************************************************


*** Top Quartile of Exposure ***
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear

local sources "openai claude"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

    local outpath "$export_root/April/TEX/Het2/6M_ld_s2_Q4.txt"
    foreach source of local sources {
        foreach outcome of local outcomes {
            reg `outcome' `source'2 if q_`source'2 == 4 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `source'2 `controls' if q_`source'2 == 4 [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", append
        }
    }

*** Second Top Quartile of Exposure ***
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear

local sources "openai claude"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

    local outpath "$export_root/April/TEX/Het2/6M_ld_s2_Q3.txt"
    foreach source of local sources {
        foreach outcome of local outcomes {
            reg `outcome' `source'2 if q_`source'2 == 3 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `source'2 `controls' if q_`source'2 == 3 [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", append
        }
    }

*** Third Top Quartile of Exposure ***
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear

local sources "openai claude"
local stages "1 2 3"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

foreach stage of local stages {
    local outpath "$export_root/April/TEX/Het2/6M_ld_s`stage'_Q2.txt"
    foreach source of local sources {
        local exposure "`source'`stage'"
        foreach outcome of local outcomes {
            reg `outcome' `exposure' if q_openai2 == 2 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `exposure' `controls' if q_openai2 == 2 [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", append
        }
    }
}

*** Bottom Quartile of Exposure ***
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear

local sources "openai claude"
local stages "1 2 3"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

foreach stage of local stages {
    local outpath "$export_root/April/TEX/Het2/6M_ld_s`stage'_Q1.txt"
    foreach source of local sources {
        local exposure "`source'`stage'"
        foreach outcome of local outcomes {
            reg `outcome' `exposure' if q_openai2 == 1 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `exposure' `controls' if q_openai2 == 1 [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", append
        }
    }
}


********************************************************************************************************************************
*************************************************** Occupations by Quartiles ***************************************************
********************************************************************************************************************************
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear
merge 1:1 cps_code using "$data_root/Working/cps_titles.dta"
save "$data_root/Cleaned/6M_LD_Stageexp.dta", replace

gsort -openai2
list cps_title openai2 occ_freq_wt if q_openai2 == 4
list cps_title openai2 occ_freq_wt if q_openai2 == 3
list cps_title openai2 occ_freq_wt if q_openai2 == 2
list cps_title openai2 occ_freq_wt if q_openai2 == 1

********************************************************************************************************************************
*************************************** Interaction Terms (Exposure Quartile - Updated) ****************************************
********************************************************************************************************************************
use "$data_root/Cleaned/6M_LD_Stageexp.dta", clear

*** Just Fixed Effects ***
local sources "openai claude"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

    local outpath "$export_root/April/TEX/Het3/6M_ld_s`stage'_baseline.txt"
    foreach source of local sources {
        local exposure "`source'2"
        foreach outcome of local outcomes {
            reg `outcome' DQ1_`exposure'  DQ2_`exposure'  DQ3_`exposure' DQ4_`exposure' [aweight = occ_freq_wt], vce(robust) nocons
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", keep(DQ1_`exposure'  DQ2_`exposure'  DQ3_`exposure' DQ4_`exposure') replace
            }
            else {
                outreg2 using "`outpath'", keep(DQ1_`exposure'  DQ2_`exposure'  DQ3_`exposure' DQ4_`exposure') append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' DQ1_`exposure'  DQ2_`exposure'  DQ3_`exposure' DQ4_`exposure' `controls' [aweight = occ_freq_wt], vce(robust) nocons
            outreg2 using "`outpath'", keep(DQ1_`exposure'  DQ2_`exposure'  DQ3_`exposure' DQ4_`exposure') append
        }
    }

*** Top Quartile Interaction Term ***

local sources "openai claude"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

local outpath "$export_root/April/TEX/int2/6M_ld_s2_Q4_Int.txt"
foreach source of local sources {
        foreach outcome of local outcomes {
            reg `outcome' `source'2 DQ4_`source'2 exp_q4_interaction_`source'2 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", keep(`source'2 DQ4_`source'2 exp_q4_interaction_`source'2) replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `source'2 DQ4_`source'2 exp_q4_interaction_`source'2 `controls' [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", keep(`source'2 DQ4_`source'2 exp_q4_interaction_`source'2) append
        }
    }
	
*** Top 2 Quartile Interaction Terms ***

local sources "openai claude"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

local outpath "$export_root/April/TEX/int2/6M_ld_s2_Q4_Q3_Int.txt"
foreach source of local sources {
        foreach outcome of local outcomes {
            reg `outcome' `source'2 DQ4_`source'2 DQ3_`source'2 exp_q4_interaction_`source'2 exp_q3_interaction_`source'2 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", keep(`source'2 DQ4_`source'2 DQ3_`source'2 exp_q4_interaction_`source'2 exp_q3_interaction_`source'2) replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `source'2 DQ4_`source'2 DQ3_`source'2 exp_q4_interaction_`source'2 exp_q3_interaction_`source'2 `controls' [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", keep(`source'2 DQ4_`source'2 DQ3_`source'2 exp_q4_interaction_`source'2 exp_q3_interaction_`source'2) append
        }
    }
	
*** Bottom 3 Quartile Interaction Terms ***

local sources "openai claude"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

local outpath "$export_root/April/TEX/int2/6M_ld_s2_Q3_Q2_Q1_Int.txt"
foreach source of local sources {
        foreach outcome of local outcomes {
            reg `outcome' `source'2 DQ3_`source'2 DQ2_`source'2 DQ1_`source'2 exp_q3_interaction_`source'2 exp_q2_interaction_`source'2 exp_q1_interaction_`source'2 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", keep(`source'2 DQ3_`source'2 DQ2_`source'2 DQ1_`source'2 exp_q3_interaction_`source'2 exp_q2_interaction_`source'2 exp_q1_interaction_`source'2) replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `source'2 DQ3_`source'2 DQ2_`source'2 DQ1_`source'2 exp_q3_interaction_`source'2 exp_q2_interaction_`source'2 exp_q1_interaction_`source'2 `controls' [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", keep(`source'2 DQ3_`source'2 DQ2_`source'2 DQ1_`source'2 exp_q3_interaction_`source'2 exp_q2_interaction_`source'2 exp_q1_interaction_`source'2) append
        }
    }
	
reg d_ahrswork2 openai2 DQ3_openai2 DQ2_openai2 DQ1_openai2 exp_q3_interaction_openai2 exp_q2_interaction_openai2 exp_q1_interaction_openai2 prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022 [aweight = occ_freq_wt], vce(robust)


*** Bottom 3 Quartile Interaction Terms (Stage 1) ***

local sources "openai claude"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

local outpath "$export_root/April/TEX/int2/6M_ld_s1_Q3_Q2_Q1_Int.txt"
foreach source of local sources {
        foreach outcome of local outcomes {
            reg `outcome' `source'1 DQ3_`source'1 DQ2_`source'1 DQ1_`source'1 exp_q3_interaction_`source'1 exp_q2_interaction_`source'1 exp_q1_interaction_`source'1 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", keep(`source'1 DQ3_`source'1 DQ2_`source'1 DQ1_`source'1 exp_q3_interaction_`source'1 exp_q2_interaction_`source'1 exp_q1_interaction_`source'1) replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `source'1 DQ3_`source'1 DQ2_`source'1 DQ1_`source'1 exp_q3_interaction_`source'1 exp_q2_interaction_`source'1 exp_q1_interaction_`source'1 `controls' [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", keep(`source'1 DQ3_`source'1 DQ2_`source'1 DQ1_`source'1 exp_q3_interaction_`source'1 exp_q2_interaction_`source'1 exp_q1_interaction_`source'1) append
        }
    }
	
	
*** Bottom 3 Quartile Interaction Terms (Stage 3) ***

local sources "openai claude"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

local outpath "$export_root/April/TEX/int2/6M_ld_s3_Q3_Q2_Q1_Int.txt"
foreach source of local sources {
        foreach outcome of local outcomes {
            reg `outcome' `source'3 DQ3_`source'3 DQ2_`source'3 DQ1_`source'3 exp_q3_interaction_`source'3 exp_q2_interaction_`source'3 exp_q1_interaction_`source'3 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", keep(`source'3 DQ3_`source'3 DQ2_`source'3 DQ1_`source'3 exp_q3_interaction_`source'3 exp_q2_interaction_`source'3 exp_q1_interaction_`source'3) replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `source'3 DQ3_`source'3 DQ2_`source'3 DQ1_`source'3 exp_q3_interaction_`source'3 exp_q2_interaction_`source'3 exp_q1_interaction_`source'3 `controls' [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", keep(`source'3 DQ3_`source'3 DQ2_`source'3 DQ1_`source'3 exp_q3_interaction_`source'3 exp_q2_interaction_`source'3 exp_q1_interaction_`source'3) append
        }
    }

*** Bottom 2 Quartile Interaction Terms ***

local sources "openai claude"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

local outpath "$export_root/April/TEX/int2/6M_ld_s2_Q2_Q1_Int.txt"
foreach source of local sources {
        foreach outcome of local outcomes {
            reg `outcome' `source'2 DQ2_`source'2 DQ1_`source'2 exp_q2_interaction_`source'2 exp_q1_interaction_`source'2 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", keep(`source'2 DQ2_`source'2 DQ1_`source'2 exp_q2_interaction_`source'2 exp_q1_interaction_`source'2) replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `source'2 DQ2_`source'2 DQ1_`source'2 exp_q2_interaction_`source'2 exp_q1_interaction_`source'2 `controls' [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", keep(`source'2 DQ2_`source'2 DQ1_`source'2 exp_q2_interaction_`source'2 exp_q1_interaction_`source'2) append
        }
    }
	
*** Bottom Quartile Interaction Term ***

local sources "openai claude"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

local outpath "$export_root/April/TEX/int2/6M_ld_s2_Q1_Int.txt"
foreach source of local sources {
        foreach outcome of local outcomes {
            reg `outcome' `source'2 DQ1_`source'2 exp_q1_interaction_`source'2 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", keep(`source'2 DQ1_`source'2 exp_q1_interaction_`source'2) replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `source'2 DQ1_`source'2 exp_q1_interaction_`source'2 `controls' [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", keep(`source'2 DQ1_`source'2 exp_q1_interaction_`source'2) append
        }
    }
	
	
*** Top 3 Quartile Interaction Terms ***

local sources "openai claude"
local outcomes "d_log_emp d_unemp_rate d_ahrswork1 d_ahrswork2 d_ahrsworkt d_other_job d_fulltime"
local controls "prop_age_30to50_2022 prop_age_50plus_2022 prop_black_2022 prop_asian_2022 prop_native_2022 prop_mixed_other_2022 prop_pacific_2022 prop_educ_q1_2022 prop_educ_q2_2022 prop_educ_q3_2022 prop_midwest_2022 prop_northeast_2022 prop_west_2022 prop_fem_2022"

local outpath "$export_root/April/TEX/int2/6M_ld_s2_Q4_Q3_Q2_Int.txt"
foreach source of local sources {
        foreach outcome of local outcomes {
            reg `outcome' `source'2 DQ4_`source'2 DQ3_`source'2 DQ2_`source'2 exp_q4_interaction_`source'2 exp_q3_interaction_`source'2 exp_q2_interaction_`source'2 [aweight = occ_freq_wt], vce(robust)
            if "`source'" == "openai" & "`outcome'" == "d_log_emp" {
                outreg2 using "`outpath'", keep(`source'2 DQ4_`source'2 DQ3_`source'2 DQ2_`source'2 exp_q4_interaction_`source'2 exp_q3_interaction_`source'2 exp_q2_interaction_`source'2) replace
            }
            else {
                outreg2 using "`outpath'", append
            }
        }
        foreach outcome of local outcomes {
            reg `outcome' `source'2 DQ4_`source'2 DQ3_`source'2 DQ2_`source'2 exp_q4_interaction_`source'2 exp_q3_interaction_`source'2 exp_q2_interaction_`source'2 `controls' [aweight = occ_freq_wt], vce(robust)
            outreg2 using "`outpath'", keep(`source'2 DQ4_`source'2 DQ3_`source'2 DQ2_`source'2 exp_q4_interaction_`source'2 exp_q3_interaction_`source'2 exp_q2_interaction_`source'2) append
        }
    }



