#' A function to batch activate the results from planet_search()
#'
#' This function allows you to activate assets using the Planet API. Assets cannot be downloaded until activated.
#' @param i Row index (integer) of the search result. Mant to be used in a loop.
#' @param item_name Defaults to "PSOrthoTile".
#' @keywords Planet
#' @export
#' @examples
#' planet_activate()

library(httr)
library(jsonlite)

planet_activate = function(i, item_name = "PSOrthoTile")
{
  url <- paste0("https://api.planet.com/data/v1/item-types/",item_name,"/items/",response[i,])
  print(url)

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

  if(max(names(content(activate)) %in% product) == 1){
    activated = POST(content(activate)[[product]][["_links"]][["activate"]], authenticate(api_key, ""))
  if(activated$status_code == 204){
    print(paste("Status code:", activated$status_code, "Ready to download"))}
  if(activated$status_code == 202){
    print(paste("Status code:", activated$status_code, "Not ready to download"))}
  if(activated$status_code == 200){
    print(paste("Status code:", activated$status_code, "Not ready to download"))}
  }else{print(paste("No", item_name, product, "data available for activation"))}}
