library(tidyverse)
library(tidytext)
library(textdata)
library(sentimentr)
library(rvest)
library(RedditExtractoR)
library(udpipe)
library(igraph)
library(ggraph)

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

# Aggregate to identify top words/lemmas
reddit_token |> 
  group_by(lemma) |>
  summarize(n = n()) |>
  arrange(desc(n))

# Common words include housing, city, ordinance, and Chicago --> see what is being said about Chicago/city and ordinance
reddit_token |>
  filter(lemma %in% c("Chicago", "city", "ordinance", "housing"))

# Token IDs
# Housing = 4
# city = 23
# ordinance = 2
# Chicago = 5

# Find what they are saying about Chicago/city
reddit_token |>
  filter(head_token_id %in% c(23, 5)) |>
  group_by(lemma) |>
  summarize(n = n()) |>
  arrange(desc(n)) # No strong language pops out at me

# Find what they are saying about the ordinance
reddit_token |>
  filter(head_token_id == 2) |>
  group_by(lemma) |>
  summarize(n = n()) |>
  arrange(desc(n)) # No strong language 

# Find what they are saying about housing
reddit_token |>
  filter(head_token_id == 4) |>
  group_by(lemma) |>
  summarize(n = n()) |>
  arrange(desc(n)) # No strong language

# Idea: create a shiny that is interactive that allows user to select top 5 words to create word plot to see what is being said
# Include overall afinn statistics, too

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

# Aggregate text data
reddit_aggregate <- reddit_token |>
  group_by(lemma) |>
  mutate(n_lemma = n()) |>
  ungroup() |>
  mutate(prop_lemma = n_lemma / sum(n_lemma)) |>
  distinct(lemma, .keep_all = TRUE)

# Merge sentiments
reddit_nrc <- merge_nrc(reddit_aggregate)
reddit_afinn <- merge_afinn(reddit_aggregate)

# Find summary statistics
summary(reddit_afinn$afinn) # skews positive but there is a full range

# Plot nrc
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

## Dependencies
# Functions to find children and parents 
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

# Bigrams
bigram <- function(children_df, parent_df){
  bigram_df <- rbind(children_df |> dplyr::select(doc_id, parent, children),
                     parent_df |> dplyr::select(doc_id, parent, children))
  
  bigram_counts <- bigram_df |>
    group_by(doc_id, parent, children) |> 
    summarize(n = n()) |>
    ungroup() |>
    arrange(desc(n))
  
  return(bigram_counts)
}


bigram(ordinance_ch, ordinance_pa)

bigram_city <- bigram(city_ch, city_pa)

bigram_city |>
  distinct(doc_id)


graph_city <- bigram_city %>%  dplyr::select(parent, children, n) %>%
  graph_from_data_frame() 

ggraph(bigram_graph, layout = "fr") + 
  geom_edge_link(aes(edge_alpha = n), show.legend = FALSE, arrow = arrow(length = unit(4, 'mm')), end_cap = circle(.07, 'inches')) +
  geom_node_point(color = "lightblue", size = 5) + geom_node_text(aes(label = name), vjust = 1, hjust = 1)  + theme_void()

# Find children and parents
ordinance_ch <- children("ordinance")
ordinance_pa <- parent("ordinance")

city_ch <- children("city")
city_pa <- parent("city")

chicago_ch <- children("Chicago")
chicago_pa <- parent("Chicago")

housing_ch <- children("housing")
housing_pa <- parent("housing")


