library(readr)
library(dplyr)
library(labelled)
library(haven)
library(tidyr)
library(spatstat)
library(ggplot2)
library(shiny)


navbarPage("My app", 
           
           tabPanel("Tab1", 
                   fluidPage(
                     titlePanel("Top Title"), 
                     sidebarLayout(
                       sidebarPanel(
                         selectInput("inputname", "Name", choices=c("a", "b", "c"), selected="c")),
                       
                       mainPanel(
                         tableOutput("table")
                       )
                     )
                   ) 
                    
                    )
           
           )