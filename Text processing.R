library(tidyverse)
library(tidytext)
library(textdata)
library(sentimentr)
library(rvest)
library(RedditExtractoR)
library(udpipe)
library(igraph)
library(ggraph)
library(shiny)
library(plotly)

frequent_words <- c("Chicago", "city", "ordinance", "housing")

ui <- fluidPage(
  titlePanel("Public Perception of Chicago ADU Ordinance"),
  sidebarLayout(
    sidebarPanel(
      img(src = "https://d11jve6usk2wa9.cloudfront.net/platform/10747/assets/logo.png",
          height = 90,
          width = 260),
      selectInput(inputId = "select_word", label = "Select Frequent Word", choices = frequent_words
      ),
    ), 
    mainPanel(
      tabsetPanel(
        tabPanel("Overall Sentiment", 
                 h4("Sentiment analysis of ADU ordinance"),
                 h6("Text collected from Chicago sub-reddit thread about ADU ordinance"),
                 plotOutput("sentiment_graph"),
                 h4("Summary statistics calculated using afinn sentiment"),
                 tableOutput("sentiment_summary")),
        tabPanel("Word Webs", 
                 h4("Select one of the most frequently used words in the Reddit thread"),
                 h6("Dependency graphs show words used in relation to frequent words"),
                 plotOutput("word_web")),
      )
    )
  )
)

server <- function(input, output) { 
  # Upload data using RedditExtractoR package
  url <- "https://www.reddit.com/r/chicago/comments/13wu8pw/adu_citywide_expansion_ordinance_introduced_to/"
  reddit <- get_thread_content(url)
  
  # Filter for comment text data
  reddit_comments <- reddit$comments
  reddit_comments <- reddit_comments$comment
  
  # Convert to lemmas and clean
  reddit_udpipe <- udpipe(reddit_comments, "english")
  reddit_lemma <- anti_join(reddit_udpipe, stop_words, by = c("lemma" = "word"))
  reddit_lemma <- reddit_lemma |>
    filter(!upos %in% c("PUNCT", "CCONJ"))
  
  # Create new lemma dataframe
  reddit_token <- reddit_lemma |>
    select("doc_id", "token", "lemma", "token_id", "head_token_id", "upos")
  
  # Aggregate text data
  reddit_aggregate <- reddit_token |>
    group_by(lemma) |>
    mutate(n_lemma = n()) |>
    ungroup() |>
    mutate(prop_lemma = n_lemma / sum(n_lemma)) |>
    distinct(lemma, .keep_all = TRUE)
  
  # Get sentiments
  sentiment_nrc <- get_sentiments("nrc") |>
    rename(nrc = sentiment)
  sentiment_afinn <- get_sentiments('afinn') %>%
    rename(afinn = value)
  
  # Functions to merge data
  merge_nrc <- function(df){
    df |>
      left_join(sentiment_nrc, by = c("lemma" = "word")) |>
      filter(!is.na(nrc))  
  }
  
  merge_afinn <- function(df){
    df |>
      left_join(sentiment_afinn, by = c("lemma" = "word")) |>
      filter(!is.na(afinn))
  }
  
  # Merge sentiments
  reddit_nrc <- merge_nrc(reddit_aggregate)
  reddit_afinn <- merge_afinn(reddit_aggregate)
  
  # Find summary statistics
  summary_table <- reactive({
    reddit_afinn |>
    summarize(median = median(afinn, na.rm = TRUE),
              mean = mean(afinn, na.rm = TRUE),
              stan_dev = sd(afinn, na.rm = TRUE),
              min = min(afinn, na.rm = TRUE),
              max = max(afinn, na.rm = TRUE))
  })
  
  output$sentiment_summary <- renderTable({
    summary_table()
    })
  
  # Plot nrc
  output$sentiment_graph <- renderPlot({
    reddit_nrc |>
    ggplot(aes(x = nrc)) +
    geom_bar(fill = "steelblue", color = "black") +
    scale_x_discrete(guide = guide_axis(angle = 45)) +
    geom_text(stat = 'count', 
              aes(label =..count..), 
              vjust = -0.5,
              size = 2.5) +
    labs(title = "Public Opinion of ADU Ordinance is \nOverwhelmingly Positive",
         subtitle = "While largely positive, ADU Ordinance backlash \nstill exists",
         y = "Count",
         x = "NRC Sentiment",
         caption = "Data collected from Chicago Sub-Reddit") +
    ylim(0, 102) +
    theme_bw()
  })
  
  # Functions for dependencies graphs
  children <- function(interested_word){
    reddit_lemma |>
      filter(lemma == interested_word) |>
      inner_join(reddit_lemma |> dplyr::select(doc_id, head_token_id, lemma),
                 by = c("token_id" = "head_token_id", "doc_id" = "doc_id")) |>
      dplyr::select(doc_id, lemma.y, lemma.x) |>
      rename(parent = lemma.x, children = lemma.y)
  }
  
  parent <- function(interested_word){
    reddit_lemma |>
      filter(lemma == interested_word) |>
      inner_join(reddit_lemma |> dplyr::select(doc_id, token_id, lemma),
                 by = c("head_token_id" = "token_id", "doc_id" = "doc_id")) |>
      dplyr::select(doc_id, lemma.y, lemma.x) |>
      rename(children = lemma.x, parent = lemma.y)
  }
  
  bigram <- function(children_df, parent_df){
    bigram_df <- rbind(children_df |> dplyr::select(doc_id, parent, children),
                       parent_df |> dplyr::select(doc_id, parent, children))
    
    bigram_counts <- bigram_df |>
      group_by(doc_id, parent, children) |> 
      summarize(n = n()) |>
      ungroup() |>
      arrange(desc(n)) |>
      head(40) # filtered for top 40 words to increase graph readability
    
    return(bigram_counts)
  }
  
  graph_bigram <- function(df){
    plot <- df |>
      dplyr::select(parent, children, n) |>
      graph_from_data_frame() 
    
    ggraph(plot, layout = "fr") + 
      geom_edge_link(aes(edge_alpha = n), show.legend = FALSE, 
                     arrow = arrow(length = unit(4, 'mm')), 
                     end_cap = circle(.07, 'inches')) +
      geom_node_point(color = "lightblue", size = 5) + 
      geom_node_text(aes(label = name), vjust = 1, hjust = 1)  + 
      theme_void() 
  }
  
  plot_web <- function(word){
    children_x <- children(word)
    parent_x <- parent(word)
    bigram_word <- bigram(children_x, parent_x)
    graph <- graph_bigram(bigram_word)
    return(graph)
  }
  
  chosen_word <- reactive({
    input$select_word
  })
  
  output$word_web <- renderPlot({
    plot_web(chosen_word())
  })
}

shinyApp(ui = ui, server = server)






