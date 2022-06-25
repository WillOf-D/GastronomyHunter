# Create API Database MongoDB

library(mongolite)

connection_string <- paste(
  sep = "",
  'mongodb+srv://',
  Sys.getenv("MONGO_USERNAME"),
  ':',
  Sys.getenv("MONGO_PASSWORD"),
  '@clustertest01.iaoip.mongodb.net/?retryWrites=true&w=majority'
)


# Ambil Data Twitter
library(rtweet)
library(tm)
library(tidytext)
library(dplyr)
library(stringr)


twitter_token <- create_token(
  app = "GastroHunter",
  consumer_key =    Sys.getenv("TWITTER_CONSUMER_API_KEY"), 
  consumer_secret = Sys.getenv("TWITTER_CONSUMER_API_SECRET"), 
  access_token =    Sys.getenv("TWITTER_ACCESS_TOKEN"), 
  access_secret =   Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET")
)

search_keywords <- paste(
  sep = " OR ",
  "#bread",
  "#cookie",
  "#sweets",
  "#dessert",
  "#fruit",
  "#baking",
  "#pie"
)

tweets <- search_tweets(
  search_keywords,
  n = 10000,
  include_rts = TRUE,
  lang = "en",
  token = twitter_token,
  retryonratelimit = TRUE
)


text <- str_c(tweets$text, collapse = " ")

docs <- Corpus(VectorSource(text))

toSpace <- content_transformer(function (x , pattern ) gsub(pattern, " ", x))
docs <- tm_map(docs, toSpace, "/")
docs <- tm_map(docs, toSpace, "@")
docs <- tm_map(docs, toSpace, "\\|")
docs <- tm_map(docs, toSpace, "cook")
docs <- tm_map(docs, toSpace, "foodie")
docs <- tm_map(docs, toSpace, "blogger")
docs <- tm_map(docs, toSpace, "pride")
docs <- tm_map(docs, content_transformer(tolower))
docs <- tm_map(docs, removeNumbers)
docs <- tm_map(docs, removeWords, stopwords("english"))
docs <- tm_map(docs, removePunctuation)
docs <- tm_map(docs, stripWhitespace)
docs <- tm_map(docs, removeWords,
               c( "amp",
                  "https",
                  "tco",
                  "fuck", 
                  "suck", 
                  "fruit", 
                  "dessert", 
                  "sweets", 
                  "bread", 
                  "cookie", 
                  "recipe", 
                  "recipes",
                  "food", 
                  "baking", 
                  "today", 
                  "foodie",
                  "foodies",
                  "cooking", 
                  "cook", 
                  "make", 
                  "blogger", 
                  "new", 
                  "now"
              )
)


dtm <- TermDocumentMatrix(docs)
m <- as.matrix(dtm)
v <- sort(rowSums(m),decreasing=TRUE)
d <- data.frame(word = names(v),freq=v)
d <- head(d, 1000)

entry_name <- paste(
  sep = "_",
  format(Sys.time(), "%Y_%m_%d_%H_%M")
)

twitter_collection <- mongo(collection = entry_name, # Creating collection
                            db = "dataset_R", # Creating DataBase
                            url = connection_string, 
                            verbose = TRUE)

twitter_collection$insert(d)

rm(twitter_collection)
gc()
