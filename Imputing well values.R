# Imputing missing hours in well data #############

install.packages("imputeTS")
library(imputeTS)
library(readxl)
library(tidyverse)
library(lubridate)

file.dir <- "C:\\Users\\Melissa Sandahl\\OneDrive\\Documents\\School\\MSA courses\\AA502\\Data Viz\\Well_Data\\Well Data\\G-2866_T.xlsx"

well <- read_excel(file.dir, sheet=3)

# Aggregate by hour

well2 <- well %>%
  mutate(time_2 = hour(time)) %>% 
  unite(datetime, date, time_2, sep = " ", remove = FALSE) %>%
  mutate(datetime = ymd_h(datetime)) %>%
  select(datetime, depth = Corrected) 

well3 <- well2 %>% 
  group_by(datetime) %>% 
  summarise(well_avg = mean(depth))



# Create sequence of dates by hour

datetime <- seq(ymd_h("2007-10-01 01"), ymd_h("2018-06-12 23"), by = '1 hour')
datetime <- as.data.frame(datetime)

# Join sequence with well data to find missing hours
well4 <- well3 %>%
  right_join(datetime)


#Impute missing hours
well4$imputed <- na.kalman(well4$well_avg)


#Plot data with imputed values
ggplot(well4, aes(datetime, imputed)) +
  geom_line(color = "blue") +
  theme_bw() +
  labs(x = "Date And Time (in hours)", y = "Avg Depth of Well (in feet)", 
       title = "Avg Depth of Well From 2007-2018")

#Write data to csv
write_csv(well4, path= "well_imputed.csv")
