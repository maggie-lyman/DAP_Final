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
library(ggrepel)
library(RColorBrewer)
library(scales)
library(forcats)

## Add path
path <- "C:/Users/mlyma/OneDrive/Documents/GitHub/DAP_Final/"
#path <- "/Users/maxwellwagner/Documents/GitHub/DAP_Final/"

## Load data

# Read in csv files: ADU Applications and Issues
adus_issued <- read_csv(paste0(path, "Additional_Dwelling_Unit_Preapprovals_Issued_20240130.csv"))
adu_apps <- read_csv(paste0(path, "Additional_Dwelling_Unit_Preapproval_Applications_20240207.csv"))

# Read in Shape Files: Chicago Census Tracts, Chicago boundaries, ADU Zones

# Chicago Census Tracts
zipF <- paste0(path, "Boundaries - Census Tracts - 2010.zip")
unzip(zipF,exdir=path)
chicago_tracts <- st_read(
  file.path(path, "geo_export_6356fb24-e715-483f-922e-9fd4badc2b8c.shp")
)
# Change CRS 
chicago_tracts <- st_transform(chicago_tracts, 
                               crs = 4326)

# ADU Zones
adu_zones <- st_read(paste0(path, "adu_pilot_areas.geojson"))
# Change CRS
adu_zones <- st_transform(adu_zones, 
                          crs = 4326)

#Read in Chicago boundaries
chicago_boundaries <- st_read(
  file.path(path, "Boundaries - City")
)
#Change CRS 
chicago_boundaries <- st_transform(chicago_boundaries, 
                                   crs = 4326)

# Read in Census Data

# Read in API census data
key <- "a58ec96cdf12838255365193b5aa59b943091de3"
census_data <- get_acs(geography = "tract",
                       variables = c("B01003_001", "B05010_001", "B19326_001",
                                     "B07002_001", "B07013_002", "B25106_002", "B25064_001",
                                     "B25070_001"),
                       state = "IL",
                       year = 2020,
                       output = "tidy",
                       county = "Cook",
                       key = key,
                       survey = "acs5")

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

## Join Data

# Merge shape files with ADU coordinates
Chicago_adus_merged <- st_join(chicago_tracts, adu_coord)
Chicago_adu_app_merged <- st_join(chicago_tracts, adu_app_coord)

# Join Chicago tracts with ACS data
chicago_census_data_geo <- chicago_tracts |>
  left_join(census_clean, join_by("geoid10" == "geoid"))

# Merge census tracts with ADU zones
zone_census_merge <- st_join(chicago_census_data_geo, adu_zones, largest = TRUE)

## Manipulate Data

# First clean denial data
# Group by zone to find denail total and rate for each
denial_locations <- adu_app_coord |>
  mutate(denied = ifelse(status == "Denied", 1, 0)) |>
  group_by(adu_zone) |>
  mutate(total_apps = n(),
         total_denials = sum(denied, na.rm = TRUE),
         denial_rate = total_denials/total_apps) |>
  ungroup()

# Join denied data with zone shape file
denial_shape <- st_join(adu_zones, denial_locations)

# Next clean census/zone data
# Add a new column with a binary variable indicating whether a row represents an ADU permit issued
Chicago_adus_tract <- Chicago_adus_merged |>
  mutate(ADU_tract = if_else(is.na(id), 0, 1))

#Group data by census tract and find total number of ADUs per census tract
Chicago_adus_tract_counts <- Chicago_adus_tract |>
  group_by(tractce10, .drop = FALSE) |>
  summarize(count = sum(ADU_tract))

#Name census tracts outside of ADU zones
zone_census_merge <- zone_census_merge |>
  mutate(Zone = if_else(is.na(name.y), "Outside ADU Zone", name.y))

#List census tracts that are majority in an ADU zone
inside_adu_zone <- zone_census_merge |>
  filter(Zone != "Outside ADU Zone")

tracts_adu_zone <- as.list(inside_adu_zone$tractce10)

#Find the count of ADU permits in census tracts within ADU zones
inside_adu_zone_counts <-  Chicago_adus_tract_counts |>
  filter(tractce10 %in% tracts_adu_zone) 

#Convert ADU count and census sf files into dataframes
df_inside_adu_zone_counts <- data_frame(inside_adu_zone_counts)

df_zone_census_merge <- data_frame(zone_census_merge)

#Join the two dataframes to get census data for each tract within an ADU zone
df_tract_counts_census <- inner_join(df_inside_adu_zone_counts, df_zone_census_merge, by = "tractce10")

# Check to ensure that all ADU permits issued are counted
test_that("All ADU permits are represented in count", 
          expect_equal(sum(inside_adu_zone_counts$count), nrow(adus_issued)))

#Find the population of each zone
zone_population_grouped <- df_tract_counts_census |>
  drop_na(total_pop) |>
  group_by(Zone) |>
  summarize(total_zone_population = sum(total_pop)) 

#Add a zone population column to the zone_census_merge 
df_tract_counts_census_pop <- df_zone_census_merge |>
  inner_join(zone_population_grouped, by = "Zone")

#Add the proportion of each census tract's population to the total zone population
df_tract_counts_census_pop <- df_tract_counts_census_pop |>
  mutate(pop_proportion = total_pop/total_zone_population)

#Convert each census tract's metrics to a weighted measure
df_tract_counts_census_pop <- df_tract_counts_census_pop |>
  mutate(rent_weighted = median_gross_rent * pop_proportion)

#Find the population-weighted median for each zone
zone_rent_grouped <- df_tract_counts_census_pop |>
  drop_na(rent_weighted) |>
  group_by(Zone) |>
  summarize(zone_median_rent = sum(rent_weighted))

#Add a zone median rent column 
df_adu_zones <- data.frame(adu_zones) |>
  rename(Zone = name)

df_adu_zones_median_rent <- df_adu_zones |>
  inner_join(zone_rent_grouped, by = "Zone")

#Convert back to a sf file
adu_zones_median_rent <- st_as_sf(df_adu_zones_median_rent)

#Group ADU permits by zone and calculate the number of new market-rate and afffordable ADUs
adu_by_zone <- adu_clean |>
  group_by(adu_zone) |>
  summarize(total_affordable = sum(aff_adus),
            total_new_adus = sum(new_adus),
            total_market_rate = total_new_adus - total_affordable)

#Pivot longer in order to plot data on a bar graph
adu_by_zone_wider <- adu_by_zone |>
  pivot_longer(cols = c(total_affordable, total_market_rate), names_to = "Metric", values_to = "Count")

## Regression Analysis

summary(lm(count ~ median_gross_rent + total_pop, data = df_tract_counts_census))

## Plot Data
# Plot choropleth of denials
denials <- ggplot() +
  geom_sf(data = chicago_boundaries) +
  geom_sf(data = denial_shape,
          aes(fill = denial_rate)) +
  geom_sf(data = denial_locations |> filter(denied == 1),
          size = 2, shape = 21, alpha = 0.5,
          color = "black", fill = "#fff7bc") +
  scale_fill_gradient(breaks = c(0.10, 0.16, 0.20), 
  low = "#fff7bc", high = "#cc4c02") +
  labs(title = "ADU denials are concentrated in \nSouthwest zone", 
       subtitle = "ADU denial rate and denial locations by zone",
       fill = "Denial rate \n(denials/total apps)",
       caption = "Source: City of Chicago Data Portal") +
  theme_void() +
  theme(
    text = element_text(color = "#22211d"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    legend.background = element_rect(fill = "#f5f5f2", color = NA),
    legend.title = element_text(size= 10, face = "bold"),
    plot.title = element_text(size= 14, face = "bold", hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.4, l = 2, unit = "cm")),
    plot.subtitle = element_text(size= 9, hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.25, l = 2, unit = "cm")),
    plot.caption = element_text(size=8, color = "#4e4d47", margin = margin(b = 0.3, r=-99, unit = "cm") ),
    legend.position = c(0.2, 0.2))

#Plot median rent by zone choropleth
adus_by_rent <- ggplot()  +
  geom_sf(data = chicago_boundaries) +
  geom_sf(data = adu_zones_median_rent, 
          aes(fill = zone_median_rent)) +
  scale_fill_gradient(breaks=c(950, 1100, 1250, 1400), low = "#f3f7f2", high = "#33756D", 
                      guide = guide_legend(keyheight = unit(6, units = "mm"), 
                                           keywidth=unit(12, units = "mm"), 
                                           label.position = "right", 
                                           title.position = 'top', 
                                           nrow=4),
                      labels = c("$950", "$1,100", "$1,250", "$1,400")) +
  labs(title = "ADU permits are concentrated in high rent zones", 
       subtitle = "City of Chicago ADU permit locations compared to zone median gross rent",
       fill = "Median Gross Rent ",
       caption = "Source: City of Chicago Data Portal | 2022 American Community Survey") +
  geom_point(data = adu_clean, 
             aes(longitude, latitude), 
             size = .2) +
  theme_void() +
  theme(
    text = element_text(color = "#22211d"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    legend.background = element_rect(fill = "#f5f5f2", color = NA),
    legend.title = element_text(size= 10, face = "bold"),
    plot.title = element_text(size= 14, face = "bold", hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.4, l = 2, unit = "cm")),
    plot.subtitle = element_text(size= 9, hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.25, l = 2, unit = "cm")),
    plot.caption = element_text(size=8, color = "#4e4d47", margin = margin(b = 0.3, r=-99, unit = "cm") ),
    legend.position = c(0.2, 0.2))

#Plot comparison of affordable and market-rate ADUs
affordable_vs_market <- ggplot(data = adu_by_zone_wider, 
       aes(x = fct_rev(fct_reorder(adu_zone, Count)), y = Count, fill = Metric)) +
  geom_col(position = position_stack(reverse = TRUE)) +
  scale_fill_manual(values = c("total_affordable" = "#FCC201", "total_market_rate" = "#33756D"),
                    labels = c("Affordable", "Market Rate")) +
  scale_y_continuous(breaks=c(0, 50, 100, 150, 200, 250), expand = expansion(mult = c(0, 0.1))) +
  labs(x = "ADU zone",
       y = "Number of units permitted",
       title = "A small fraction of new ADU units are affordable",
       subtitle = "Number of ADU permits issued in Chicago, by zone and affordability level",
       caption = "Source: City of Chicago Data Portal",
       fill = "Affordablility Level") +
  theme(
    text = element_text(color = "#22211d"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    legend.background = element_rect(fill = "#f5f5f2", color = "black"),
    legend.title = element_text(size= 10, face = "bold"),
    plot.title = element_text(size= 16, face = "bold", hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.2, l = 2, unit = "cm")),
    axis.text = element_text(size= 10),
    axis.title = element_text(size= 12, face = "bold"),
    plot.subtitle = element_text(size= 12, hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.25, l = 2, unit = "cm")),
    plot.caption = element_text(size=10, color = "#4e4d47", margin = margin(b = 0.3, t = 0.3, r=-99, unit = "cm") ),
    legend.position = c(0.83, 0.8))

# Plot regression of rents on number of ADUs per census tract
rent_regression <- ggplot(data = df_tract_counts_census,
       aes(x = median_gross_rent,
           y = count)) +
  geom_point(fill = "#33756D", color = "#33756D",
             shape = 21, size = 2) +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  scale_y_continuous(breaks = c(0, 5, 10, 15), expand = expansion(mult = c(0.1))) +
  scale_x_continuous(breaks = c(0, 1000, 2000, 3000), labels = c("$0", "$1,000", "$2,000", "$3,000"), expand = expansion(mult = c(0.1))) +
  labs(title = "Median gross rent is correlated with ADU permits",
       subtitle = "Number of ADU permits compared to median gross rent, by census tract",
       y = "Number of ADU Permits",
       x = "Median Gross Rent",
       caption = "Source: City of Chicago Data Portal | 2022 American Community Survey") +
  theme_minimal() +
  theme(
    text = element_text(color = "#22211d"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    plot.title = element_text(size= 16, face = "bold", hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.2, l = 2, unit = "cm")),
    axis.text = element_text(size= 10),
    axis.title = element_text(size= 12, face = "bold"),
    plot.subtitle = element_text(size= 12, hjust=0.01, color = "#4e4d47", margin = margin(b = 0.1, t = 0.25, l = 2, unit = "cm")),
    plot.caption = element_text(size=10, color = "#4e4d47", margin = margin(b = 0.3, t = 0.5, r=-99, unit = "cm") ))

# Print plots
denials
affordable_vs_market
rent_regression
adus_by_rent

# Save plot
ggsave(paste0(path, "adu_denials.png"), plot = denials)
ggsave(paste0(path, "adu_affordable_split.png"), plot = affordable_vs_market)
ggsave(paste0(path, "rent_regression.png"), plot = rent_regression)
ggsave(paste0(path, "adu_by_rent.png"), plot = adus_by_rent)
