# remotes::install_github("bevingtona/planetR", force = T)
library(planetR)
library(here)
library(httr)
library(jsonlite)

#### VARIABLES: Set variables for Get_Planet function ####

# Site name
site = "MySite"

# Set Workspace (optional)
setwd("")

# Set API (manually in the script or in a attached file)
api_key = ""
api_key = as.character(read.csv("../api.csv")$api)

# Date range of interest
start_year = 2018
end_year   = 2018
start_doy  = 250
end_doy    = 300
date_start = as.Date(paste0(start_year,"-01-01"))+start_doy
date_end   = as.Date(paste0(end_year,"-01-01"))+end_doy

# Metadata filters
cloud_lim    = 0.1 #less than
item_name    = "PSScene4Band" #PSOrthoTile")#,"PSScene3Band") #c(#c("Sentinel2L1C") #"PSOrthoTile"
product      = "analytic_sr" #c("analytic_b1","analytic_b2")

# Set AOI
# my_aoi       = read_sf("") # Import from KML or other
# my_aoi       = mapedit::editMap() # Set in GUI
# bbox         = extent(my_aoi)
bbox         = extent(-129,-127,50,51)

# Set/Create Export Folder (optional)
exportfolder = paste(site, item_name, product, start_year, end_year, start_doy, end_doy, sep = "_")
dir.create(exportfolder, showWarnings = F)

#### PLANET_SEARCH: Search API ####

response <- planet_search(bbox, date_end, date_start, cloud_lim, item_name)
print(paste("Images available:", nrow(response), item_name, product))

#### PLANET_ACTIVATE: Batch Activate ####

for(i in 1:nrow(response)) {
  planet_activate(i, item_name = item_name)
  print(paste("Activating", i, "of", nrow(response)))}

#### PLANET_DOWNLOAD: Batch Download ####

for(i in 1:nrow(response)) {
  planet_download(i)
  print(paste("Downloading", i, "of", nrow(response)))}
