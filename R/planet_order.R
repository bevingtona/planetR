##PlanetR search + Orders API for download

planet_order <- function(aoi_dir = "/Users/DataLab/Desktop/Wine Project/SMV2.geojson",
                         start_year = 2021,
                         start_doy = 158,
                         end_year = 2021,
                         end_doy = 160,
                         cloud_lim = 0.1,
                         item_name = "PSScene4Band",
                         product  = "analytic_sr",
                         order = "AutomationTEST"){

#remotes::install_github("bevingtona/planetR", force = T)
#install.packages(c("here", "httr", "jsonlite", "raster","stringr"))

library(sf)
library(planetR)
library(here)
library(httr)
library(jsonlite)
library(raster)
library(stringr)


# insert api key here
api_key = "" 

#Create filters for PlanetR search

# Date range of interest
# Date range of interest

date_start = as.Date(paste0(start_year,"-01-01"))+start_doy
date_end   = as.Date(paste0(end_year,"-01-01"))+end_doy


# Set AOI - will be used to find all images that include AOI, later used to clip in Orders API
my_aoi  = read_sf(aoi_dir)
bbox    = extent(my_aoi)


#SEARCH FOR IMAGES

#uses the quick search url (more info: https://developers.planet.com/docs/apis/data/reference/#tag/Item-Search)
response <- planet_search(bbox, date_end, date_start, cloud_lim, item_name)

#ORDER API

items = response$resDFid.response_doy...[1:nrow(response)]
products = list(list(item_ids = items, item_type = unbox(item_name), product_bundle = unbox(product)))

aoi = list(
  type=jsonlite::unbox("Polygon"),
  coordinates = list(list(
    c(bbox@xmin,
      bbox@ymin),
    c(bbox@xmin,
      bbox@ymax),
    c(bbox@xmax,
      bbox@ymax),
    c(bbox@xmax,
      bbox@ymin),
    c(bbox@xmin,
      bbox@ymin)
  ))
)

#json structure needs specific nesting, double nested for tools hence the list(list())
clip = list(aoi = aoi)
tools <-  list(list(clip = clip))

#Build request body and convert to json
order_name = unbox(order)
order_body <- list(name = order_name, products = products, tools = tools)
order_json <- toJSON(order_body, pretty = TRUE)

url = "https://api.planet.com/compute/ops/orders/v2"

#Sent request (will make order, NOT REVERSIBLE, will show up on planet account)
request <- POST(url, body = order_json, content_type_json(), username = api_key)

#request content
post_content <- content(request)
order_id <- post_content$id

#GET order for download
#If you lose the order_id, don't redo the request, log onto planet and find it in the orders menu
#order_id for example SMV2 order: "dab92990-ce3a-456c-8ad6-ca0c569b4a1a"
url2 = paste0("https://api.planet.com/compute/ops/orders/v2/", order_id)

get_order <- GET(url = url2, username = api_key)
#Download links are in here, under _links>results>location
get_content <- content(get_order)
#When state = 'success', ready for download

#check if order is ready
while(get_content$state != "success"){
  print("Order still being proccessed, trying again in 60 seconds...")
  Sys.sleep(60)
  get_order <- GET(url = url2, username = api_key)
  get_content <- content(get_order)
}

##Time to download!

#First create download folder:
dir.create(order_name, showWarnings = TRUE)

#Download each item in order
for(i in 1:length(get_content$`_links`$results)){
  
  #find item names in order contents
  name <- get_content$`_links`$results[[i]]$name
  findslash <- gregexpr("/", name)
  startchar <- findslash[[1]][length(findslash[[1]])] + 1
  filename <- substr(name, startchar, nchar(name))
  
  download_url <- get_content$`_links`$results[[i]]$location
  RETRY("GET",url = download_url, username = api_key, write_disk(path = paste(order_name, filename, sep = "/"), overwrite = TRUE))
  
}

print(paste0("Download complete, items located in ", getwd(), "/", order_name))

}

# call function (you may have to change order name to one that hasn't already been used)
planet_order(order = "AutomationTEST_1")



