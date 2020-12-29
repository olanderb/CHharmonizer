
library(readr)
library(dplyr)
library(labelled)
library(haven)
library(tidyr)
library(spatstat)
library(ggplot2)



function(input, output, session){


cf_table1 <- data %>% group_by(ADMIN1Name, ADMIN2Name) %>%
  count(yn_chocks, wt = hh_weight) %>%
  drop_na() %>%
  mutate(perc = 100 * n / sum(n)) %>%
  ungroup() %>% select(-n) %>%
  spread(key = yn_chocks, value = perc) %>% replace(., is.na(.), 0)  %>% mutate_if(is.numeric, round, 1) %>%
  select(ADMIN1Name, ADMIN2Name, `01_yn_chocks_yes` = Yes, `01_yn_chocks_No` = No)



updateSelectInput(session=session, "inputname", choices=unique(as.character(cf_table1$ADMIN1Name)), selected="")



filteredtab<-reactive({
  cf_table1 <- data %>% group_by(ADMIN1Name, ADMIN2Name) %>%
    count(yn_chocks, wt = hh_weight) %>%
    drop_na() %>%
    mutate(perc = 100 * n / sum(n)) %>%
    ungroup() %>% select(-n) %>%
    spread(key = yn_chocks, value = perc) %>% replace(., is.na(.), 0)  %>% mutate_if(is.numeric, round, 1) %>%
    select(ADMIN1Name, ADMIN2Name, `01_yn_chocks_yes` = Yes, `01_yn_chocks_No` = No)
  
  cf_table1
  
  
})



output$table<-renderTable({
  
  cf_table1<-filteredtab()
  
  if(input$inputname==""){
  cf_table1
  }else{
    cf_table1[cf_table1$ADMIN1Name==input$inputname,]
  }
  
})









}