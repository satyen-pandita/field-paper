import delimited  "C:\Users\shrey\OneDrive - UW-Madison\UW\field-paper\proc\TimeReg.csv", clear

gen propTime_home_m = time_spent_m_home/(time_spent_m_leisure + time_spent_m_home + time_spent_m_self)
gen propTime_home_w = time_spent_w_home/(time_spent_w_leisure + time_spent_w_home + time_spent_w_self)
gen ratio_propTime = propTime_home_m/propTime_home_w
gen ratio_hpTime = time_spent_m_home/time_spent_w_home

gen ln_cons = log(cons_exp_total_monthly+0.01)

gen adivasi = 0 
replace adivasi = 1 if socialgroup == 1

// reg ratio_propTime adivasi ln_cons, r

areg ratio_hpTime adivasi ln_cons i.religion i.land_possessed_survey_date_code member_5plus_needing_care_no_car , r absorb(district)

areg ratio_propTime adivasi ln_cons i.religion i.land_possessed_survey_date_code member_5plus_needing_care_no_car , r absorb(district)

gen propTime_home_m = time_spent_m_home/(time_spent_m_leisure + time_spent_m_home)
gen propTime_home_w = time_spent_w_home/(time_spent_w_leisure + time_spent_w_home)

gen ratio_propTime = propTime_home_m/propTime_home_w

areg ratio_propTime adivasi ln_cons i.religion i.land_possessed_survey_date_code member_5plus_needing_care_no_car , r absorb(district)
