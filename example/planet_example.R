# remotes::install_github("bevingtona/planetR", force = T)
library(planetR)
library(here)
library(raster)
library(httr)

#### VARIABLES: Set variables for Get_Planet function ####

# Set API
setwd(here())
api_key = as.character(read.csv("C:/Users/bevington/Dropbox/FLNRO_p1/Programming/bevirepo/api.csv")$api)

# Date range of interest
start_year = 2018
end_year   = 2018
start_doy  = 250
end_doy    = 300
date_start = as.Date(paste0(start_year,"-01-01"))+start_doy
date_end   = as.Date(paste0(end_year,"-01-01"))+end_doy

# Metadata filters
cloud_lim    = 0.1 #less than
item_name    = "PSOrthoTile" #PSScene4Band")#,"PSScene3Band") #c(#c("Sentinel2L1C") #"PSOrthoTile"
product      = "analytic" #c("analytic_b1","analytic_b2")

# Set AOI
my_aoi       = read_sf("") # Import from KML or other
my_aoi       = mapedit::editMap() # Set in GUI
bbox         = extent(my_aoi)

#### PLANET_SEARCH: Search API ####

response <- planet_search(bbox, date_end, date_start, cloud_lim, item_name)
print(paste("Images available:", length(response$features), item_name, product))

#### PLANET_ACTIVATE: Batch Activate ####

for(i in 1:length(response$features)) {
  planet_activate(i)
  print(paste("Activating", i, "of", length(response$features)))}
   
#### PLANET_DOWNLOAD: Batch Download ####
  
for(i in 1:length(response$features)) {
  planet_download(i)
  print(paste("Downloading", i, "of", length(response$features)))}
  