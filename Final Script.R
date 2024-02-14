## Maggie data cleaning

## Load packages
library(tidyverse)
library(readr)
library(sf)
library(spData)
library(snakecase)
library(httr)
library(jsonlite)
library(tidycensus)

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

# Read in csv file
adus_issued <- read_csv(paste0(path, "Additional_Dwelling_Unit_Preapprovals_Issued_20240130.csv"))
# Unzip shape file
zipF <- paste0(path, "Boundaries - Census Tracts - 2010.zip")
unzip(zipF,exdir=path)
# Read in shape file
chicago_tracts <- st_read(
  file.path(path, "geo_export_6356fb24-e715-483f-922e-9fd4badc2b8c.shp")
)
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
census_celan <- rename_columns(census_clean)

# Add coords to ADU
adu_coord <- make_coord(adu_clean)

# Join Data


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



