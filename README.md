**To Do as of 3/1**
1. Email prof about our github - Maggie DONE
2. Organization - Move regression to separate file - Max DONE
3. Readme - What each code and what order - Max DONE
4. Readme - Data source and description of data - Maggie DONE
5. Readme - What needs to be modified to replicate - Maggie DONE
6. Readme - Date created, authors, version, packages, package versions - Max DONE
7. Readme - Link to shiny apps - Maggie DONE
8. Organization - Rename files - choropleth file to static plot R, shiny apps, write up - Maggie DONE
9. Organization - Create data folder and images folder, put images in there - Max DONE
10. Write up - Research question/background - Max
11. Write up - Approach taken/coding involved/difficulties - Maggie DONE
12. Write up - Results and future research - Max
13. Write up - Github user names and names - Maggie/Max

### ReadMe File - DAP Final

This repo analyzes Additional Dwelling Units in Chicago. This analysis uses data collected from the City of Chicago, US Census, and text data from the Chicago sub-reddit.

### Authors

Max Wagner
Maggie Lyman

### Date Created

March 2, 2024 

### R version

RStudio 2022.07.1+554 "Spotted Wakerobin" Release (7872775ebddc40635780ca1ed238934c3345c5de, 2022-07-22) for macOS
Mozilla/5.0 (Macintosh; Intel Mac OS X 13_2_0) AppleWebKit/537.36 (KHTML, like Gecko) QtWebEngine/5.12.10 Chrome/69.0.3497.128 Safari/537.36

### Packages to use this repo include:

- tidyverse
- readr
- sf
- spData
- snakecase
- httr
- jsonlite 
- tidycensus
- testthat
- ggrepel
- scales
- forcats
- shiny
- tidytext
- textdata
- sentimentr
- rvest
- RedditExtractoR
- udpipe
- igraph
- ggraph
- plotly
- lubridate
- readr

### The data sources include:

  1. **ADU pre-approved applications CSV from the City of Chicago:** Data includes ADU zone, geometric location (longitude and latitude), affordability or market price, applicant information, status of application (pending, denied, issued), etc. for all ADU permit applications
  2. **ADU pre-approvals issued CSV from the City of Chicago:** Data includes ADU zone, geometric location (longitude and latitude), affordability or market price, applicant infomation, etc. for all ADU permits issued
  3. **Chicago census tracts shapefile from the City of Chicago:** Data includes geometric boundaries for all census tract areas in Chicago
  4. **Chicago neighborhood shapefile from the City of Chicago:** Data includes geometric boundaries for all 77 Chicago neighborhoods
  5. **Chicago boundary shapefile from the City of Chicago:** Data includes Chicago geometric boundary
  6. **ADU pilot zones JSON:** Data includes ADU ordinance zone boundaries
  7. **2020 American Community Survey:** Data is collected using API. Includes Cook county data for total population, poverty income ratio, median income, median gross rent, median age, rate of owner occupied housing, rate of owner occupied housing by percent income, gross rent per percent income. *Note:* Not all fields are used in the study, but could be used for relevant future analysis.
  8. **Chicago subreddit text data:** Text data scraped from Chicago subreddit thread about ADU ordinance. Comment text downloaded for analysis.
  
### Description of code + order the files should run

The R files included in the repo are described below and should be run in the following order:

   1. **data.R:**

First, The code reads in data sources 1-7 listed above. For spatial datasets, the CRS is set to 4326 to maintain consistency. For the ACS data, an API is used to pull 2020 survey data. The data sources are then cleaned using two functions: rename_columns and make_coord. New column names are applied to the ACS data to replace the variable codes. Next, a series of joins are used to join the ACS data with census tract geometries, ADU location geometries with census tract geometries and census tract geometries with ADU zone geometries.

The code then identifies the location of ADU permit denials and joins the denial geometries with the ADU zone geometries. Next, the code identifies the count of ADUs in each census tract and adds a column that specifies whether a census tract is inside or outside of an ADU zone. The tract codes for each census tract within an ADU zone are added to a list so that the ACS data can be filtered to include only census tracts within an ADU zone. Joins are performed to generate a dataframe that includes the geometries of the 314 census tracts within ADU zones along with the count of ADUs in each tract and the ACS data. A check confirms that all permitted ADUs are included.

Next, the code calculates each census tract's proportion of the total zone population. The proportions are used to weight the median gross rent of each census tract. The result is a population-weighted median gross rent for each ADU zone.

The number of market-rate and affordable ADUs are then calculated. A pivot wider puts the data in the format necessary for a bar plot.

  2. **staticplot.R:** 

The code creates three static plots:

- Choropleth: ADU permit denial locations
- Choropleth: Median gross rent by ADU zone
- Bar plot: Comparison of affordable and market-rate ADUs 

Inspiration for colors and plot formatting taken from: https://r-graph-gallery.com/327-chloropleth-map-from-geojson-with-ggplot2.html

The three static plots are generated, printed and saved. 

   3. **model.R:** 

The code runs a linear regression of ADU count on median gross rent of each census tract within an ADU zone. A control for census tract population is included.

The code then creates a plot of median gross rent vs. the number of ADUs per census tract. A linear regression line shows that median gross rent is positively correlated with the number of new ADUs in a census tract.

   4. **shinyapp.R:**
   
The code creates a shiny app to display information about ADUs at the neighborhood level. It allows the user to choose a neighborhood and generate data across three tabs:

- Plot: The monthly ADU applications and approvals since May 2021
- Median Rent (2020): The median gross rent for the neighborhood, per 2020 ACS
- Median Income (2020): The median income for the neighborhood, per 2020 ACS

First, the code sets up the UI, creating a drop-down for the neighborhood and the three panels outlined above. Next, the data sources are cleaned using the same methods outlined above in the **staticplot.R:** section.

Next, the code summarizes the ADU data and ACS data at the neighborhood level. Median gross rent and median income are calculated using a weighted average based on population of each census tract within a neighborhood. ADU applications and approvals and grouped and counted. A reactive function is used to filter the datasets by neighborhood.

Lastly, the plot and two tables are generated.
   
   5. **textprocess.R:**
   
The code creates a shiny app to display information about ADU sentiment, scraped from a Reddit thread about the 2021 ADU Ordinance. It allows the user to choose one of four words frequently used in the Reddit thread and view the overall sentiment and word webs stemming from that word. The two tabs are:

- Overall Sentiment: A plot of the NRC sentiment and AFINN summary statistics for the text from the Reddit thread
- Word Webs: Dependency graphs for the selected frequent word from the Reddit thread

First, the code sets up the UI, creating a drop-down for the frequent word and the two panels outlined above. Next, a function is created to use the RedditExtractoR package to scrape the text from the Reddit thread. The text is aggregated, stop words are removed and lemmas are generated using udpipe.

Next, the sentiment is analyzed using NRC and AFINN. Summary statistics are generated and a plot is created using the NCR sentiment words.

Lastly, the dependency graphs are created using the following functions:

- children
- parent
- bigram
- graph_bigram
- plot_web

A reactive function is used to filter based on the user's selected word.

### Replication modifications:

  - **staticplot.R:** Update path in line 17 and (*optional*) API Census key in line 55
  - **model.R:** None
  - **shinyapp.R:** Update path in line 39 and (*optional*) API Census key in line 60
  - **textprocess.R:** None
  
### Link to Shiny Plot

*Note:* At this time, Shiny apps are not deployed. Users of this repo have permission to deploy Shiny Apps. 

Local Shiny App Links are as followed:

  1. [shinyapp.R](http://127.0.0.1:5962/)
  2. [textprocess.R](http://127.0.0.1:6970/)