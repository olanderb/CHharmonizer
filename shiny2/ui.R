## UI page

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

#add a tooltip for instructions
formattip<-tags$span("Column to Format: ", title="Organize your choices by hazard type.  These columns should be hazards, these are about clean water, so and so and so are about stability.")

navbarPage("Cadre Data Harmonizer", 
           
           tabPanel("Import & View Data",
                    bootstrapPage(useShinyjs(), #don't know if we need to use this line, but bootstrap makes for a more flexible UI, so we can keep for later
                                  sidebarLayout(
                                    sidebarPanel(
                                      fileInput(inputId = "file", label = "Select file", multiple = FALSE, accept='.sav'),
                                    helpText(HTML("Import your SPSS data and browse the variables"))
                                    ),
                                    mainPanel(
                                     
                                      DT::dataTableOutput('table'),
                                      #DT::dataTableOutput("table2")
                                    )
                                  )
                    )
           ),
           tabPanel("Rename Key Food Security & Technical Variables",
           bootstrapPage(useShinyjs(), #don't know if we need to use this line, but bootstrap makes for a more flexible UI, so we can keep for later
                         sidebarLayout(
                           sidebarPanel(
                             helpText(HTML("To standardize the variable names of the Direct Food Security Evidence, in the fields below, select the name of the variable in the dataset which corresponds with the instructions")),
                             
                             selectInput("choosename", "Select Name of Food Consumption Score (FCS) Variable", choices="", selected="", multiple = FALSE), 
                             div(style='display:inline-block',textInput("newname",value = "FCScat", label=NULL, width="160px")),
                             div(style='display:inline-block',actionButton('renamecolumn', 'Rename', style='padding:4px; font-size:80%;')),
                             
                             helpText(HTML("Here we need a table to show the values for FCSCat and a way to make sure that they are Poor,Borderline,Acceptable")),
                             
                             
                             selectInput("choosename2", "Select Name of reduced Coping Strategy Index (rCSI) Variable", choices="", selected="", multiple = FALSE), 
                             div(style='display:inline-block',textInput("newname2",value = "rCSIScore", label=NULL, width="160px")),
                             div(style='display:inline-block',actionButton('renamecolumn2', 'Rename', style='padding:4px; font-size:80%;')),
                             
                             selectInput("choosename3", "Select Name of Household Dietary Diversity Score (HDDS) Variable", choices="", selected="", multiple = FALSE), 
                             div(style='display:inline-block',textInput("newname3",value = "HDDScore", label=NULL, width="160px")),
                             div(style='display:inline-block',actionButton('renamecolumn3', 'Rename', style='padding:4px; font-size:80%;')),
                             
                             selectInput("choosename4", "Select Name of Household Hunger Scale (HHS) Variable", choices="", selected="", multiple = FALSE), 
                             div(style='display:inline-block',textInput("newname4",value = "HHScore", label=NULL, width="160px")),
                             div(style='display:inline-block',actionButton('renamecolumn4', 'Rename', style='padding:4px; font-size:80%;')),
                             
                             selectInput("choosename5", "Select Name of Livelihood Coping Stategy (LHCS) Variable", choices="", selected="", multiple = FALSE), 
                             div(style='display:inline-block',textInput("newname5",value = "LhHCSCat", label=NULL, width="160px")),
                             div(style='display:inline-block',actionButton('renamecolumn5', 'Rename', style='padding:4px; font-size:80%;')),
                             
                             helpText(HTML("Here we need a table to show the values for LhHCSCat and a way to make sure that they are NoStrategies,StressStrategies,CrisisStrategies,EmergencyStrategies")),
                             
                             helpText(HTML("To standardize the variable names of the geographic and weight variables, rename them in the fields below")),
                             
                             selectInput("choosename6", "Select Name of First Administrative Division", choices="", selected="", multiple = FALSE), 
                             div(style='display:inline-block',textInput("newname6",value = "ADMIN1Name", label=NULL, width="160px")),
                             div(style='display:inline-block',actionButton('renamecolumn6', 'Rename', style='padding:4px; font-size:80%;')),
                             
                             selectInput("choosename7", "Select Name of Second Administrative Division (if applicaple)", choices="", selected="", multiple = FALSE), 
                             div(style='display:inline-block',textInput("newname7",value = "ADMIN2Name", label=NULL, width="160px")),
                             div(style='display:inline-block',actionButton('renamecolumn7', 'Rename', style='padding:4px; font-size:80%;')),
                             
                             selectInput("choosename8", "Select Name of household weights (if applicaple)", choices="", selected="", multiple = FALSE), 
                             div(style='display:inline-block',textInput("newname8",value = "hh_weight", label=NULL, width="160px")),
                             div(style='display:inline-block',actionButton('renamecolumn8', 'Rename', style='padding:4px; font-size:80%;')),
                             
                             
                             HTML('</br><hr style="color: black;">'),
                           helpText(HTML("Here can be some instructions"))
                           ),
                           mainPanel(
                             
                             DT::dataTableOutput('table1'),
                             #DT::dataTableOutput("table2")
                           )
                         )
           )
           ),

tabPanel("Generate Contributing Factor variables",
         HTML("<h1>Placeholder for other stuff</h1>"), 
         DT::dataTableOutput("table2")
), 

tabPanel("Figures/Maps", 
         HTML("<h3>Anything you want to say here....</h3>"), 
         leafletOutput("map1"))

)