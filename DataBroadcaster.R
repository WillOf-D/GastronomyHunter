


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



# Get Latest Data

twitter_extraction <- mongo(db = "dataset_R", # Creating DataBase
                            url = connection_string, 
                            verbose = TRUE)


latest_entry <- head(sort(as.data.frame(
  twitter_extraction$run(
            '{"listCollections":1}')$cursor)[,3], 
        decreasing = TRUE
        ),
     1)

latest_collection <- mongo(collection = latest_entry, # Creating collection
                           db = "dataset_R", # Creating DataBase
                           url = connection_string, 
                           verbose = TRUE)


d <- latest_collection$find()


## 1st Hashtag
samp_word <- "GastronomyHunter"


# Latest Status
status_details <- paste0(
  "Hello, Hunters!", 
  "\n", 
  "\n",
  "This is a tweet post for my assigment. ",
  "You will find in the embedded picture, the most frequent words that is mentioned recently with cakes, desserts, cookies, etc. ",
  "Hope you find some inspirations for your next baking adventure! ",
  "\n",
  "\n",
  "Adios,,",
  "\n",
  "#", 
  samp_word
  )

status_details <- as.character(status_details) 

# Latest Chart
library(ggplot2)
library(ggwordcloud)
library(RColorBrewer)
pic <- ggwordcloud(words = d$word, freq = d$freq, min.freq = 111,
          max.words=99, random.order=FALSE, rot.per=0.45, 
          colors=brewer.pal(8, "Dark2"))

pic_file <- tempfile( fileext = ".png")
ggsave(pic_file, plot = pic, device = "png", dpi = 144, width = 8, height = 8, units = "in" )


# Publish to Twitter
library(rtweet)

## Create Twitter token
twitter_token <- create_token(
  app = "GastroHunter",
  consumer_key =    Sys.getenv("TWITTER_CONSUMER_API_KEY"), 
  consumer_secret = Sys.getenv("TWITTER_CONSUMER_API_SECRET"), 
  access_token =    Sys.getenv("TWITTER_ACCESS_TOKEN"), 
  access_secret =   Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET")
)

## Post the tweet to Twitter
rtweet::post_tweet(
  status = status_details,
  media = pic_file,
  token = twitter_token
)


rm(twitter_extraction)
rm(latest_collection)
gc()
