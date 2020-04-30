#' A function to search Planet imagery
#'
#' This function allows you to search the Planet API
#' @param bbox shapefile of bounding box must be EPSG:4326 Projection; no default.
#' @param date_end Expects as.Date; defaults to as.Date('2018-07-01')
#' @param date_start Expects as.Date; defaults to as.Date('2018-08-01')
#' @param cloud_lim Cloud percentage from 0-1; defaults to 0.1, or 10%.
#' @param item_name Defaults to "PSOrthoTile".
#' @keywords Planet
#' @export
#' @examples
#' planet_search()

####
#### Code from https://www.lentilcurtain.com/posts/accessing-planet-labs-data-api-from-r/
####

library(httr)
library(jsonlite)

planet_search <- function(bbox ,
                          date_end = as.Date('2018-07-01'),
                          date_start = as.Date('2018-08-01'),
                          cloud_lim = 0.1,
                          item_name = "PSOrthoTile")

  {

  #convert shapefile to geojson
  #shapefile of bounding box must be EPSG:4326 Projection
  geo_json_geometry <- list(
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


  # filter for items the overlap with our chosen geometry
  geometry_filter <- list(
    type= jsonlite::unbox("GeometryFilter"),
    field_name= jsonlite::unbox("geometry"),
    config= geo_json_geometry
  )

  #we will search for images for up to a month beforethe date we are interested in

  dategte <- paste0(date_start,"T00:00:00.000Z")
  datelte <- paste0(date_end,"T00:00:00.000Z")

  # filter images by daterange
  date_range_filter <- list(
    type= jsonlite::unbox("DateRangeFilter"),
    field_name= jsonlite::unbox("acquired"),
    config= list(
      gte= jsonlite::unbox(dategte),
      lte= jsonlite::unbox(datelte))
  )


  # filter by cloud cover
  cloud_cover_filter <- list(
    type= jsonlite::unbox("RangeFilter"),
    field_name= jsonlite::unbox("cloud_cover"),
    config = list(
      lte= jsonlite::unbox(cloud_lim))
  )

  # combine filters
  filter_configs <- list(
    type= jsonlite::unbox("AndFilter"),
    config = list(date_range_filter, cloud_cover_filter,geometry_filter) #, coverage_filter
  )

  #build request
  search_endpoint_request <- list(
    item_types = item_name,
    filter = filter_configs
  )

  #convert request to JSON
  body_json <- jsonlite::toJSON(search_endpoint_request,pretty=TRUE)

  #API request config
  url <- 'https://api.planet.com/data/v1/quick-search'
  body <- body_json

  #send API request
  request <- httr::POST(url, body = body, content_type_json(), authenticate(api_key, ""))

  resDF <- fromJSON(httr::content(request, as = "text"))
  res <- resDF
  resDFid <- data.frame(id =resDF$features$id)


  while(is.null(res$`_links`$`_next`)==FALSE){
    request <- httr::GET(httr::content(request)$`_links`$`_next`, content_type_json(), authenticate(api_key, ""))
    res <- fromJSON(httr::content(request, as = "text"))
    resID = res$features$id
    resDFid <- rbind(resDFid, data.frame(id = resID))
    }


  response_doy <- as.numeric(
    format(
      as.Date.character(
        str_split_fixed(
          resDFid$id,
          pattern = "_",n = 2)[,1],
        format = "%Y%m%d"),
      format = "%j")
  )

  response_doy <- (response_doy > start_doy & response_doy < end_doy)

  resDFid_doy <- data.frame(resDFid[response_doy,])

  print(paste(nrow(resDFid),"images ... between", date_start, "and", date_end))
  print(paste(nrow(resDFid_doy),"images ... that meet all criteria"))

  return(resDFid_doy)
}

