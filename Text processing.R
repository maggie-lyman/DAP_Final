library(tidyverse)
library(tidytext)
library(textdata)
library(sentimentr)
library(rvest)

url <- "https://www.reddit.com/r/chicago/comments/13wu8pw/adu_citywide_expansion_ordinance_introduced_to/"
response <- read_html(url)

node <- response |>
  html_elements("p")

public_opinion <- html_text(node)

public_opinion_df <- data.frame(text = public_opinion)

token_df <- unnest_tokens(public_opinion_df, word_tokens,  text, token = "words")

anti_join(token_df, stop_words, by = c("word_tokens" = "word"))

## Check in office hours --> why is this only selecting "Chicago Illinois" and not all text?

