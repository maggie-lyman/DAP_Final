# DAP_Final

Our data
- Tracts from census for chloropleth
- ADU issued (coach house vs basement unit)
- ADU applications (shows denied and accepted)
- Average rent data (API)
- Census? 

Our questions
- Where are ADUs being built? Are they being built in areas with the highest rents?
- Where are ADUs being denied?
- What kinds of ADUs are being built? 

Our plots

1. Non-dynamic: Chloropleth/point where are ADUs (and type by shape)
  - Max
  - Approved applications
2. Dynamic: Average rent and number of ADUs built
  - Max
3. Non-dynamic: Chloropleth with ADU denials (and type by shape)
  - Maggie
4. Dynamic: Applications by month since the start of program filtered by ward/neighborhood - use plotly to see exact number (include regression?)
  - Maggie 

Text processing <- come back

Analysis

Linear regression of average number of ADU applications in each neighborhood/tract by log median rent (or median rent). Report on statistic and plot. Use plot as one of two static plots or add to Shiny app. 