library(tidyverse)
library(readr)
library(shiny)
library(sf)
library(spData)
library(snakecase)
library(plotly)
library(lubridate)
library(sf)
library(spData)
library(snakecase)
library(httr)
library(jsonlite)
library(tidycensus)

## Change to application approvals by month instead of applications by month

ui <- fluidPage(
  titlePanel("Additional Dwelling Unit Applications"),
  sidebarLayout(
    sidebarPanel(
      img(src = "https://d11jve6usk2wa9.cloudfront.net/platform/10747/assets/logo.png",
          height = 90,
          width = 260),
      selectInput(inputId = "select_neighborhood", label = "Neighborhood", choices = NULL
      ),
    ), 
    mainPanel(
      tabsetPanel(
        tabPanel("Plot", plotlyOutput("graph")),
        tabPanel("Median Rent", tableOutput("median_rent")),
        tabPanel("Median Income", tableOutput("median_income"))
      )
    )
  )
)

server <- function(input, output) { 
  # Set path
  path <- "C:/Users/mlyma/OneDrive/Documents/GitHub/DAP_Final/"
  
  ## Read in data
  
  # Upload CSV
  adus <- read_csv(paste0(path, "Additional_Dwelling_Unit_Preapproval_Applications_20240216.csv"))
  
  # Shape Files
  zipF <- paste0(path, "Boundaries - Census Tracts - 2010.zip")
  unzip(zipF,exdir=path)
  chicago_tracts <- st_read(
    file.path(path, "geo_export_6356fb24-e715-483f-922e-9fd4badc2b8c.shp")
  )
  ZipF2 <- paste0(path, "Boundaries - Neighborhoods.zip")
  unzip(ZipF2, exdir = path)
  chicago_neighborhoods <- st_read(
    file.path(path, "geo_export_ab2c9a8a-dc67-4ec7-a969-bb86c9c5c6bd.shp")
  )
  
  # Census
  # Upload census
  key <- "a58ec96cdf12838255365193b5aa59b943091de3"
  census_data <- get_acs(geography = "tract",
                         variables = c("B01003_001", "B05010_001", "B19326_001",
                                       "B07002_001", "B07013_002", "B25106_002", "B25064_001",
                                       "B25070_001"),
                         state = "IL",
                         year = 2020,
                         output = "tidy",
                         county = "Cook",
                         key = key,
                         survey = "acs5")
  
  # Add functions
  rename_columns <- function(df){ 
    snake <- to_snake_case(names(df))
    names <- noquote(snake, right = FALSE)
    setNames(df, names)
  }
  
  make_coord <- function(df){
    st_as_sf(x = df,
             coords = c("longitude", "latitude"),
             crs = 4326)
  }
  
  ## Clean and merge data
  # Change CRS of shapefiles
  chicago_tracts <- st_transform(chicago_tracts, 
                                 crs = 4326)
  
  # Change CRS of shapefile
  chicago_neighborhoods <- st_transform(chicago_neighborhoods, 
                                        crs = 4326)
  
  
  # Clean CSV
  adu_clean <- rename_columns(adus)
  adu_clean <- make_coord(adu_clean)
  
  
  # Clean census
  census_wide <- census_data |>
    dplyr::select(-moe) |>
    pivot_wider(names_from = variable,
                values_from = estimate)
  
  census_clean <- census_wide |>
    rename(total_pop = B01003_001,
           ratio_income_to_poverty = B05010_001,
           median_income = B19326_001,
           median_age = B07002_001,
           owner_occupied_housing = B07013_002,
           owner_occupied_by_perc_income = B25106_002,
           median_gross_rent = B25064_001,
           gross_rent_perc_income = B25070_001)
  
  ## Join data
  adu_tract <- st_join(chicago_tracts, adu_clean)
  adu_tract_hood <- st_join(chicago_neighborhoods, adu_tract)
  
  adu_summarize <- data.frame(adu_tract_hood)
  
  adu_summarize <- adu_summarize |>
    left_join(census_clean, join_by("geoid10" == "GEOID"))
  
  ## Summarize data
  adu_months <- adu_summarize |>
    mutate(ADU_approved = ifelse(status == "Issued", 1, 0),
           approval_date = mdy(status_updated_date),
           month = round_date(approval_date, 'month'),
           submission_date = mdy(submission_date),
           month = round_date(submission_date, 'month'),
           ADU_submitted = if_else(is.na(id), 0, 1)) |>
    group_by(pri_neigh) |>
    mutate(avg_median_income = mean(median_income, na.rm = TRUE),
           avg_gross_rent = mean(median_gross_rent, na.rm = TRUE)) |>
    ungroup() |>
    group_by(month) |>
    mutate(total_approvals = sum(ADU_approved),
           total_submissions = sum(ADU_submitted)) |>
    distinct(pri_neigh, month, .keep_all = TRUE) |>
    select(pri_neigh, month, ADU_approved, total_approvals, ADU_submitted,
           median_income, total_submissions, median_gross_rent, 
           avg_median_income, avg_gross_rent) |>
    ungroup()
  
  # Choose neighborhood
  observeEvent(adu_months, {
    nb_options <- adu_months |>
      group_by(pri_neigh) |>
      summarize(sum = sum(ADU_approved, na.rm = TRUE)) |>
      filter(sum > 0) |>
      pull(pri_neigh)
    updateSelectInput(inputId = "select_neighborhood", choices = nb_options) 
  })
  
  # Filter Data  
    chosen_neighborhood <- reactive({
      adu_months |>
        filter(pri_neigh == input$select_neighborhood)
    })
  
  # Plot ADU submissions
  output$graph <- renderPlotly({
    plot <- ggplot(data = chosen_neighborhood()) +
      geom_point(aes(x = month,
                     y = total_approvals,
                     fill = "Approvals"),
                 color = "lightgray",
                 shape = 21, size = 2) +
      geom_line(aes(x = month,
                    y = total_approvals, group = 1),
                color = "lightgreen",
                linetype = "dashed") +
      geom_point(aes(x = month,
                     y = total_submissions,
                     fill = "Submissions"),
                 color = "lightgray",
                 shape = 21, size = 2) +
      geom_line(aes(x = month,
                    y = total_submissions, group = 1),
                color = "steelblue") +
      labs(title = "ADU submissions and approvals by month",
           subtitle = "Monthly applications and approvals since ordinance passed \n in December 2020",
           y = "Submission and approval count",
           x = "Month") +
      scale_fill_manual(values = c("Approvals" = "lightgreen", "Submissions" = "steelblue"), 
                        guide = guide_legend(title = "Application type")) +
      theme_bw()
    
      ggplotly(plot)
  })
  
  # Create table 
  output$median_rent <- renderTable({chosen_neighborhood() |>
      distinct(pri_neigh, .keep_all = TRUE) |>
      pull(avg_gross_rent)
  })
  
  output$median_income <- renderTable({chosen_neighborhood() |>
      distinct(pri_neigh, .keep_all = TRUE) |>
      pull(avg_median_income)
  })
}

shinyApp(ui = ui, server = server)

