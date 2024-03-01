install.packages("ggrepel")
library(ggrepel)
install.packages("RColorBrewer")
library(RColorBrewer)
install.packages("scales")
library(scales)
install.packages("forcats")
library(forcats)

#Set path
path <- "/Users/maxwellwagner/Documents/GitHub/DAP_Final/"

#Read in ADU zone files
adu_zones <- st_read(paste0(path, "adu_pilot_areas.geojson"))

adu_zones <- st_transform(adu_zones, 
                          crs = 4326)

#Merge ADU permits with ADU zones
adu_zones_merged <- st_join(adu_zones, adu_coord)

Chicago_adus_zone <- adu_zones_merged |>
  mutate(ADU_zone = if_else(is.na(id), 0, 1))

adu_zones_counts <- Chicago_adus_zone |>
  group_by(name, .drop = FALSE) |>
  summarize(count = sum(ADU_zone))

#Join Chicago tracts with ACS data
chicago_census_data_geo <- chicago_tracts |>
  left_join(census_clean, join_by("tractce10" == "tractce10"))

#Merge census tracts with ADU zones
zone_census_merge <- st_join(chicago_census_data_geo, adu_zones, largest = TRUE)

#Name census tracts outside of ADU zones
zone_census_merge <- zone_census_merge |>
  mutate(Zone = if_else(is.na(name), "Outside ADU Zone", name))

#List census tracts that are majority in an ADU zone
inside_adu_zone <- zone_census_merge |>
  filter(Zone != "Outside ADU Zone")

tracts_adu_zone <- as.list(inside_adu_zone$geoid10)

#Find the count of ADU permits in census tracts within ADU zones
inside_adu_zone_counts <-  Chicago_adus_tract_counts |>
  filter(geoid10 %in% tracts_adu_zone) 

#Convert ADU count and census sf files into dataframes
df_inside_adu_zone_counts <- data_frame(inside_adu_zone_counts)

df_zone_census_merge <- data_frame(zone_census_merge)

#Join the two dataframes
df_tract_counts_census <- inner_join(df_inside_adu_zone_counts, df_zone_census_merge, by = "geoid10")

#Plot regression of rents on number of ADUs per census tract
summary(lm(count ~ median_gross_rent + total_pop, data = df_tract_counts_census))

ggplot(data = df_tract_counts_census,
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

#Plot median rent by zone choropleth
ggplot()  +
  geom_sf(data = chicago_boundaries) +
  geom_sf(data = adu_zones_median_rent, 
          aes(fill = zone_median_rent)) +
  scale_fill_gradient(breaks=c(1025,1325, 1625), low = "#f3f7f2", high = "#33756D", 
                    guide = guide_legend(keyheight = unit(7, units = "mm"), 
                                          keywidth=unit(12, units = "mm"), 
                                          label.position = "right", 
                                          title.position = 'top', 
                                          nrow=3),
                   labels = c("$1,025", "$1,325", "$1,625")) +
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

#Plot median income by zone choropleth
ggplot()  +
  geom_sf(data = adu_zones_counts_income, 
          aes(fill = zone_median_income)) +
  scale_fill_gradient(low = "white", 
                      high = "forest green") + 
  labs(title = "ADU Permits are Concentrated in Zones with Highest Incomes", 
       subtitle = "ADU Permits by Zone",
       fill = "Zone Average Income ",
       caption = "Source: City of Chicago Data Portal") +
  geom_point(data = adu_clean, 
             aes(longitude, latitude), 
             size = .01) +
  theme_void() +
  theme(
    text = element_text(color = "#22211d"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    legend.background = element_rect(fill = "#f5f5f2", color = NA),
    legend.title = element_text(size= 10, face = "bold"),
    plot.title = element_text(size= 12, hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.4, l = 2, unit = "cm")),
    plot.subtitle = element_text(size= 10, hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.43, l = 2, unit = "cm")),
    plot.caption = element_text( size=12, color = "#4e4d47", margin = margin(b = 0.3, r=-99, unit = "cm") ),
    legend.position = c(0.9, 0.7))
  
#Plot regression by income plot
ggplot(data = adu_zones_counts_income,
       aes(x = count,
           y = zone_median_income)) +
  geom_point(color = "lightgray", fill = "steelblue",
             shape = 21, size = 2) +
  geom_smooth() +
  labs(title = "ADU Applications v. Neighborhood Median Income",
       y = "Number of Applications",
       x = "Median Income") +
  theme_bw()

#Plot regression by rent plot
adu_summarize_filter <- adu_summarize |>
  filter(!is.na(id)) |>
  group_by(geoid10) |>
  summarize(count = n(),
            median_rent = mean(median_gross_rent)) 

ggplot(data = adu_summarize_filter,
       aes(x = median_rent,
           y = count)) +
  geom_point(color = "lightgray", fill = "steelblue",
             shape = 21, size = 2) +
  geom_smooth() +
  labs(title = "Areas with higher rents submit more ADU applications",
       subtitle = "Number of ADU applications compared to median gross rent, by census tract",
       y = "Number of Applications",
       x = "Median Gross Rent",
       caption = "Source: City of Chicago Data Portal | 2022 American Community Survey") +
theme_void() +
  theme(
    text = element_text(color = "#22211d"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    plot.title = element_text(size= 12, hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.4, l = 2, unit = "cm")),
    plot.subtitle = element_text(size= 10, hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.43, l = 2, unit = "cm")),
    plot.caption = element_text( size=12, color = "#4e4d47", margin = margin(b = 0.3, r=-99, unit = "cm") ),
    legend.position = c(0.9, 0.7))

#Convert to a dataframe
df_adu_summarize_filter <- data.frame(adu_summarize_filter)

#Find regression statistics for income
summary(lm(count ~ mean_income, data = adu_summarize_filter))

#Read in Chicago boundaries shapefile
chicago_boundaries <- st_read(
  file.path(path, "Boundaries - City")
)

#Change CRS of shapefiles
chicago_boundaries <- st_transform(chicago_boundaries, 
                               crs = 4326)

#Group ADU permits by zone and calculate the number of new market-rate and afffordable ADUs
adu_by_zone <- adu_clean |>
  group_by(adu_zone) |>
  summarize(total_affordable = sum(aff_adus),
            total_new_adus = sum(new_adus),
            total_market_rate = total_new_adus - total_affordable)

#Add the number of possible units in each zone
adu_by_zone_possible <- adu_by_zone |>
  mutate(total_possible = 
           case_when(adu_zone == "North" ~ 20156,
                  adu_zone == "Northwest" ~ 15348,
                  adu_zone == "South" ~ 37279,
                  adu_zone == "Southeast" ~ 10030,
                  adu_zone == "West" ~ 9509))

#Pivot longer in order to plot data on a bar graph
adu_by_zone_wider <- adu_by_zone |>
  pivot_longer(cols = c(total_affordable, total_market_rate), names_to = "Metric", values_to = "Count")

adu_by_zone_possible_wider <- adu_by_zone_possible |>
  pivot_longer(cols = c(total_affordable, total_market_rate, total_new_adus), names_to = "Metric", values_to = "Count")

#Plot possible ADUs next to affordable and market-rate - NEVERMIND, going back to remove possible ADUs from the analysis because it's too large
ggplot(data = adu_by_zone_possible_wider, 
       aes(x = adu_zone, y = Count, fill = Metric)) +
  geom_col(position = "dodge") +
  scale_y_continuous(trans = 'log2')

#Plot comparison of affordable and market-rate ADUs
ggplot(data = adu_by_zone_wider, 
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

  