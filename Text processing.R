library(tidyverse)
library(tidytext)
library(textdata)
library(sentimentr)
library(rvest)
library(RedditExtractoR)
library(udpipe)

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
