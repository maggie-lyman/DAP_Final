#install.packages("ggrepel")

#install.packages("RColorBrewer")

#install.packages("scales")

#install.packages("forcats")


#Set path
path <- "/Users/maxwellwagner/Documents/GitHub/DAP_Final"
path <- "C:/Users/mlyma/OneDrive/Documents/GitHub/DAP_Final/"

















#Add a zone median income column
adu_zones_counts_income <- adu_zones_counts |>
  mutate(zone_median_income = case_when(name == "North" ~ 54829,
                                        name == "Northwest" ~ 54614,
                                        name == "South" ~ 28951,
                                        name == "Southeast" ~ 30770,
                                        name == "West" ~ 23757))



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





#Plot possible ADUs next to affordable and market-rate - NEVERMIND, going back to remove possible ADUs from the analysis because it's too large
ggplot(data = adu_by_zone_possible_wider, 
       aes(x = adu_zone, y = Count, fill = Metric)) +
  geom_col(position = "dodge") +
  scale_y_continuous(trans = 'log2')



  