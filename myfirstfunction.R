library(readr)
library(dplyr)
library(labelled)
library(haven)
library(tidyr)
library(spatstat)
library(ggplot2)
library(openxlsx)
library(flextable)

#1 - import data and if it is SPSS convert values to labels - need to check later about how to use geocodes
data <- read_sav("NGREFSAFebruary2020_external.sav")
data <- to_factor(data)
  
#2 - mutate to rename direct evidence variables - allow variables to be blank 
data <- data %>% mutate(HDDScore = HDDS12, #Household Dietary Diversity Score
                        FCSCat = FCG.21.35, #Food Consumption Groups from the Food Consumption Score 21/35 - normal threshold
                        HHScore = HHSscore, #Household Hunger Score
                        rCSIScore = rCSI, #reduced coping strategies
                        LhHCSCat = Max_coping_behaviour) #livelihood coping strategies 
#mutate to rename technical variables - allow ADM2 and weight variables to be blank
data <- data %>% mutate(ADMIN1Name = state,
                        ADMIN2Name = cod_domain,
                        hh_weight = domainwgt)


#3 rename values of food security indicators (there are english and french versions)  or convert in CH values

data <- data %>%  mutate(CH_HDDS = case_when(
    HDDScore >= 5 ~ "Phase1", 
    HDDScore == 4 ~ "Phase2",       
    HDDScore == 3 ~ "Phase3",
    HDDScore == 2 ~ "Phase4",
    HDDScore < 2 ~ "Phase5"))
data <- data %>% mutate(CH_HHS =  case_when(
    HHScore == 0 ~ "Phase1",
    HHScore == 1 ~ "Phase2",
    HHScore == 2 | HHScore == 3 ~ "Phase3",
    HHScore == 4 ~ "Phase4",  
    HHScore >= 5 ~ "Phase5"))
data <- data %>% mutate(CH_rCSI = case_when(
  rCSIScore <= 3 ~ "Phase1", 
  rCSIScore >= 4 & rCSIScore <= 18 ~ "Phase2",       
  rCSIScore >= 19 ~ "Phase3"))
data <- data %>%  mutate(FCSCat = case_when(
  FCSCat == "Poor" ~ "Poor", 
  FCSCat == "Bordeline" ~ "Borderline",       
  FCSCat == "Acceptable" ~ "Acceptable"))
data <- data %>% mutate(LhHCSCat = case_when(
  LhHCSCat ==  "HH not adopting coping strategies" ~ "NoStrategies", 
  LhHCSCat == "Stress coping strategies" ~ "StressStrategies",
  LhHCSCat == "crisis coping strategies" ~ "CrisisStrategies",
  LhHCSCat == "emergencies coping strategies" ~ "EmergencyStrategies"))


#4 create tables of % of each indicator by adm1 and(if availible) adm2 - input the name of the variables
# and the table of % to calculate phase for every area
#rCSI
CH_rCSI_table_wide <- data %>% group_by(ADMIN1Name, ADMIN2Name) %>%
  drop_na(CH_rCSI) %>%
  count(CH_rCSI, wt = hh_weight) %>%
   mutate(perc = 100 * n / sum(n)) %>%
  ungroup() %>% select(-n) %>%
  spread(key = CH_rCSI, value = perc) %>% replace(., is.na(.), 0)  %>% mutate_if(is.numeric, round, 1) %>%
  mutate(rcsi23 = Phase2 + Phase3,
         rCSI_finalphase =
           case_when(
             Phase3 >= 20 ~ 3, 
             Phase2 >= 20 | rcsi23 >= 20 ~ 2,
             TRUE ~ 1)) %>% select(ADMIN1Name, ADMIN2Name, rCSI_Phase1 = Phase1, rCSI_Phase2 = Phase2, rCSI_Phase3 = Phase3, rCSI_finalphase)
                                                                                        
#Household Hunger Score
CH_HHS_table_wide <- data %>% group_by(ADMIN1Name, ADMIN2Name) %>%
  drop_na(CH_HHS) %>%
  count(CH_HHS, wt = hh_weight) %>%
  mutate(perc = 100 * n / sum(n)) %>%
  ungroup() %>% select(-n) %>%
  spread(key = CH_HHS, value = perc) %>% replace(., is.na(.), 0)  %>% mutate_if(is.numeric, round, 1) %>%
   mutate(phase2345 = `Phase2` + `Phase3` + `Phase4` + `Phase5`,
                                   phase345 = `Phase3` + `Phase4` + `Phase5`,
                                   phase45 = `Phase4` + `Phase5`,
                                   HHS_finalphase = case_when(
                                     Phase5 >= 20 ~ 5,
                                     Phase4 >= 20 | phase45 >= 20 ~ 4,
                                     Phase3 >= 20 | phase345 >= 20 ~ 3,
                                     Phase2 >= 20 | phase2345 >= 20 ~ 2,
                                     TRUE ~ 1)) %>% 
  select(ADMIN1Name, ADMIN2Name, HHS_Phase1 = Phase1, HHS_Phase2 = Phase2, HHS_Phase3 = Phase3, HHS_Phase4 = Phase4, HHS_Phase5 = Phase5, HHS_finalphase)
                          

#Food Consumption Groups
FCSCat_table_wide <- data %>% 
  drop_na(FCSCat) %>%
  group_by(ADMIN1Name, ADMIN2Name) %>%
  count(FCSCat,  wt = hh_weight) %>%
  mutate(perc = 100 * n / sum(n)) %>%
  ungroup() %>% select(-n) %>%
  spread(key = FCSCat, value = perc) %>% replace(., is.na(.), 0) %>% mutate_if(is.numeric, round, 1) %>%
#Apply the Cadre Harmonise rules for phasing the Food Consumption Groups 
  mutate(PoorBorderline = Poor + Borderline, FCG_finalphase = case_when(
  Poor < 5 ~ 1,  #if less than 5% are in the poor food group then phase 1
  Poor >= 20 ~ 4, #if 20% or more are in the poor food group then phase 4
  between(Poor,5,10) ~ 2, #if % of people are between 5 and 10%  then phase2
  between(Poor,10,20) & PoorBorderline < 30 ~ 2, #if % of people in poor food group are between 20 and 20% and the % of people who are in poor and borderline is less than 30 % then phase2
  between(Poor,10,20) & PoorBorderline >= 30 ~ 3)) %>% #if % of people in poor food group are between 20 and 20% and the % of people who are in poor and borderline is less than 30 % then phase2
  select(ADMIN1Name, ADMIN2Name, FCG_Poor = Poor, FCG_Borderline = Borderline, FCG_Acceptable = Acceptable, FCG_finalphase) #select only relevant variables and order in proper sequence


#Household Dietarty Diversity Score
CH_HDDS_table_wide  <- data %>% 
  drop_na(CH_HDDS) %>%
  group_by(ADMIN1Name, ADMIN2Name) %>%
  count(CH_HDDS, wt = hh_weight) %>%
    mutate(perc = 100 * n / sum(n)) %>%
  ungroup() %>% select(-n) %>%
  spread(key = CH_HDDS, value = perc) %>% replace(., is.na(.), 0) %>% mutate_if(is.numeric, round, 1) %>%
#Apply the 20% rule (if it is 20% in that phase or the sum of higher phases equals 20%) 
    mutate(
    phase2345 = `Phase2` + `Phase3` + `Phase4` + `Phase5`, #this variable will be used to see if phase 2 and higher phases equals 20                                 phase345 = `Phase3` + `Phase4` + `Phase5`, #this variable will be used to see if phase 3 and higher phases equal 20% or more
    phase345 = `Phase3` + `Phase4` + `Phase5`,
    phase45 = `Phase4` + `Phase5`, #this variable will be used to see if phase 3 and higher phases equal 20% or more
    HDDS_finalphase = case_when(
    `Phase5` >= 20 ~ 5, #if 20% or more is in phase 5 then assign phase 5
    `Phase4` >= 20 | phase45 >= 20 ~ 4, #if 20% or more is in phase 4 or the sum of phase4 and 5 is more than 20% then assign phase 4
    `Phase3` >= 20 | phase345 >= 20 ~ 3, #if 20% or more is in phase 3 or the sum of phase3, 4 and 5 is more than 20% then assign phase 3
    `Phase2` >= 20 | phase2345 >= 20 ~ 2, #if 20% or more is in phase 2 or the sum of phase 2, 3, 4 and 5 is more than 20% then assign phase 2
     TRUE ~ 1)) %>% #otherwise assign phase 1
  select(ADMIN1Name, ADMIN2Name, HDDS_Phase1 = Phase1, HDDS_Phase2 = Phase2, HDDS_Phase3 = Phase3, HDDS_Phase4 = Phase4, HDDS_Phase5 = Phase5, HDDS_finalphase) #select only relevant variables, rename them with indicator name and order in proper sequence


#Livelihood Coping Strategies 
LhHCSCat_table_wide <- data %>% 
  drop_na(LhHCSCat) %>%
  group_by(ADMIN1Name, ADMIN2Name) %>%
  count(LhHCSCat, wt = hh_weight) %>%
  mutate(perc = 100 * n / sum(n)) %>%
  ungroup() %>% select(-n) %>%
  spread(key = LhHCSCat, value = perc) %>% replace(., is.na(.), 0) %>% mutate_if(is.numeric, round, 1) %>%
#Apply the Cadre Harmonise rules for phasing the Livelihood Coping Strategies 
 mutate(stresscrisisemergency = StressStrategies + CrisisStrategies + EmergencyStrategies,
    crisisemergency = CrisisStrategies + EmergencyStrategies,
    LhHCSCat_finalphase = case_when(
    EmergencyStrategies >= 20 ~ 4,
    crisisemergency >= 20 & EmergencyStrategies < 20 ~ 3,  
    NoStrategies < 80 & crisisemergency < 20 ~ 2,
    NoStrategies >= 80 ~ 1)) %>% 
    select(ADMIN1Name, ADMIN2Name, LhHCSCat_NoStrategies = NoStrategies, LhHCSCat_StressStrategies = StressStrategies, LhHCSCat_CrisisStategies = CrisisStrategies, LhHCSCat_EmergencyStrategies = EmergencyStrategies, LhHCSCat_finalphase)



##Add contributing factors variables (different from the Food Security direct evidence above, these variables will depend country to country)
##so that the contributing factors can be imported into the proper category, the final variable names should be given a prefix (e.g. 01_, 02_ + the variable name + the outcome (i.e. yes, no))
##"Hazards & Vulnerability" = 01 - 10
##"Availability" = 11 - 25
##"Accessibility" = 26 - 40
##"Utilization including access to clean water" = 41 - 55
##"Stability" = 56 - 70
##make option to select if which category (from above) variable whether it is count/mean/median functions
##also - need to rename variable names because often they are meaningless - i.e. q8.15
#also - mean and median variables should be named - "category number , varaible name, mean or median"

#percentage example for hazards
cf_table01 <- data %>% group_by(ADMIN1Name, ADMIN2Name) %>%
  drop_na(yn_chocks) %>%
  count(yn_chocks, wt = hh_weight) %>%
  mutate(perc = 100 * n / sum(n)) %>%
  ungroup() %>% select(-n) %>%
  spread(key = yn_chocks, value = perc) %>% replace(., is.na(.), 0)  %>% mutate_if(is.numeric, round, 1) %>% 
  select(ADMIN1Name, ADMIN2Name, `01_yn_chocks_Yes` = Yes, `01_yn_chocks_No` = No)

#paste0(01, "_",input$columnname, "_", unique(yn_chocks)[1])=unique(yn_chocks)[1]

#another percentage example for hazards - 	Are there any conflicts between pastoralist and farmers in your community?
cf_table02 <- data %>% group_by(ADMIN1Name, ADMIN2Name) %>%
  drop_na(q8.15, wt = hh_weight) %>%
  count(q8.15) %>%
  mutate(perc = 100 * n / sum(n)) %>%
  ungroup() %>% select(-n) %>%
  spread(key = q8.15, value = perc) %>% replace(., is.na(.), 0)  %>% mutate_if(is.numeric, round, 1) %>% 
  select(ADMIN1Name, ADMIN2Name, `02_q8.15_Yes` = Yes, `01_q8.15_No` = No)

#same as table above put using pivot_wider instead of spread
cf_table02_1 <- data %>% group_by(ADMIN1Name, ADMIN2Name) %>%
  drop_na(q8.15) %>%
  count(q8.15, wt = hh_weight) %>%
  mutate(perc = 100 * n / sum(n)) %>%
  ungroup() %>% select(-n) %>%
  pivot_wider(names_from = q8.15,
              values_from = perc,
              values_fill = list(n = 0)) %>%
  mutate_if(is.numeric, round, 1) %>% 
  select(ADMIN1Name, ADMIN2Name, `02_q8.15_Yes` = Yes, `01_q8.15_No` = No)

#another way - with survey design and questionnaire - gets the same results but not that helpful
library(survey)
library(questionr)

svy <- svydesign(ids = ~1, weights = ~ hh_weight, data = data)

cf_table02_2 <- svytable(~ADMIN2Name +q8.15 , design = svy)
rprop(cf_table02_2)




#another percentage example for availability - 	Did your household practice DRY SEASON/ IRRIGATION FARMING [2019/2020]?
cf_table11 <- data %>% group_by(ADMIN1Name, ADMIN2Name) %>%
  drop_na(q8.9) %>%
  count(q8.9, wt = hh_weight) %>%
  mutate(perc = 100 * n / sum(n)) %>%
  ungroup() %>% select(-n) %>%
  spread(key = q8.9, value = perc) %>% replace(., is.na(.), 0)  %>% mutate_if(is.numeric, round, 1) %>% 
  select(ADMIN1Name, ADMIN2Name, `11_q8.9_Yes` = Yes, `01_q8.9_No` = No)
#another percentage example for availability - 	How is the harvest of the ongoing dry season/irrigation farming?
cf_table12 <- data %>% group_by(ADMIN1Name, ADMIN2Name) %>%
  drop_na(q8.9a) %>%
  count(q8.9a, wt = hh_weight) %>%
  mutate(perc = 100 * n / sum(n)) %>% 
  ungroup() %>% select(-n) %>%
  spread(key = q8.9a, value = perc) %>% replace(., is.na(.), 0)  %>% mutate_if(is.numeric, round, 1) %>% 
  select(ADMIN1Name, ADMIN2Name, `12_q8.9a_Good` = Good, `12_q8.9a_Fair` = Fair, `12_q8.9a_Bad` = Bad)

#median example for stability - HH food expenditure over month
cf_table56 <- data %>% group_by(ADMIN1Name, ADMIN2Name) %>% drop_na(food_monthly) %>%
  summarise(`56_food_monthly_median` = weighted.median(food_monthly, hh_weight)) %>%
replace(., is.na(.), 0)  %>% mutate_if(is.numeric, round, 1) %>% 
  ungroup()

#mean example for stability - HH food expenditure over month
cf_table57 <- data %>% group_by(ADMIN1Name, ADMIN2Name) %>% drop_na(food_monthly) %>%
  summarise(`57_food_monthly_mean` = weighted.mean(food_monthly, hh_weight)) %>%
  replace(., is.na(.), 0)  %>% mutate_if(is.numeric, round, 1) %>% 
  ungroup()


#7.  compile all the direct evidence and contributing factors and export the matrice intermediare excel sheet
### Merge key variables from Direct Evidence and Contributing factor tables together - problem is that some factors contributif have missing values
#should this be a join?  is ordering the same for every table?
matrice_intermediaire_direct <- bind_cols(
  FCSCat_table_wide,
  select(CH_HDDS_table_wide,-c("ADMIN1Name","ADMIN2Name")),
  select(CH_HHS_table_wide,-c("ADMIN1Name","ADMIN2Name")),
  select(LhHCSCat_table_wide,-c("ADMIN1Name","ADMIN2Name")),
  select(CH_rCSI_table_wide,-c("ADMIN1Name","ADMIN2Name")))

matrice_intermediaire <- bind_cols(matrice_intermediaire_direct, 
#add contributing factors (in order)
  select(cf_table01,-c("ADMIN1Name","ADMIN2Name")),
  select(cf_table02,-c("ADMIN1Name","ADMIN2Name")),
  select(cf_table11,-c("ADMIN1Name","ADMIN2Name")),
  select(cf_table56,-c("ADMIN1Name","ADMIN2Name")))

#add the one contributing factor that has doesnt have the same number of rows()
matrice_intermediaire <- full_join(matrice_intermediaire,cf_table12,by=c("ADMIN1Name","ADMIN2Name")) 


#8  compile all the direct evidence and contributing factors (and list of other variables) and export the matrice intermediare excel sheet
#add in other columns that will be filled in manually in excel sheet
matrice_intermediaire <- matrice_intermediaire %>% mutate(Z1_LDP_C=NA,	Z1_LDP_pop_C=NA,	Z1_SD_C=NA,	Z1_Pop_SD_C=NA,	Z1_LDP_Pr=NA,	Z1_Pop_LDP_Pr=NA,	Z1_SD_Pr=NA,	Z1_pop_SD_Pr=NA,	Z2_LDP_C=NA,	Z2_LDP_pop_C=NA,	Z2_SD_C=NA,	Z2_Pop_SD_C=NA,	Z2_LDP_Pr=NA,	Z2_Pop_LDP_Pr=NA,	Z2_SD_Pr=NA,	Z2_pop_SD_Pr=NA,	Z3_LDP_C=NA,	Z3_LDP_pop_C=NA,	Z3_SD_C=NA,	Z3_Pop_SD_C=NA,	Z3_LDP_Pr=NA,	Z3_Pop_LDP_Pr=NA,	Z3_SD_Pr=NA,	Z3_pop_SD_Pr=NA,	Z4_LDP_C=NA,	Z4_LDP_pop_C=NA,	Z4_SD_C=NA,	Z4_Pop_SD_C=NA,	Z4_LDP_Pr=NA,	Z4_Pop_LDP_Pr=NA,	Z4_SD_Pr=NA,	Z4_pop_SD_Pr=NA,	Proxy_cal=NA,	GAM=NA,	IPC_AMN_curt=NA,	GAM_Pharv=NA,	GAM_Lean=NA,	IPC_AMN_prjt=NA,	BMI=NA,	MUAC=NA,	CMR=NA,	U5DR=NA)
#formats color of columns
direct <- createStyle(fgFill = "#4F81BD", halign = "left", textDecoration = "Bold",
                      border = "Bottom", fontColour = "white")
contributifs <- createStyle(fgFill = "#FFC7CE", halign = "left", textDecoration = "Bold",
                            border = "Bottom", fontColour = "black")
hea <- createStyle(fgFill = "#C6EFCE", halign = "left", textDecoration = "Bold",
                   border = "Bottom", fontColour = "black")
nutrition <- createStyle(fgFill = "yellow", halign = "left", textDecoration = "Bold",
                         border = "Bottom", fontColour = "black")
mortalite <- createStyle(fgFill = "orange", halign = "left", textDecoration = "Bold",
                         border = "Bottom", fontColour = "black")
proxyvar <- createStyle(fgFill = "lightgreen", halign = "left", textDecoration = "Bold",
                        border = "Bottom", fontColour = "black")
#
Matrice_intermediaire <- createWorkbook()
addWorksheet(Matrice_intermediaire, "Matrice intermediaire")

col1stDirectVariable <- which(colnames(matrice_intermediaire)=="FCG_Poor")
colLastDirectVariable <- which(colnames(matrice_intermediaire)=="rCSI_finalphase")
col1stHEAVariable <- which(colnames(matrice_intermediaire)=="Z1_LDP_C")
colLastHEAVarible <- which(colnames(matrice_intermediaire)=="Z4_pop_SD_Pr")
colLastproxycal <- which(colnames(matrice_intermediaire)=="Proxy_cal")
col1stNutritionVariable <- which(colnames(matrice_intermediaire)=="GAM")
colLastNutritionVariable <- which(colnames(matrice_intermediaire)=="MUAC")
col1stMortalityVariable <- which(colnames(matrice_intermediaire)=="CMR")
colLastMortalityVariable <- which(colnames(matrice_intermediaire)=="U5DR")


Matrice_intermediaire <- createWorkbook()
addWorksheet(Matrice_intermediaire, "Matrice intermediaire")
writeData(Matrice_intermediaire,sheet = 1,matrice_intermediaire,startRow = 1,startCol = 1,)
addStyle(Matrice_intermediaire,1,rows = 1,cols = col1stDirectVariable:colLastDirectVariable
         ,style = direct,gridExpand = TRUE,)
addStyle(Matrice_intermediaire,1,rows = 1,cols =(colLastDirectVariable+1) :(col1stHEAVariable-1),
         style = contributifs,gridExpand = TRUE,)
addStyle(Matrice_intermediaire,1,rows = 1,cols =col1stHEAVariable :colLastHEAVarible,
         style = hea,gridExpand = TRUE,)
addStyle(Matrice_intermediaire,1,rows = 1,cols =col1stNutritionVariable :colLastNutritionVariable,
         style = nutrition,gridExpand = TRUE,)
addStyle(Matrice_intermediaire,1,rows = 1,cols =col1stNutritionVariable-1 ,
         style = proxyvar,gridExpand = TRUE,)
addStyle(Matrice_intermediaire,1,rows = 1,cols = col1stMortalityVariable:colLastMortalityVariable,
         style = mortalite,gridExpand = TRUE,)

saveWorkbook(Matrice_intermediaire,file ="Matrice_intermediaire.xlsx",overwrite = TRUE)
openXL(Matrice_intermediaire)


#9join in table of adm1/adm2codes and population information (need to think of how to do this)

#10 convert wide tables to long tables for direct evidence and then create bar graphs by phase, tables, and maps in Rmarkdown document
directevidence_table_long <- matrice_intermediaire_direct %>% pivot_longer(!c("ADMIN1Name","ADMIN2Name"), names_to = "variable", values_to = "values")
#make graph of indicators 
rcsi_ch_graph <- directevidence_table_long %>% filter(variable %in% c("rCSI_Phase1","rCSI_Phase2","rCSI_Phase3")) %>% ggplot(aes(fill=variable, y=values, x=ADMIN2Name)) +geom_bar(position="fill", stat="identity") +scale_fill_manual(values=c("#c6ffc7","#ffe718","#e88400")) +theme_minimal() +theme(axis.text.x = element_text(angle = 90)) +scale_y_continuous(labels = scales::percent)+ theme(axis.title.x = element_blank(), axis.title.y = element_blank()) +facet_grid(. ~ ADMIN1Name, scales = "free")




