# DAP_Final

**To Do as of 2/22**
  1. Analysis section --> update "maggie app.R" page to include regression and graph
  2. Finish slides --> Make sure it knits and graphs are included
  3. Finish write up
  4. Complete ReadMe file --> started below our notes

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

Presentation Agenda
1. Choropleth of zones --> approved by zone
2. Choropleth of denials 
3. Shiny app 1 --> **change to approvals by month, not for presentation
4. Regression
5. Affordability
6. Text processing 

Our plots

1. Non-dynamic: Chloropleth/point where are ADUs (and type by shape)
  - Max (DONE)
  - Approved applications
2. Dynamic: Average rent and number of ADUs built (include regression?)
  - Max
  - Update Maggie app.R file to include regression plot on another tab
3. Non-dynamic: Choropleth with ADU denials (and type by shape)
  - Maggie (DONE)
4. Dynamic: Applications by month since the start of program filtered by ward/neighborhood - use plotly to see exact number 
  - Maggie (DONE)
5. Dynamic: Text processing dashboard with sentiment analysis and dependency plots
  - Maggie (DONE)

Text processing  (DONE)

Find articles about ADU ordinance/pilot program to identify public perception of ADUs. Plot if public perception is mostly positive or mostly negative. 

Text processing ideas

[Reddit](https://www.reddit.com/r/chicago/comments/13wu8pw/adu_citywide_expansion_ordinance_introduced_to/) <- could be insane but also fun?
[Sun-times](https://chicago.suntimes.com/city-hall/2023/6/9/23754347/chicago-affordable-housing-expand-coach-houses-basement-units-program)
[Blog](https://www.bldgproj.com/blog/chicago-adu-ordinance)
[Chicago ULI](https://chicago.uli.org/programs/uli-in-the-community/adu-initiative/)
[The Real Deal](https://therealdeal.com/chicago/2023/06/09/top-chicago-officials-push-citywide-adu-expansion/)
[Chicago YIMBY](https://chicagoyimby.com/2022/11/deep-dive-into-chicagos-additional-dwelling-unit-adu-ordinance-after-six-months.html)

Analysis

Linear regression of average number of ADU applications in each neighborhood/tract by log median rent (or median rent). Report on statistic and plot. Use plot as one of two static plots or add to Shiny app.

If there is enough data, we could conduct a t-test to identify if ADUs are more positively received in certain zones. 

## ReadMe File

This repo analyzes Additional Dwelling Units in Chicago. This analysis uses data collected from the City of Chicago, US Census, and text data from the Chicago sub-reddit.

Packages to use this repo include: