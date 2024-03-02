## Plot Data

#Plot choropleth of denials
denials <- ggplot() +
  geom_sf(data = chicago_boundaries) +
  geom_sf(data = denial_shape,
          aes(fill = denial_rate)) +
  geom_sf(data = denial_locations |> 
            filter(denied == 1),
          size = 2, 
          shape = 21, 
          alpha = 0.5,
          color = "black", 
          fill = "#fff7bc") +
  scale_fill_gradient(breaks = c(0.10, 0.16, 0.20), 
                      low = "#fff7bc", 
                      high = "#cc4c02") +
  labs(title = "ADU denials are concentrated in the South zone", 
       subtitle = "ADU denial rate and denial locations by zone",
       fill = "Denial rate \n(denials/total apps)",
       caption = "Source: City of Chicago Data Portal") +
  theme_void() +
  theme(
    text = element_text(color = "#22211d"),
    plot.background = element_rect(fill = "#f5f5f2", 
                                   color = NA),
    panel.background = element_rect(fill = "#f5f5f2", 
                                    color = NA),
    legend.background = element_rect(fill = "#f5f5f2", 
                                     color = NA),
    legend.title = element_text(size= 10, 
                                face = "bold"),
    plot.title = element_text(size= 14, 
                              face = "bold", 
                              color = "#4e4d47"),
    plot.subtitle = element_text(size= 9, 
                                 color = "#4e4d47"),
    plot.caption = element_text(size= 10, 
                                color = "#4e4d47"),
    legend.position = c(0.2, 0.2))

#Plot median rent by zone choropleth
adus_by_rent <- ggplot()  +
  geom_sf(data = chicago_boundaries) +
  geom_sf(data = adu_zones_median_rent, 
          aes(fill = zone_median_rent)) +
  scale_fill_gradient(breaks=c(950, 1100, 1250, 1400), 
                      low = "#f3f7f2", 
                      high = "#33756D", 
                      guide = guide_legend(keyheight = unit(6, 
                                                            units = "mm"), 
                                           keywidth=unit(12, 
                                                         units = "mm"), 
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
    plot.background = element_rect(fill = "#f5f5f2", 
                                   color = NA),
    panel.background = element_rect(fill = "#f5f5f2", 
                                    color = NA),
    legend.background = element_rect(fill = "#f5f5f2", 
                                     color = NA),
    legend.title = element_text(size= 10, 
                                face = "bold"),
    plot.title = element_text(size= 14, 
                              face = "bold", 
                              color = "#4e4d47"),
    plot.subtitle = element_text(size= 9, 
                                 color = "#4e4d47"),
    plot.caption = element_text(size=10, 
                                color = "#4e4d47"),
    legend.position = c(0.2, 0.2))

#Plot comparison of affordable and market-rate ADUs
affordable_vs_market <- ggplot(data = adu_by_zone_wider, 
       aes(x = fct_rev(fct_reorder(adu_zone, 
                                   Count)), 
           y = Count, 
           fill = Metric)) +
  geom_col(position = position_stack(reverse = TRUE)) +
  scale_fill_manual(values = c("total_affordable" = "#FCC201", 
                               "total_market_rate" = "#33756D"),
                    labels = c("Affordable", "Market Rate")) +
  scale_y_continuous(breaks=c(0, 50, 100, 150, 200, 250), 
                     expand = expansion(mult = c(0, 0.1))) +
  labs(x = "ADU zone",
       y = "Number of units permitted",
       title = "A small fraction of new ADU units are affordable",
       subtitle = "Number of ADU permits issued in Chicago, by zone and affordability level",
       caption = "Source: City of Chicago Data Portal",
       fill = "Affordablility Level") +
  theme(
    text = element_text(color = "#22211d"),
    plot.background = element_rect(fill = "#f5f5f2", 
                                   color = NA),
    panel.background = element_rect(fill = "#f5f5f2", 
                                    color = NA),
    legend.background = element_rect(fill = "#f5f5f2", 
                                     color = "black"),
    legend.title = element_text(size= 10, 
                                face = "bold"),
    plot.title = element_text(size= 16, 
                              face = "bold", 
                              color = "#4e4d47"),
    axis.text = element_text(size= 10),
    axis.title = element_text(size= 12, 
                              face = "bold"),
    plot.subtitle = element_text(size= 12, 
                                 color = "#4e4d47"),
    plot.caption = element_text(size=10, 
                                color = "#4e4d47"),
    legend.position = c(0.83, 0.8))

#Print plots
denials
affordable_vs_market
adus_by_rent

#Save plots
ggsave(paste0(path, "adu_denials.png"), 
       plot = denials)
ggsave(paste0(path, "adu_affordable_split.png"), 
       plot = affordable_vs_market)
ggsave(paste0(path, "adu_by_rent.png"), 
       plot = adus_by_rent)
