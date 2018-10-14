library(jsonlite)
#install.packages('tidyverse')
library(tidyverse)
library(dplyr)

#Import business.json file 

#business <- 'C:\\Users\\Melissa Sandahl\\Desktop\\yelp_academic_dataset_business.json'
business = "C:\\Users\\rnwyn\\OneDrive\\Documents\\Text Mining\\yelp_academic_dataset_business.json"
bus_data <- stream_in(file(business))

# check structure: some variables are dataframes themselves
str(bus_data)

#flatten to remove secondary dataframe structure from variables
bus_flat <- jsonlite::flatten(bus_data)
str(bus_flat)

#export to csv

write_csv(bus_flat, path = "yelp_businesses.csv")


# Once CSV files are written, import data from here
# business <- read_csv("C:\\Users\\Melissa Sandahl\\Desktop\\yelp_businesses.csv")
# reviews <- read_csv("C:\\Users\\Melissa Sandahl\\Desktop\\yelp_academic_dataset_review.csv")
reviews = read_csv("C:\\Users\\rnwyn\\OneDrive\\Documents\\Text Mining\\yelp_academic_dataset_review.csv")
business = read_csv("C:\\Users\\rnwyn\\OneDrive\\Documents\\Text Mining\\yelp_businesses.csv")

# filter for businesses in NC, remove entries not in Charlotte area 
# Non-charlotte locations found by mapping businesses in Tableau

nc_businesses <- business %>%
  filter(state=='NC') %>%
  filter(!city %in% c('Fairview', 'Stoney Creek', 'Waterford'))

# save this dataset
write_csv(nc_businesses, path = "yelp_nc_businesses.csv")


# filter reviews for businesses in nc_businesses$business_id
keep <- nc_businesses$business_id
nc_reviews <- reviews %>%
  filter(business_id %in% keep)

#save this dataset. File size down to 230MB!
write_csv(nc_reviews, path = "yelp_nc_reviews.csv")


###############################
#Open new working files
nc_reviews = read_csv("C:\\Users\\rnwyn\\OneDrive\\Documents\\Text Mining\\yelp_nc_reviews.csv")
nc_businesses = read_csv("C:\\Users\\rnwyn\\OneDrive\\Documents\\Text Mining\\yelp_nc_businesses.csv")


#Filter categories variable in business dataset to only thos including Food and Restaurants. Had to Exclude those listed as Grocery.
keep_c = nc_businesses %>%
  filter(grepl('Food|Restaurant', categories) & !grepl('Grocery', categories))
keep_categories = keep_c$business_id

#Filter nc_reviews off those categories to include only reviews on restaurants
nc_food_reviews <- nc_reviews %>%
  filter(business_id %in% keep_categories)

#write this dataset. File down to 158MB
write_csv(nc_food_reviews, path = "yelp_nc_food_reviews.csv")


#Filtering the reviews for those talking about parking
nc_food_reviews_parking = nc_food_reviews %>%
  filter(grepl('park|Park', text))

#writing this dataset. File down to 13.3 MB. 13,515 observations. 
write_csv(nc_food_reviews_parking, path = "yelp_nc_parking_reviews.csv")

#reopening these
nc_businesses = read_csv('yelp_nc_businesses.csv')
nc_food_reviews = read_csv('yelp_nc_food_reviews.csv')
nc_parking = read_csv('yelp_nc_parking_reviews.csv')

#joining the business dataset with the reviews dataset
food_bus_reviews = right_join(nc_businesses,nc_food_reviews, by = 'business_id')
parking_food_bus_reviews = right_join(nc_businesses,nc_parking, by = 'business_id')


