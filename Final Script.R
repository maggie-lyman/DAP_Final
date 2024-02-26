## Load packages
library(tidyverse)
library(readr)
library(sf)
library(spData)
library(snakecase)
library(httr)
library(jsonlite)
library(tidycensus)
library(testthat)

## Function
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

## Load data

# Add path
path <- "C:/Users/mlyma/OneDrive/Documents/GitHub/DAP_Final/"
# path <- "/Users/maxwellwagner/Documents/GitHub/DAP_Final/"

# Read in csv file
adus_issued <- read_csv(paste0(path, "Additional_Dwelling_Unit_Preapprovals_Issued_20240130.csv"))
adu_apps <- read_csv(paste0(path, "Additional_Dwelling_Unit_Preapproval_Applications_20240207.csv"))
# Unzip shape file
zipF <- paste0(path, "Boundaries - Census Tracts - 2010.zip")
unzip(zipF,exdir=path)
# Read in shape file
chicago_tracts <- st_read(
  file.path(path, "geo_export_6356fb24-e715-483f-922e-9fd4badc2b8c.shp")
)
# Change CRS of shapefiles
chicago_tracts <- st_transform(chicago_tracts, 
                              crs = 4326)
# Read in API census data
key <- "a58ec96cdf12838255365193b5aa59b943091de3"
census_data <- get_acs(geography = "tract",
        variables = c("B01003_001", "B05010_001", "B19326_001",
                      "B07002_001", "B07013_002", "B25106_002", "B25064_001",
                      "B25070_001"),
        state = "IL",
        year = 2022,
        output = "tidy",
        county = "Cook",
        key = key,
        survey = "acs5")

# For our notes only: I searched through this to find the right census variables
census_variables <- load_variables(2021, "acs5", cache = TRUE)
view(census_variables)

## Data Cleaning
# Rename census variables
census_wide <- census_data |>
  dplyr::select(-moe) |>
  pivot_wider(names_from = variable,
              values_from = estimate)

census_clean <- census_wide |>
  rename(total_pop = B01003_001,
         ratio_income_to_poverty = B05010_001,
         median_income = B19326_001,
         median_age = B07002_001,
         owner_occupied_housing = B07013_002,
         owner_occupied_by_perc_income = B25106_002,
         median_gross_rent = B25064_001,
         gross_rent_perc_income = B25070_001)
# Clean column names
adu_clean <- rename_columns(adus_issued)
adu_app_clean <- rename_columns(adu_apps)
census_clean <- rename_columns(census_clean)

# Add coords to ADU
adu_coord <- make_coord(adu_clean)
adu_app_coord <- make_coord(adu_app_clean)

# Join Data

## Static plot - Chloropleth of where ADUs are located
# Merge shape files with ADU coordinates
Chicago_adus_merged <- st_join(chicago_tracts, adu_coord)
Chicago_adu_app_merged <- st_join(chicago_tracts, adu_app_coord)
# Add a new column with a binary variable indicating whether a row represents an ADU permit issued
Chicago_adus_tract <- Chicago_adus_merged |>
  mutate(ADU_tract = if_else(is.na(id), 0, 1))
# Use application dataset to create binary columns for application status
Chicago_adu_app_tract <- Chicago_adu_app_merged |>
  mutate(ADU_tract = ifelse(is.na(id), 0, 1))
Chicago_adu_app_tract <- Chicago_adu_app_tract |>
  mutate(issued = case_when(status == "Issued" &
                              ADU_tract == 1 ~ 1,
                            is.na(status) ~ NA,
                            TRUE ~ 0),
         denied = case_when(status == "Denied" &
                              ADU_tract == 1 ~ 1,
                            is.na(status) ~ NA,
                            TRUE ~ 0),
         pending = case_when(status %in% c("Notification docs requested",
                                           "Affordability docs requested") &
                               ADU_tract == 1 ~ 1,
                             is.na(status) ~ NA,
                             TRUE ~ 0)) 

# Group data by census tract and find total number of ADUs per census tract
Chicago_adus_tract_counts <- Chicago_adus_tract |>
  group_by(tractce10, .drop = FALSE) |>
  summarize(count = sum(ADU_tract))
# Check to ensure that all ADU permits issued are counted
test_that("All ADU permits are represented in count", 
          expect_equal(sum(Chicago_adus_tract_counts$count), nrow(adus_issued)))
# Plot a choropleth of the number of ADUs in each tract
ggplot()  +
  geom_sf(data = Chicago_adus_tract_counts, 
          aes(fill = count)) +
  scale_fill_gradient(low = "white", 
                      high = "dark red") + 
  labs(title = "ADU Permits are Concentrated in North Side Census Tracts", 
       subtitle = "Number of ADU permits issued in Chicago, by census tract",
       fill = "ADU Permits",
       caption = "Source: City of Chicago Data Portal") +
  theme_minimal() 

# Group ADUs by tract to identify denial rate, pending rate, and approval rate
# Sum denials per tract
app_aggregated <- Chicago_adu_app_tract |>
  group_by(tractce10) |>
  summarize(issue_rate = mean(issued, na.rm = TRUE),
            denial_rate = mean(denied, na.rm = TRUE),
            pending_rate = mean(pending, na.rm = TRUE),
            total_denials = sum(denied, na.rm = TRUE))
# Filter for points of denial locations
denied_point <- adu_app_coord |>
  filter(status == "Denied")

# Plot chloropleth with denials
ggplot() +
  geom_sf(data = app_aggregated,
          aes(fill = denial_rate)) +
  geom_sf(data = denied_point,
          size = 2, shape = 21, alpha = 0.5,
          fill = "#238b45",
          color = "black") +
  scale_fill_gradient(low = "#66c2a4",
                      high = "#00441b",
                      na.value = "white") +
  labs(title = "ADU Denials concentrated in North and Southwest Census Tracts", 
       subtitle = "Mean ADU denials and denial locations by census tract",
       fill = "Rate of denials",
       caption = "Source: City of Chicago Data Portal") +
  theme_minimal() 

## Max problem set 2 notes:
# Read CSV file with ADU approvals

adus_issued <- read_csv("Additional_Dwelling_Unit_Preapprovals_Issued_20240130.csv")

# Read in Chicago ward shapefiles

chicago_shape <- st_read("Boundaries - Wards (2015-2023)")

# Change CRS

chicago_shape <- st_transform(chicago_shape, 
                              crs = 4326)

# Convert latitude and longitude columns to an SF point geometry column

sf_adus_issued <- adus_issued |>
  st_as_sf(coords = c("LONGITUDE", "LATITUDE"), 
           crs = 4326) |>
  select(geometry, WARD) |>
  rename(ward_adu = WARD)

# Merge Chicago shape file with ADU data

Chicago_adus_merged <- st_join(chicago_shape, sf_adus_issued)

# Group data by ward and find total number of ADUs per ward

Chicago_adus_merged <- Chicago_adus_merged |>
  group_by(ward, .drop = FALSE) |>
  summarize(Count = n()) 

# Plot a choropleth of the number of ADUs in each ward

ggplot()  +
  geom_sf(data = Chicago_adus_merged, 
          aes(fill = Count)) +
  scale_fill_gradient(low = "white", 
                      high = "dark green") + 
  labs(title = "ADU Permits are Concentrated in North Side Wards", 
       subtitle = "Number of ADUs issued in Chicago, by ward",
       fill = element_blank(),
       caption = "Source: City of Chicago Data Portal") +
  theme_minimal() +
  geom_point(data = adus_issued, 
             aes(LONGITUDE, LATITUDE), 
             size = .01)







