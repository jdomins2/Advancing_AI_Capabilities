* Name: cps_event_study.do
* Author: Jacob Dominski
* Date Created: Febuary 19, 2025
* Last Updated:

*******************************************************************************************************************
************************************************** Housekeeping ***************************************************
*******************************************************************************************************************

************************************************ Set Global paths *************************************************
global data_root = "/Users/jdomins2/Desktop/CPS_Work/Data"
global crosswalk_root = "/Users/jdomins2/Desktop/CPS_Work/Crosswalks"
global export_root = "/Users/jdomins2/Desktop/CPS_Work/Output"
global deflator_root = "/Users/jdomins2/Desktop/CPS_Work/Deflators"
global code_root = "/Users/jdomins2/Desktop/CPS_Work/Code"

************************************************ Load Census Data *************************************************
use "$data_root/CPS/monthly_cps_v1.dta", clear
*21,811,973 observations*

************************************************ Install Programs *************************************************
ssc install reghdfe, replace
ssc install ftools, replace
ssc install ivreg2, replace

*******************************************************************************************************************
*************************************** Updated  Event studies by occupation ***************************************
*******************************************************************************************************************
use "$data_root/Cleaned/monthly_cps_w_ai_scores.dta", clear
destring cps_code, replace


eventdd Dunemp if cps_code == 800, hdfe absorb(i.cps_code) timevar(ntime) ci(rcap) lags(25) leads(25) inrange


coefplot, keep(lead25 lead24 lead23 lead22 lead21 lead20 lead19 lead18 lead17 lead16 ///
               lead15 lead14 lead13 lead12 lead11 lead10 lead9 lead8 lead7 lead6 ///
               lead5 lead4 lead3 lead2 lead1 lag0 lag1 lag2 lag3 lag4 lag5 lag6 ///
               lag7 lag8 lag9 lag10 lag11 lag12 lag13 lag14 lag15 lag16 lag17 ///
               lag18 lag19 lag20 lag21 lag22 lag23 lag24 lag25) ///
    vertical ciopts(recast(rarea) color(gs12)) /// <-- Confidence band
    xlabel(1 "−25"6 "−20" 11 "−15" 16 "−10" 21 "−5" 26 "0" ///
           31 "5" 36 "10" 41 "15" 46 "20"  51 "25", nogextend) ///
    ytitle("Unemployed") ///
    xtitle("Month since ChatGPT (Dec. 2022=0)") ///
    xline(26, lcolor(black) lwidth(medthick)) /// <-- Vertical line at x=0 (true 0 is at 26 due to shifting)
    yline(0, lcolor(red) lwidth(medthick))    /// <-- Horizontal line at y=0




* Step 1: Create a shifted event time variable (so that -25 becomes 1, 0 becomes 26, and 25 becomes 51)
gen ntime_shift = ntime + 26

* Step 2: Run the regression with event time dummies and fixed effects using the shifted variable
reg Dunemp i.ntime_shift i.cps_code if cps_code==800, robust

* Step 3: Compute the predicted effects (margins) over the shifted event time range
margins, at(ntime_shift=(1(1)51))

* Step 4: Plot the margins with continuous confidence bands and re-label the x-axis
marginsplot, ciopts(recast(area) color(gs12%50)) ///
    xlabel(1 " -25" 6 " -20" 11 " -15" 16 " -10" 21 " -5" 26 "0" 31 "5" 36 "10" 41 "15" 46 "20" 51 "25") ///
    xtitle("Event Time") yline(0)





 




*******************************************************************************************************************
******************************************* Event studies by occupation *******************************************
*******************************************************************************************************************

*************************** Occupations in Draft of Workforce Dynamics in the Age of AI ***************************
use "$data_root/Cleaned/monthly_cps_cleaned_v1", clear


*Accountants and auditors
eventdd Dunemp if occ == 800, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_800.png", replace
count if occ == 800

eventdd ahrswork1 if occ == 800, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_HRS_WRK_800.png", replace
count if occ == 800

*Market research analysts and marketing specialists
eventdd Dunemp if occ == 735, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_735.png", replace
count if occ == 735

eventdd ahrswork1 if occ == 735, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_HRS_WRK_735.png", replace
count if occ == 735

*Marketing managers
eventdd Dunemp if occ == 51, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_51.png", replace
count if occ == 51

eventdd ahrswork1 if occ == 51, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_HRS_WRK_51.png", replace
count if occ == 51

*Software developers
eventdd Dunemp if occ == 1021, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_1021.png", replace
count if occ == 1021

eventdd ahrswork1 if occ == 1021, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_HRS_WRK_1021.png", replace
count if occ == 1021

*Lawyers
eventdd Dunemp if occ == 2100, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_2100.png", replace
count if occ == 2100

eventdd ahrswork1 if occ == 2100, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_HRS_WRK_2100.png", replace
count if occ == 2100

*Paralegals and legal assistants
eventdd Dunemp if occ == 2145, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_2145.png", replace
count if occ == 2145

eventdd ahrswork1 if occ == 2145, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_HRS_WRK_2145.png", replace
count if occ == 2145

*Graphic designers
eventdd Dunemp if occ == 2634, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_2634.png", replace
count if occ == 2634

eventdd ahrswork1 if occ == 2634, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_HRS_WRK_2634.png", replace
count if occ == 2634

*Editors
eventdd Dunemp if occ == 2830, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_2830.png", replace
count if occ == 2830

eventdd ahrswork1 if occ == 2830, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_HRS_WRK_2830.png", replace
count if occ == 2830

*Writers and authors
eventdd Dunemp if occ == 2850, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_2850.png", replace
count if occ == 2850

eventdd ahrswork1 if occ == 2850, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_HRS_WRK_2850.png", replace
count if occ == 2850

********************************** Office and Administrative Support Occupations **********************************

* Bookkeeping, Accounting, and Auditing clerks (5120)
eventdd Dunemp if occ == 5120, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/ES_5120.png", replace

eventdd ahrswork1 if occ == 5120, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_HRS_WRK_5120.png", replace
count if occ == 5120


* First-line supervisors of office and administrative support workers
eventdd Dunemp if occ == 5000, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5000.png", replace

* Switchboard operators, including answering service
eventdd Dunemp if occ == 5010, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5010.png", replace

*Telephone operators
eventdd Dunemp if occ == 5020, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5020.png", replace

*Communications equipment operators, all other
eventdd Dunemp if occ == 5040, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5040.png", replace

*Bill and account collectors
eventdd Dunemp if occ == 5100, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5100.png", replace

*Billing and posting clerks
eventdd Dunemp if occ == 5110, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5110.png", replace

*Gambling cage workers
eventdd Dunemp if occ == 5130, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5130.png", replace

* Payroll and timekeeping clerks
eventdd Dunemp if occ == 5140, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5140.png", replace

*Procurement clerks
eventdd Dunemp if occ == 5150, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5150.png", replace

*Tellers
eventdd Dunemp if occ == 5160, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5160.png", replace

*Financial clerks, all other
eventdd Dunemp if occ == 5165, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5165.png", replace

*Brokerage clerks
eventdd Dunemp if occ == 5200, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5200.png", replace

*Court, municipal, and license clerks
eventdd Dunemp if occ == 5220, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5220.png", replace

*Credit authorizers, checkers, and clerks
eventdd Dunemp if occ == 5230, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5230.png", replace

*Customer service representatives
eventdd Dunemp if occ == 5240, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5240.png", replace

*Eligibility interviewers, government programs
eventdd Dunemp if occ == 5250, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5250.png", replace

*File clerks
eventdd Dunemp if occ == 5260, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5260.png", replace

*Hotel, motel, and resort desk clerks
eventdd Dunemp if occ == 5300, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5300.png", replace

*Interviewers, except eligibility and loan
eventdd Dunemp if occ == 5310, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5310.png", replace

*Library assistants, clerical
eventdd Dunemp if occ == 5320, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5320.png", replace

*Loan interviewers and clerks
eventdd Dunemp if occ == 5330, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5330.png", replace

*New accounts clerks
eventdd Dunemp if occ == 5340, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5340.png", replace

*Order clerks
eventdd Dunemp if occ == 5350, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5350.png", replace

*Human resources assistants, except payroll and timekeeping
eventdd Dunemp if occ == 5360, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5360.png", replace

*Receptionists and information clerks
eventdd Dunemp if occ == 5400, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5400.png", replace

*Reservation and transportation ticket agents and travel clerks
eventdd Dunemp if occ == 5410, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5410.png", replace
count if occ == 5410

*Information and record clerks, all other
eventdd Dunemp if occ == 5420, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5420.png", replace
count if occ == 5420

*Cargo and freight agents
eventdd Dunemp if occ == 5500, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5500.png", replace
count if occ == 5500

*Couriers and messengers
eventdd Dunemp if occ == 5510, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5510.png", replace
count if occ == 5510

*Public safety telecommunicators
eventdd Dunemp if occ == 5521, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5521.png", replace
count if occ == 5521

*Dispatchers, except police, fire, and ambulance
eventdd Dunemp if occ == 5522, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5522.png", replace
count if occ == 5522

*Meter readers, utilities
eventdd Dunemp if occ == 5530, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5530.png", replace
count if occ == 5530

*Postal service clerks
eventdd Dunemp if occ == 5540, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5540.png", replace
count if occ == 5540

*Postal service mail carriers
eventdd Dunemp if occ == 5550, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5550.png", replace
count if occ == 5550

*Postal service mail sorters, processors, and processing machine operators
eventdd Dunemp if occ == 5560, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5560.png", replace
count if occ == 5560

*Production, planning, and expediting clerks
eventdd Dunemp if occ == 5600, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5600.png", replace
count if occ == 5600

*Shipping, receiving, and inventory clerks
eventdd Dunemp if occ == 5610, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5610.png", replace
count if occ == 5610

*Weighers, measurers, checkers, and samplers, recordkeeping
eventdd Dunemp if occ == 5630, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5630.png", replace
count if occ == 5630

*Executive secretaries and executive administrative assistants*
eventdd Dunemp if occ == 5710, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5710.png", replace
count if occ == 5710

*Legal secretaries and administrative assistants
eventdd Dunemp if occ == 5720, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5720.png", replace
count if occ == 5720

*Medical secretaries and administrative assistants
eventdd Dunemp if occ == 5730, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5730.png", replace
count if occ == 5730

*Secretaries and administrative assistants, except legal, medical, and executive
eventdd Dunemp if occ == 5740, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5740.png", replace
count if occ == 5740

eventdd ahrswork1 if occ == 5740, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_HRS_WRK_5740.png", replace
count if occ == 5740

*Data entry keyers
eventdd Dunemp if occ == 5810, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5810.png", replace
count if occ == 5810

*Word processors and typists
eventdd Dunemp if occ == 5820, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5820.png", replace
count if occ == 5820

*Desktop publishers
eventdd Dunemp if occ == 5830, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5830.png", replace
count if occ == 5830

*Insurance claims and policy processing clerks
eventdd Dunemp if occ == 5840, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5840.png", replace
count if occ == 5840

*Mail clerks and mail machine operators, except postal service
eventdd Dunemp if occ == 5850, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5850.png", replace
count if occ == 5850

*Office clerks, general
eventdd Dunemp if occ == 5860, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5860.png", replace
count if occ == 5860

eventdd ahrswork1 if occ == 5860, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_HRS_WRK_5860.png", replace
count if occ == 5860

*Office machine operators, except computer
eventdd Dunemp if occ == 5900, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5900.png", replace
count if occ == 5900

*Proofreaders and copy markers
eventdd Dunemp if occ == 5910, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5910.png", replace
count if occ == 5910

*Statistical assistants
eventdd Dunemp if occ == 5920, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5920.png", replace
count if occ == 5920

*Office and administrative support workers, all other
eventdd Dunemp if occ == 5940, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/ES_5940.png", replace
count if occ == 5940


********************************* Computer, Engineering, and Science Occupations **********************************

* Computer and mathematical occupations, ALL
eventdd Dunemp if occ >= 1005 & occ <= 1240, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1005_1240.png", replace
count if occ >= 1005 & occ <= 1240

eventdd ahrswork1 if occ >= 1005 & occ <= 1240, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/In_Draft/ES_HRS_WRK_1005_1240.png", replace
count if occ >= 1005 & occ <= 1240

*Computer and information research scientists
eventdd Dunemp if occ == 1005, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1005.png", replace
count if occ == 1005

eventdd ahrswork1 if occ == 1005, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1005.png", replace
count if occ == 1005

*Computer systems analysts
eventdd Dunemp if occ == 1006, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1006.png", replace
count if occ == 1006

eventdd ahrswork1 if occ == 1006, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1006.png", replace
count if occ == 1006

*Information security analysts
eventdd Dunemp if occ == 1007, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1007.png", replace
count if occ == 1007

eventdd ahrswork1 if occ == 1007, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1007.png", replace
count if occ == 1007

*Computer programmers
eventdd Dunemp if occ == 1010, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1010.png", replace
count if occ == 1010

eventdd ahrswork1 if occ == 1010, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1010.png", replace
count if occ == 1010

*Software developers
eventdd Dunemp if occ == 1021, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1021.png", replace
count if occ == 1021

eventdd ahrswork1 if occ == 1021, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1021.png", replace
count if occ == 1021

*Software quality assurance analysts and testers
eventdd Dunemp if occ == 1022, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1022.png", replace
count if occ == 1022

eventdd ahrswork1 if occ == 1022, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1022.png", replace
count if occ == 1022

*Web developers
eventdd Dunemp if occ == 1031, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1031.png", replace
count if occ == 1031

eventdd ahrswork1 if occ == 1031, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1031.png", replace
count if occ == 1031

*Web and digital interface designers
eventdd Dunemp if occ == 1032, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1032.png", replace
count if occ == 1032

eventdd ahrswork1 if occ == 1032, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1032.png", replace
count if occ == 1032

*Computer support specialists
eventdd Dunemp if occ == 1050, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1050.png", replace
count if occ == 1050

eventdd ahrswork1 if occ == 1050, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1050.png", replace
count if occ == 1050

*Database administrators and architects
eventdd Dunemp if occ == 1065, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1065.png", replace
count if occ == 1065

eventdd ahrswork1 if occ == 1065, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1065.png", replace
count if occ == 1065

*Network and computer systems administrators
eventdd Dunemp if occ == 1105, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1105.png", replace
count if occ == 1105

eventdd ahrswork1 if occ == 1105, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1105.png", replace
count if occ == 1105

*Computer network architects
eventdd Dunemp if occ == 1106, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1106.png", replace
count if occ == 1106

eventdd ahrswork1 if occ == 1106, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1106.png", replace
count if occ == 1106

*Computer occupations, all other
eventdd Dunemp if occ == 1108, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1108.png", replace
count if occ == 1108

eventdd ahrswork1 if occ == 1108, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1108.png", replace
count if occ == 1108

*Actuaries
eventdd Dunemp if occ == 1200, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1200.png", replace
count if occ == 1200

eventdd ahrswork1 if occ == 1200, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1200.png", replace
count if occ == 1200

*Mathematicians
eventdd Dunemp if occ == 1210, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1210.png", replace
count if occ == 1210

eventdd ahrswork1 if occ == 1210, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1210.png", replace
count if occ == 1210

*Operations research analysts
eventdd Dunemp if occ == 1220, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1220.png", replace
count if occ == 1220

eventdd ahrswork1 if occ == 1220, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1220.png", replace
count if occ == 1220

*Statisticians
eventdd Dunemp if occ == 1230, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1230.png", replace
count if occ == 1230

eventdd ahrswork1 if occ == 1230, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1230.png", replace
count if occ == 1230

*Other mathematical science occupations
eventdd Dunemp if occ == 1240, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1240.png", replace
count if occ == 1240

eventdd ahrswork1 if occ == 1240, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1240.png", replace
count if occ == 1240

*Architecture and Engineering Occupations, ALL
eventdd Dunemp if occ >= 1305 & occ <= 1560, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1305_1560.png", replace
count if occ >= 1305 & occ <= 1560

eventdd ahrswork1 if occ >= 1305 & occ <= 1560, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1305_1560.png", replace
count if occ >= 1305 & occ <= 1560

*Architects, except landscape and naval
eventdd Dunemp if occ == 1305, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1305.png", replace
count if occ == 1305

eventdd ahrswork1 if occ == 1305, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1305.png", replace
count if occ == 1305

*Landscape architects
eventdd Dunemp if occ == 1306, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1306.png", replace
count if occ == 1306

eventdd ahrswork1 if occ == 1306, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1306.png", replace
count if occ == 1306

*Surveyors, cartographers, and photogrammetrists
eventdd Dunemp if occ == 1310, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1310.png", replace
count if occ == 1310

eventdd ahrswork1 if occ == 1310, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1310.png", replace
count if occ == 1310

*Aerospace engineers
eventdd Dunemp if occ == 1320, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1320.png", replace
count if occ == 1320

eventdd ahrswork1 if occ == 1320, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1320.png", replace
count if occ == 1320

*Agricultural engineers
eventdd Dunemp if occ == 1330, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1330.png", replace
count if occ == 1330

eventdd ahrswork1 if occ == 1330, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1330.png", replace
count if occ == 1330

*Bioengineers and biomedical engineers
eventdd Dunemp if occ == 1340, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1340.png", replace
count if occ == 1340

eventdd ahrswork1 if occ == 1340, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1340.png", replace
count if occ == 1340

*Chemical engineers
eventdd Dunemp if occ == 1350, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1350.png", replace
count if occ == 1350

eventdd ahrswork1 if occ == 1350, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1350.png", replace
count if occ == 1350

*Civil engineers
eventdd Dunemp if occ == 1360, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1360.png", replace
count if occ == 1360

eventdd ahrswork1 if occ == 1360, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1360.png", replace
count if occ == 1360

*Computer hardware engineers
eventdd Dunemp if occ == 1400, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1400.png", replace
count if occ == 1400

eventdd ahrswork1 if occ == 1400, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1400.png", replace
count if occ == 1400

*Electrical and electronics engineers
eventdd Dunemp if occ == 1410, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1410.png", replace
count if occ == 1410

eventdd ahrswork1 if occ == 1410, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1410.png", replace
count if occ == 1410

*Environmental engineers
eventdd Dunemp if occ == 1420, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1420.png", replace
count if occ == 1420

eventdd ahrswork1 if occ == 1420, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1420.png", replace
count if occ == 1420

*Industrial engineers, including health and safety
eventdd Dunemp if occ == 1430, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1430.png", replace
count if occ == 1430

eventdd ahrswork1 if occ == 1430, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1430.png", replace
count if occ == 1430

*Marine engineers and naval architects
eventdd Dunemp if occ == 1440, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1440.png", replace
count if occ == 1440

eventdd ahrswork1 if occ == 1440, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1440.png", replace
count if occ == 1440

*Materials engineers
eventdd Dunemp if occ == 1450, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1450.png", replace
count if occ == 1450

eventdd ahrswork1 if occ == 1450, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1450.png", replace
count if occ == 1450

*Mechanical engineers
eventdd Dunemp if occ == 1460, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1460.png", replace
count if occ == 1460

eventdd ahrswork1 if occ == 1460, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1460.png", replace
count if occ == 1460

*Mining and geological engineers, including mining safety engineers
eventdd Dunemp if occ == 1500, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1500.png", replace
count if occ == 1500

eventdd ahrswork1 if occ == 1500, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1500.png", replace
count if occ == 1500

*Nuclear engineers
eventdd Dunemp if occ == 1510, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1510.png", replace
count if occ == 1510

eventdd ahrswork1 if occ == 1510, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1510.png", replace
count if occ == 1510

*Petroleum engineers
eventdd Dunemp if occ == 1520, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1520.png", replace
count if occ == 1520

eventdd ahrswork1 if occ == 1520, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1520.png", replace
count if occ == 1520

*Engineers, all other
eventdd Dunemp if occ == 1530, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1530.png", replace
count if occ == 1530

eventdd ahrswork1 if occ == 1530, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1530.png", replace
count if occ == 1530

*Architectural and civil drafters
eventdd Dunemp if occ == 1541, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1541.png", replace
count if occ == 1541

eventdd ahrswork1 if occ == 1541, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1541.png", replace
count if occ == 1541

*Other drafters
eventdd Dunemp if occ == 1545, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1545.png", replace
count if occ == 1545

eventdd ahrswork1 if occ == 1545, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1545.png", replace
count if occ == 1545

*Electrical and electronic engineering technologists and technicians
eventdd Dunemp if occ == 1551, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1551.png", replace
count if occ == 1551

eventdd ahrswork1 if occ == 1551, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1551.png", replace
count if occ == 1551

*Other engineering technologists and technicians, except drafters
eventdd Dunemp if occ == 1555, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1555.png", replace
count if occ == 1555

eventdd ahrswork1 if occ == 1555, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1555.png", replace
count if occ == 1555

*Surveying and mapping technicians
eventdd Dunemp if occ == 1560, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1560.png", replace
count if occ == 1560

eventdd ahrswork1 if occ == 1560, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1560.png", replace
count if occ == 1560

*Life, Physical, and Social Science Occupations, ALL:
eventdd Dunemp if occ >= 1600 & occ <= 1980, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1600_1980.png", replace
count if occ >= 1600 & occ <= 1980

eventdd ahrswork1 if occ >= 1600 & occ <= 1980, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1600_1980.png", replace
count if occ >= 1600 & occ <= 1980

*Agricultural and food scientists
eventdd Dunemp if occ == 1600, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1600.png", replace
count if occ == 1600

eventdd ahrswork1 if occ == 1600, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1600.png", replace
count if occ == 1600

*Biological scientists
eventdd Dunemp if occ == 1610, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1610.png", replace
count if occ == 1610

eventdd ahrswork1 if occ == 1610, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1610.png", replace
count if occ == 1610

*Conservation scientists and foresters
eventdd Dunemp if occ == 1640, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1640.png", replace
count if occ == 1640

eventdd ahrswork1 if occ == 1640, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1640.png", replace
count if occ == 1640

*Medical scientists
eventdd Dunemp if occ == 1650, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1650.png", replace
count if occ == 1650

eventdd ahrswork1 if occ == 1650, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1650.png", replace
count if occ == 1650

*Life scientists, all other
eventdd Dunemp if occ == 1660, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1660.png", replace
count if occ == 1660

eventdd ahrswork1 if occ == 1660, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1660.png", replace
count if occ == 1660

*Astronomers and physicists
eventdd Dunemp if occ == 1700, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1700.png", replace
count if occ == 1700

eventdd ahrswork1 if occ == 1700, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1700.png", replace
count if occ == 1700

*Atmospheric and space scientists
eventdd Dunemp if occ == 1710, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1710.png", replace
count if occ == 1710

eventdd ahrswork1 if occ == 1710, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1710.png", replace
count if occ == 1710

*Chemists and materials scientists
eventdd Dunemp if occ == 1720, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1720.png", replace
count if occ == 1720

eventdd ahrswork1 if occ == 1720, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1720.png", replace
count if occ == 1720

*Environmental scientists and specialists, including health
eventdd Dunemp if occ == 1745, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1745.png", replace
count if occ == 1745

eventdd ahrswork1 if occ == 1745, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1745.png", replace
count if occ == 1745

*Geoscientists and hydrologists, except geographers
eventdd Dunemp if occ == 1750, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1750.png", replace
count if occ == 1750

eventdd ahrswork1 if occ == 1750, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1750.png", replace
count if occ == 1750

*Physical scientists, all other
eventdd Dunemp if occ == 1760, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1760.png", replace
count if occ == 1760

eventdd ahrswork1 if occ == 1760, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1760.png", replace
count if occ == 1760

*Economists
eventdd Dunemp if occ == 1800, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1800.png", replace
count if occ == 1800

eventdd ahrswork1 if occ == 1800, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1800.png", replace
count if occ == 1800

*Survey researchers
eventdd Dunemp if occ == 1815, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1815.png", replace
count if occ == 1815

eventdd ahrswork1 if occ == 1815, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1815.png", replace
count if occ == 1815

*Clinical and counseling psychologists
eventdd Dunemp if occ == 1821, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1821.png", replace
count if occ == 1821

eventdd ahrswork1 if occ == 1821, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1821.png", replace
count if occ == 1821

*School psychologists
eventdd Dunemp if occ == 1822, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1822.png", replace
count if occ == 1822

eventdd ahrswork1 if occ == 1822, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1822.png", replace
count if occ == 1822

*Other psychologists
eventdd Dunemp if occ == 1825, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1825.png", replace
count if occ == 1825

eventdd ahrswork1 if occ == 1825, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1825.png", replace
count if occ == 1825

*Sociologists
eventdd Dunemp if occ == 1830, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1830.png", replace
count if occ == 1830

eventdd ahrswork1 if occ == 1830, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1830.png", replace
count if occ == 1830

*Urban and regional planners
eventdd Dunemp if occ == 1840, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1840.png", replace
count if occ == 1840

eventdd ahrswork1 if occ == 1840, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1840.png", replace
count if occ == 1840

*Miscellaneous social scientists and related workers
eventdd Dunemp if occ == 1860, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1860.png", replace
count if occ == 1860

eventdd ahrswork1 if occ == 1860, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1860.png", replace
count if occ == 1860

*Agricultural and food science technicians
eventdd Dunemp if occ == 1900, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1900.png", replace
count if occ == 1900

eventdd ahrswork1 if occ == 1900, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1900.png", replace
count if occ == 1900

*Biological technicians
eventdd Dunemp if occ == 1910, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1910.png", replace
count if occ == 1910

eventdd ahrswork1 if occ == 1910, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1910.png", replace
count if occ == 1910

*Chemical technicians
eventdd Dunemp if occ == 1920, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1920.png", replace
count if occ == 1920

eventdd ahrswork1 if occ == 1920, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1920.png", replace
count if occ == 1920

*Environmental science and geoscience technicians
eventdd Dunemp if occ == 1935, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1935.png", replace
count if occ == 1935

eventdd ahrswork1 if occ == 1935, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1935.png", replace
count if occ == 1935

*Nuclear technicians
eventdd Dunemp if occ == 1940, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1940.png", replace
count if occ == 1940

eventdd ahrswork1 if occ == 1940, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1940.png", replace
count if occ == 1940

*Social science research assistants
eventdd Dunemp if occ == 1950, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1950.png", replace
count if occ == 1950

eventdd ahrswork1 if occ == 1950, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1950.png", replace
count if occ == 1950

*Other life, physical, and social science technicians
eventdd Dunemp if occ == 1970, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1970.png", replace
count if occ == 1970

eventdd ahrswork1 if occ == 1970, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1970.png", replace
count if occ == 1970

*Occupational health and safety specialists and technicians
eventdd Dunemp if occ == 1980, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_1980.png", replace
count if occ == 1980

eventdd ahrswork1 if occ == 1980, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_1980.png", replace
count if occ == 1980

*Travel agents
eventdd Dunemp if occ == 4830, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Unemployed") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_UNEN_4830.png", replace
count if occ == 4830

eventdd ahrswork1 if occ == 4830, hdfe absorb(i.occ i.year) timevar(ntime) ci(rcap) lags(25) leads(25) inrange graph_op(ytitle("Hours Worked") xtitle("Month since ChatGPT (Dec. 2022=0)") xscale(range(-25 25)) xlabel(-25(5)25, nogextend))
graph export "$export_root/Event_Studies/Computer_Engineering_Science/ES_HRS_WRK_4830.png", replace
count if occ == 4830
