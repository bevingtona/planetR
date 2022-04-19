#' A function to search Planet imagery
#'
#' This function allows you to search the Planet API
#' @param bbox bounding box made with extent() from the raster package; must be EPSG:4326 Projection; no default.
#' @param date_end Expects as.Date; defaults to as.Date('2018-07-01')
#' @param date_start Expects as.Date; defaults to as.Date('2018-08-01')
#' @param cloud_lim Cloud percentage from 0-1; defaults to 0.1, or 10%.
#' @param ground_control Defaults to TRUE, filter images to only those with ground control, ensures locational accuracy of 10 m RMSE or better
#' @param quality Defaults to "standard", other option is "test" see https://support.planet.com/hc/en-us/articles/4407808871697-Image-quality-Standard-vs-Test-imagery
#' @param item_name Defaults to "PSOrthoTile".
#' @param api_key your planet api key string
#' @keywords Planet
#' @export
#' @examples
#' planet_search()

####
#### Code from https://www.lentilcurtain.com/posts/accessing-planet-labs-data-api-from-r/
####

library(httr)
library(jsonlite)


planet_search <- function(bbox,
                          date_end = NULL,
                          date_start = NULL,
                          cloud_lim = 0.1,
                          ground_control = TRUE,
                          quality = "standard",
                          item_name = "PSOrthoTile",
                          asset = "ortho_analytic_8b_sr" ,
                          api_key = "test",
                          list_dates = NULL)

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
  if(is.null(list_dates)==FALSE){

    dategte <- paste0(min(list_dates),"T00:00:00.000Z")
    datelte <- paste0(max(list_dates),"T00:00:00.000Z")

  }else{

    dategte <- paste0(date_start,"T00:00:00.000Z")
    datelte <- paste0(date_end,"T00:00:00.000Z")
  }

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

  # filter by ground control
  gc_filter <- list(
    type= jsonlite::unbox("NotFilter"),
    config = list(
      field_name= jsonlite::unbox("ground_control"),
      type= jsonlite::unbox("StringInFilter"),
      config = list(jsonlite::unbox(tolower(!ground_control)))
    )
  )

  # filter by quality
  quality_filter <- list(
    type = jsonlite::unbox("NotFilter"),
    config = list(
      field_name= jsonlite::unbox("quality_category"),
      type= jsonlite::unbox("StringInFilter"),
      config = list(jsonlite::unbox(quality))
    )
  )

  # combine filters
  filter_configs <- list(
    type= jsonlite::unbox("AndFilter"),
    config = list(date_range_filter, cloud_cover_filter, gc_filter, quality_filter, geometry_filter) #, coverage_filter
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
  # Read first page
  res <- fromJSON(httr::content(request, as = "text", encoding = "UTF-8"))

  check_permission <- function(res){

    # Check Permissions
    permissions <- do.call(rbind, lapply(1:length(res$features$`_permissions`),function(i){

      permissions <- stringr::str_split(res$features$`_permissions`[[i]], ":", simplify = T)
      permissions <- data.frame(id = res$features$id[i],
                                i = i,
                                asset = gsub("assets.","",permissions[,1]),
                                permission = permissions[,2])
      return(permissions)}))

    resDFid <- permissions[permissions$asset==asset,]
    resDFid[resDFid$permission=="download",]
    }

  permissions <- check_permission(res)

  # Read following pages, if exist
  while(is.null(res$`_links`$`_next`)==FALSE){
    request <- httr::GET(httr::content(request)$`_links`$`_next`, content_type_json(), authenticate(api_key, ""))
    res <- fromJSON(httr::content(request, as = "text", encoding = "UTF-8"))
    if(is.null(unlist(res$features))==FALSE){
      permissions <- rbind(permissions, check_permission(res))
    }
    }

  permissions <- permissions[!is.na(permissions$id),]

  if(unique(permissions$permission) == "download"){
    print(paste("You have DOWNLOAD permissions for these images."))

  permissions$date = as.Date.character(permissions$id,format = "%Y%m%d")
  permissions$yday = as.numeric(format(permissions$date, "%j"))

  if(is.null(list_dates)==FALSE){

    permissions <- permissions[permissions$date %in% list_dates,]
    print(paste("Found",nrow(permissions),"suitable",item_name, asset, "images that you have permission to download."))
    print(paste("In list of",length(list_dates), "dates from", min(list_dates),"to", max(list_dates)))

  }else{

    start_doy <- lubridate::yday(date_start)
    end_doy <- lubridate::yday(date_end)

    permissions <- permissions[permissions$yday>=start_doy & permissions$yday<=end_doy,]
    print(paste("Found",nrow(permissions),"suitable",item_name, asset, "images that you have permission to download."))
    print(paste("Between yday:", start_doy, "to", end_doy))

  }

  if(nrow(permissions)>0){
    return(permissions$id)}else{
      print(paste("You DO NOT have DOWNLOAD permissions for these images. You have", toupper(unique(permissions$permission)), "permission"))
    }
  }
}
