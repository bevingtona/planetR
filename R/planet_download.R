#' A function to download activated Planet imagery
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

library(httr)
library(jsonlite)

planet_download = function(i)
{

  url <- paste0("https://api.planet.com/data/v1/item-types/",item_name,"/items/",response$features[[i]]$id)
  # print(url)

  # GET BASICS ASSET

  get <- GET(url, content_type_json(), authenticate(api_key, ""))

  if(get$status_code == 429){
    print(paste("Status code:", get$status_code, "rate limit error: poll"))}
  if(get$status_code == 200){
    print(paste("Status code:", get$status_code, "authenticated"))}
  if(get$status_code == 404){
    print(paste("Status code:", get$status_code, "error"))}

  # PARSE CONTENT TO GET ACTIVATION CODE

  contents <- content(get, "parse")

  activate = GET(contents$`_links`$assets, authenticate(api_key, ""))

  for(t in seq(1,1000,1)) {
    print(t)
    activated = POST(content(activate)[[product]][["_links"]][["activate"]], authenticate(api_key, ""))
    if(activated$status_code != 204){
      print(paste(activated$status_code, "retry in 10 seconds"))
      Sys.sleep(10)}
    else {break}}

  activate = GET(contents$`_links`$assets, authenticate(api_key, ""))
  download = GET(content(activate)[[product]][["_links"]][["_self"]], authenticate(api_key, ""))

  link = content(download, "parsed")

  export = paste0(contents$id,".tif")

  RETRY("GET", link$location, httr::write_disk(export, overwrite = T), httr::progress("down"), authenticate(api_key, ""))

}
