## Regression Analysis

# Run a regression of ADU count on median gross rent of each census tract within an ADU zone. Control for census tract population is included.
summary(lm(count ~ median_gross_rent + total_pop, 
           data = df_tract_counts_census))

# Plot regression of rents on number of ADUs per census tract
rent_regression <- ggplot(data = df_tract_counts_census,
                          aes(x = median_gross_rent,
                              y = count)) +
  geom_point(fill = "#33756D", color = "#33756D",
             shape = 21, size = 2) +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  scale_y_continuous(breaks = c(0, 5, 10, 15), expand = expansion(mult = c(0.1))) +
  scale_x_continuous(breaks = c(0, 1000, 2000, 3000), labels = c("$0", "$1,000", "$2,000", "$3,000"), expand = expansion(mult = c(0.1))) +
  labs(title = "Median gross rent is correlated with number of ADU permits",
       subtitle = "Number of ADU permits compared to median gross rent with linear regression model, by ADU zone census tract",
       y = "Number of ADU Permits",
       x = "Median Gross Rent",
       caption = "Source: City of Chicago Data Portal | 2022 American Community Survey") +
  theme_minimal() +
  theme(
    text = element_text(color = "#22211d"),
    plot.background = element_rect(fill = "#f5f5f2", color = NA),
    panel.background = element_rect(fill = "#f5f5f2", color = NA),
    plot.title = element_text(size= 16, face = "bold", color = "#4e4d47", margin = margin(b = -0.1, t = 0.2, l = 2, unit = "cm")),
    axis.text = element_text(size= 10),
    axis.title = element_text(size= 12, face = "bold"),
    plot.subtitle = element_text(size= 12, hjust=0.01, color = "#4e4d47", margin = margin(b = 0.1, t = 0.25, l = 2, unit = "cm")),
    plot.caption = element_text(size=10, color = "#4e4d47", margin = margin(b = 0.3, t = 0.5, r=-99, unit = "cm") ))
