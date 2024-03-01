# DAP_Final

**To Do as of 3/1**
1. Email prof about our github - Maggie DONE
2. Organization - Move regression to separate file - Max DONE
3. Readme - What each code and what order - Max
4. Readme - Data source and description of data - Maggie DONE
5. Readme - What needs to be modified to replicate - Maggie (mostly) DONE
6. Readme - Date created, authors, version, packages, package versions - Max
7. Readme - Link to shiny apps - Maggie DONE
8. Organization - Rename files - choropleth file to static plot R, shiny apps, write up - Maggie DONE
9. Organization - Create data folder and images folder, put images in there - Max DONE
10. Write up - Research question/background - Max
11. Write up - Approach taken/coding involved/difficulties - Maggie
12. Write up - Results and future research - Max
13. Write up - Github user names and names - Maggie/Max

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

### The data sources include:

  1. **ADU pre-approved applications CSV from the City of Chicago:** Data includes ADU zone, geometric location (longitude and latitude), affordability or market price, applicant information, status of application (pending, denied, issued), etc. for all ADU permit applications
  2. **ADU pre-approvals issued CSV from the City of Chicago:** Data includes ADU zone, geometric location (longitude and latitude), affordability or market price, applicant infomation, etc. for all ADU permits issued
  3. **Chicago census tracts shapefile from the City of Chicago:** Data includes geometric boundaries for all census tract areas in Chicago
  4. **Chicago neighborhood shapefile from the City of Chicago:** Data includes geometric boundaries for all 77 Chicago neighborhoods
  5. **Chicago boundary shapefile from the City of Chicago:** Data includes Chicago geometric boundary
  6. **ADU pilot zones JSON:** Data includes ADU ordinance zone boundaries
  7. **2020 American Community Survey:** Data is collected using API. Includes Cook county data for total population, poverty income ratio, median income, median gross rent, median age, rate of owner occupied housing, rate of owner occupied housing by percent income, gross rent per percent income. *Note:* Not all fields are used in the study, but could be used for relevant future analysis.
  8. **Chicago subreddit text data:** Text data scraped from Chicago subreddit thread about ADU ordinance. Comment text downloaded for analysis.
  
### Description of code + order the files should fun

The R files included in the repo are described below and should be run in the following order:

  1. **staticplot.R:** 

The code reads in data sources 1-7 listed above. For spatial datasets, the CRS is set to 4326 to maintain consistency. For the ACS data, an API is used to pull 2020 survey data. The data sources are then cleaned using two functions: rename_columns and make_coord. New column names are applied to the ACS data to replace the variable codes. Next, a series of joins are used to join the ACS data with census tract geometries, ADU location geometries with census tract geometries and census tract geometries with ADU zone geometries.

The code then identifies the location of ADU permit denials and joins the denial geometries with the ADU zone geometries. Next, the code identifies the count of ADUs in each census tract and adds a column that specifies whether a census tract is inside or outside of an ADU zone. The tract codes for each census tract within an ADU zone are added to a list so that the ACS data can be filtered to include only census tracts within an ADU zone. Joins are performed to generate a dataframe that includes the geometries of the 314 census tracts within ADU zones along with the count of ADUs in each tract and the ACS data. A check confirms that all permitted ADUs are included.

Next, the code calculates each census tract's proportion of the total zone population. The proportions are used to weight the median gross rent of each census tract. The result is a population-weighted median gross rent for each ADU zone.

The number of market-rate and affordable ADUs are then calculated. A pivot wider puts the data in the format necessary for a bar plot.

Lastly, three static plots are generated, printed and saved:

- Choropleth: ADU permit denial locations
- Choropleth: Median gross rent by ADU zone
- Bar plot: Comparison of affordable and market-rate ADUs 

   2. **model.R:** 

The code runs a linear regression of ADU count on median gross rent of each census tract within an ADU zone. A control for census tract population is included.

The code then creates a plot of median gross rent vs. the number of ADUs per census tract. A linear regression line shows that median gross rent is positively correlated with the number of new ADUs in a census tract.

   3. **shinyapp.R:**
   

   
   4. **textprocess.R:**

### Packages to use this repo include:

### Replication modifications:

  - **staticplot.R:** Update path in line 17 and (*optional*) API Census key in line 55
  - **model.R:** <-- come back****
  - **shinyapp.R:** Update path in line 39 and (*optional*) API Census key in line 60
  - **textprocess.R:** None
  
### Link to Shiny Plot

*Note:* At this time, Shiny apps are not deployed. Users of this repo have permission to deploy Shiny Apps. 

Local Shiny App Links are as followed:

  1. [shinyapp.R](http://127.0.0.1:5962/)
  2. [textprocess.R](http://127.0.0.1:6970/)