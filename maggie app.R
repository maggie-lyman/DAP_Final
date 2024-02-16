library(tidyverse)
library(readr)
library(shiny)
library(sf)
library(spData)
library(shinyFeedback)
library(snakecase)
library(plotly)


## Functions
rename_columns <- function(df){ 
  snake <- to_snake_case(names(df))
  names <- noquote(snake, right = FALSE)
  setNames(df, names)
}

make_coord <- function(df){
  st_as_sf(x = df,
           coords = c("longitude", "latitude"),
           crs = 4326)
}

path <- "C:/Users/mlyma/OneDrive/Documents/GitHub/DAP_Final/"
adu_apps <- read_csv(paste0(path, "Additional_Dwelling_Unit_Preapproval_Applications_20240207.csv"))
# Unzip shape file tracts
zipF <- paste0(path, "Boundaries - Census Tracts - 2010.zip")
unzip(zipF,exdir=path)
# Read in shape file
chicago_tracts <- st_read(
  file.path(path, "geo_export_6356fb24-e715-483f-922e-9fd4badc2b8c.shp")
)
# Change CRS of shapefiles
chicago_tracts <- st_transform(chicago_tracts, 
                               crs = 4326)
# Unzip shape file neighborhoods
ZipF2 <- paste0(path, "Boundaries - Neighborhoods.zip")
unzip(ZipF2, exdir = path)
# Read in shape file
chicago_neighborhoods <- st_read(
  file.path(path, "geo_export_ab2c9a8a-dc67-4ec7-a969-bb86c9c5c6bd.shp")
)
# Change CRS of shapefile
chicago_neighborhoods <- st_transform(chicago_neighborhoods, 
                                      crs = 4326)
# Upload CSV
adus <- read_csv(paste0(path, "Additional_Dwelling_Unit_Preapproval_Applications_20240216.csv"))

# Clean CSV
adu_clean <- rename_columns(adus)
adu_clean <- make_coord(adu_clean)
# Merge Files
adu_tract <- st_join(chicago_tracts, adu_clean)
adu_tract_hood <- st_join(chicago_neighborhoods, adu_tract)

