#### STEP 1: LIBRARIES ####

# remotes::install_github("bevingtona/planetR", force = T)
# install.packages(c("here", "httr", "jsonlite", "raster"))

library(planetR)
library(here)
library(httr)
library(jsonlite)
library(raster)
library(stringr)

#### STEP 2: USER VARIABLES: Set variables for Get_Planet function ####

# Site name that will be used in the export folder name
site = "Kiwa"

# Set Workspace (optional)
setwd("")

# Set API (manually in the script or in a attached file)
api_key = as.character(read.csv("../api.csv")$api) # OPTION 1
# api_key = "" # OPTION 2

# Date range of interest
start_year = 2016
end_year   = 2020
start_doy  = 290
end_doy    = 300
date_start = as.Date(paste0(start_year,"-01-01"))+start_doy
date_end   = as.Date(paste0(end_year,"-01-01"))+end_doy

# Metadata filters
cloud_lim    = 0.02 # percent scaled from 0-1
item_name    = "PSScene4Band" #PSOrthoTile")#,"PSScene3Band") #c(#c("Sentinel2L1C") #"PSOrthoTile"
product      = "analytic_sr" #c("analytic_b1","analytic_b2")

# Set AOI (many ways to set this!) Ultimately just need an extent()
# my_aoi       = read_sf("") # Import from KML or other
my_aoi       = mapedit::editMap() # Set in GUI
bbox         = extent(my_aoi)
# bbox         = extent(-129,-127,50,51)

# Set/Create Export Folder (optional)
exportfolder = paste(site, item_name, product, start_year, end_year, start_doy, end_doy, sep = "_")
dir.create(exportfolder, showWarnings = F)

#### STEP 3: PLANET_SEARCH: Search API ####

response <- planet_search(bbox, date_end, date_start, cloud_lim, item_name)
print(paste("Images available:", nrow(response), item_name, product))


#### STEP 4: PLANET_ACTIVATE: Batch Activate ####

for(i in 1:nrow(response)) {
  planet_activate(i, item_name = item_name)
  print(paste("Activating", i, "of", nrow(response)))}

#### STEP 5: PLANET_DOWNLOAD: Batch Download ####

for(i in 1:nrow(response)) {
  planet_download(i)
  print(paste("Downloading", i, "of", nrow(response)))}
