## Max's code from pset2:

# Add paths

# Read CSV file with ADU approvals

adus_issued <- read_csv("Additional_Dwelling_Unit_Preapprovals_Issued_20240130.csv")

# Read in Chicago ward shapefiles

chicago_shape <- st_read("/Users/maxwellwagner/Downloads/Boundaries - Wards (2015-2023)")

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



