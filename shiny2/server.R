## server file

library(readr)
library(dplyr)
library(labelled)
library(haven)
library(tidyr)
library(spatstat)
library(ggplot2)
library(shiny)
library(shinyWidgets)
library(shinyjs)
library(leaflet)


function(input, output, session){
  
  ##if dataframe to load in is too big for app, uncomment this line to increase maximum file upload size
  options(shiny.maxRequestSize=300*1024^2) 
  
  ##set up reactive values to store the dataframe in (reactiveValues allows to store outside of all functions)
  values<-reactiveValues()
  
  ####bring in the point intercept csv (or data already in proper format), as a reactive values table
  observeEvent(input$file,{
    
    infile<-input$file
    
   data<-read_sav(infile$datapath)
  #data<-as.data.frame(data)
   
   #update the names dropdown
   updateSelectInput("choosename", session=session, choices = names(data), selected="")
   updateSelectInput("choosename2", session=session, choices = names(data), selected="")
   updateSelectInput("choosename3", session=session, choices = names(data), selected="")
   updateSelectInput("choosename4", session=session, choices = names(data), selected="")
   updateSelectInput("choosename5", session=session, choices = names(data), selected="")
   updateSelectInput("choosename6", session=session, choices = names(data), selected="")
   updateSelectInput("choosename7", session=session, choices = names(data), selected="")
   updateSelectInput("choosename8", session=session, choices = names(data), selected="")
   
   ################  
   #1 - import data and if it is SPSS convert values to labels - need to check later about how to use geocodes
   #data <- read_sav("NGREFSAFebruary2020_external.sav")
   data <- to_factor(data)
   
 
   ##################
    ## format the data, then save it to reactive values
    values$data<-data
  })
  
  

  
  #plot table of reactive values (which will dynamically change with the formatting)
  output$table<-DT::renderDataTable({
    if (is.null(input$file))
      return(NULL)

    
    values$data
    
  }, options=list(paging=TRUE,pageLength=5, searching=TRUE, scrollX=TRUE), selection="single",rownames=FALSE, escape=FALSE)
  
  
 
  
  
  
############################################################################################################
  
  observeEvent(input$renamecolumn, {
    values$data->df
    names(df)[names(df)==input$choosename]<-input$newname
    values$data<-df
#re-update the names dropdown
  updateSelectInput("choosename", session=session, choices = names(df), selected="")
})
  observeEvent(input$renamecolumn2, {
    values$data->df
    names(df)[names(df)==input$choosename2]<-input$newname2
    values$data<-df
#re-update the names dropdown
    updateSelectInput("choosename2", session=session, choices = names(df), selected="")
  }) 
  observeEvent(input$renamecolumn3, {
    values$data->df
    names(df)[names(df)==input$choosename3]<-input$newname3
    values$data<-df
    #re-update the names dropdown
    updateSelectInput("choosename3", session=session, choices = names(df), selected="")
  })   
  observeEvent(input$renamecolumn4, {
    values$data->df
    names(df)[names(df)==input$choosename4]<-input$newname4
    values$data<-df
    #re-update the names dropdown
    updateSelectInput("choosename4", session=session, choices = names(df), selected="")
  })   
  observeEvent(input$renamecolumn5, {
    values$data->df
    names(df)[names(df)==input$choosename5]<-input$newname5
    values$data<-df
    #re-update the names dropdown
    updateSelectInput("choosename5", session=session, choices = names(df), selected="")
  })  
  observeEvent(input$renamecolumn6, {
    values$data->df
    names(df)[names(df)==input$choosename5]<-input$newname6
    values$data<-df
    #re-update the names dropdown
    updateSelectInput("choosename6", session=session, choices = names(df), selected="")
  })  
  observeEvent(input$renamecolumn7, {
    values$data->df
    names(df)[names(df)==input$choosename7]<-input$newname7
    values$data<-df
    #re-update the names dropdown
    updateSelectInput("choosename7", session=session, choices = names(df), selected="")
  })  
  observeEvent(input$renamecolumn8, {
    values$data->df
    names(df)[names(df)==input$choosename8]<-input$newname8
    values$data<-df
    #re-update the names dropdown
    updateSelectInput("choosename8", session=session, choices = names(df), selected="")
  })  
  #format the data and write to the new reactiveValues table

  
  
  
  

  output$table1<-DT::renderDataTable({
    if (is.null(input$file))
      return(NULL)
    
    
    values$data
    
  }, options=list(paging=TRUE,pageLength=5, searching=TRUE, scrollX=TRUE), selection="single",rownames=FALSE, escape=FALSE)
  
  
  
  
  
  
  observeEvent(input$format,{
    
    values$data->data
    
    
    
    if(input$processingtype=="Count"){
    #percentage example for hazards
    cf_table01 <- data %>% group_by(ADMIN1Name, ADMIN2Name) %>%
      drop_na(yn_chocks) %>%
      count(yn_chocks, wt = hh_weight) %>%
      mutate(perc = 100 * n / sum(n)) %>%
      ungroup() %>% select(-n) %>%
      spread(key = yn_chocks, value = perc) %>% replace(., is.na(.), 0)  %>% mutate_if(is.numeric, round, 1) %>%
      select(ADMIN1Name, ADMIN2Name, `01_yn_chocks_Yes` = Yes, `01_yn_chocks_No` = No)

    #paste0(01, "_",input$columnname, "_", unique(yn_chocks)[1])=unique(yn_chocks)[1]
    }
    
    
    
    if(is.null(values$summarytable)){
    values$summarytable<-cf_table01
    } else {
      values$summarytable<-merge(values$summarytable, cf_table01, by=c('ADMIN1Name', 'ADMIN2Name'), all.x=T) #convert to tidyverse which left outer join function
    }
    
    
  })
  
  
  
  
  

  
  
  ######################################################################################
  #download to csv (or other format)
  
  #specify the output name and what to output
  output$formatteddownload <- downloadHandler(
    filename = "FormattedData.csv",
    content = function(file) {
      
      
      write.csv(values$summarytable, file, row.names=F)
    },
    contentType= "text/csv"
  )
  
  
  
  ########################################################################################################
  ########################################################################################################
  ########################################################################################################
  ########################################################################################################
  ########################################################################################################
  # tab 2 
  
  #plot table of reactive values (which will dynamically change with the formatting)
  
 
  
  
  
  output$table2<-DT::renderDataTable({
    if (is.null(values$summarytable))
      return(NULL)
    
    
    values$summarytable
    
  }, options=list(paging=TRUE,pageLength=10, searching=TRUE, scrollX=TRUE), selection="single",rownames=FALSE, escape=FALSE)
  
  

  
  ########################################################################################################
  ########################################################################################################
  ########################################################################################################
  ########################################################################################################
  ########################################################################################################
  #tab 3
  
  output$map1 <- renderLeaflet({
    
    leaflet() %>% addProviderTiles("Esri.WorldImagery") %>% 
      fitBounds(-83, 24, -79, 31) %>% 
      addLayersControl(
        baseGroups = c("Thing","Off"),
        overlayGroups = c("Stuff"),
        options = layersControlOptions(collapsed = FALSE), position="topleft")  
      

    
    
  })
  
  
  
  
}

