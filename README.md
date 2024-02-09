# DAP_Final

Our data
- Tracts from census for chloropleth
- ADU applications (shows denied and accepted, including type)
- Average rent data (API)
- Census? 
- Look for shape file with ADU zones?

* Clean data only for those up until 10/31/2023
* Program started May 1, 2021
--> Look at first 18-months of the program

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

Text processing 

Find articles about ADU ordinance/pilot program to identify public perception of ADUs. Plot if public perception is mostly positive or mostly negative. 

Analysis

Linear regression of average number of ADU applications in each neighborhood/tract by log median rent (or median rent). Report on statistic and plot. Use plot as one of two static plots or add to Shiny app.

If there is enough data, we could conduct a t-test to identify if ADUs are more positively received in certain zones. 