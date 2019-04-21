
  library(mapedit)
  library(leaflet)
  library(tidyverse)
  library(lubridate)
  library(jsonlite)
  library(sf)
  library(sp)
  library(XML)
  library(dplyr)
  library(raster)
  library(plotly)
  library(geojsonsf)
  library(httr)
  library(mapview)
  library(here)

  #### VARIABLES: Set variables for Get_Planet function ####

  # Set API

  # Date range of interest
  start_year = 2018
  end_year   = 2018
  start_doy  = 250
  end_doy    = 300

  # Metadata filters
  cloud_lim    = 0.1 #less than
  cover_lim    = 0.01 #greater than
  item_names   = c("PSOrthoTile") #PSScene4Band")#,"PSScene3Band") #c(#c("Sentinel2L1C") #"PSOrthoTile"
  products     = c("analytic")#c("analytic_b1","analytic_b2")

  my_aoi = read_sf("ExampleCode/Polygons.sqlite")
  polys = c("Polygon3")

  for(poly in polys){
  my_aoi = my_aoi %>% filter(aoi == poly)
  # write_sf(my_aoi, "test.kml")
  bbox <- extent(my_aoi)
  # plot(bbox)

  # Ourput variables
  project      = paste0("Larch_",poly)
  downloads    = "C:/Users/bevington/Planet_Downloads"
  setwd(downloads)
  dir.create(project)
  setwd(project)

  #### FUNCTION 1: Get a list of planet images that meet criteria ####


  #### FUNCTION 2: Batch activate all assets in the list  ####


  #### FUNCTION 3: Batch download activated assets (may take a few minutes until activated, and a few minustes to download)  ####


  #### LOOP ####

  for(item_name in item_names){
    for(product in products){

      print(item_name)
      print(product)

      folder      = paste(format(today(),"%Y%M%d_%H%m"),project,start_year,end_year,start_doy,end_doy, item_name, product, "c", cloud_lim, "v", cover_lim, sep="_")
      setwd(paste0(downloads,"/",project,"/"))
      dir.create(folder)
      setwd(paste0(downloads,"/",project,"/",folder))

      for(year in seq(start_year,end_year,1)){
        date_start = as.Date(paste0(year,"-01-01"))+start_doy
        date_end   = as.Date(paste0(year,"-01-01"))+end_doy

        print(year)

        #### FUNCTION 4: ORDERS v2

        # https://planet-platform.readme.io/docs/api-examples
        #
        # orders_url = "https://api.planet.com/compute/ops/orders/v2/"
        # prods = list(item_ids  = "20151119_025740_0c74",
        #              item_types      = jsonlite::unbox(item_name),
        #              product_bundle = jsonlite::unbox(product))
        # order = list(
        #   name = jsonlite::unbox("test"),
        #   products = prods)
        # body <- jsonlite::toJSON(order, pretty = T); body
        #
        # request <- httr::POST(url = orders_url, body = body,  content_type_json(), authenticate(api_key, ""))
        # print(content(request))
        #
        #
        # content(POST(url, body = body, content_type_json(), authenticate(api_key, "")))
        #




      #### PROCESSING: Call API ####

          response <- get_planet(bbox, date_end, date_start, cloud_lim, cover_lim, item_name)
          print(paste("Images available:",length(response$features), item_name, product))

      #### PROCESSING: Batch Activate ####
      if(length(response$features) == 0)
      {print("No images")}
      if(length(response$features) > 0)
      {

      for(i in 1:length(response$features)) {
        activate_planet_from_response(i)
        print(paste("Activating", i, "of", length(response$features)))}

        print("wait 20 seconds")
        Sys.sleep(20)

      #### PROCESSING: Batch Download ####

      for(i in 1:length(response$features)) {
        download_planet_from_response(i)
        print(paste("Downloading", i, "of", length(response$features)))}


    }}}}



          # Create AOI
          # lat         = 50.407621
          # lat.offset  = 0.002
          # lon         = -126.315961
          # lon.offset  = 0.002
          # my_aoi<-raster(nrows=100, ncols=100, xmn=lon-lon.offset, xmx=lon+lon.offset, ymn=lat-lat.offset, ymx=lat+lat.offset)
  }
