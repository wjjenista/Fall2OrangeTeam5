library(jsonlite)
library(tidyverse)

#Import business.json file 

business <- 'C:\\Users\\Melissa Sandahl\\Desktop\\yelp_academic_dataset_business.json'
bus_data <- stream_in(file(business))

# check structure: some variables are dataframes themselves
str(bus_data)

#flatten to remove secondary dataframe structure from variables
bus_flat <- jsonlite::flatten(bus_data)
str(bus_flat)

#export to csv

write_csv(bus_flat, path = "yelp_businesses.csv")


# Once CSV files are written, import data from here
business <- read_csv("C:\\Users\\Melissa Sandahl\\Desktop\\yelp_businesses.csv")
reviews <- read_csv("C:\\Users\\Melissa Sandahl\\Desktop\\yelp_academic_dataset_review.csv")

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

