  
#' A function to download activated Planet imagery
#'
#' Download and clip images
#' @param i 
#' @param overwrite
#' @param my_aoi
#' @keywords Planet
#' @export
#' @examples
#' planet_download_withClip()

library(httr)
library(jsonlite)
library(stars)
library(sf)


planet_download_withClip <- function (i, overwrite = T, my_aoi, out_dir) 
{
  url <- paste0("https://api.planet.com/data/v1/item-types/", 
                item_name, "/items/", response[i, ])
  get <- GET(url, content_type_json(), authenticate(api_key, 
                                                    ""))
  if (get$status_code == 429) {
    print(paste("Status code:", get$status_code, "rate limit error: poll"))
  }
  if (get$status_code == 200) {
    print(paste("Status code:", get$status_code, "authenticated"))
  }
  if (get$status_code == 404) {
    print(paste("Status code:", get$status_code, "error"))
  }
  contents <- content(get, "parse")
  activate = GET(contents$`_links`$assets, authenticate(api_key, 
                                                        ""))
  if (max(names(content(activate)) %in% product) == 1) {
    for (t in seq(1, 1000, 1)) {
      print(t)
      activated = POST(content(activate)[[product]][["_links"]][["activate"]], 
                       authenticate(api_key, ""))
      if (activated$status_code != 204) {
        print(paste(activated$status_code, "retry in 10 seconds"))
        Sys.sleep(10)
      }
      else {
        break
      }
    }
    activate = GET(contents$`_links`$assets, authenticate(api_key, 
                                                          ""))
    download = GET(content(activate)[[product]][["_links"]][["_self"]], 
                   authenticate(api_key, ""))
    link = content(download, "parsed")
    export = paste0(out_dir, "/", contents$id, 
                    ".tif")
    RETRY("GET", link$location, httr::write_disk(export, 
                                                 overwrite = overwrite), httr::progress("down"), 
          authenticate(api_key, ""))
    

    r <- read_stars(export)
    r_clip <- r[my_aoi %>% st_transform(crs = st_crs(r))] 
    stars::write_stars(obj = r_clip, dsn = sub(".tif","_clip.tif",export))
    file.remove(export)
    
  }
  else {
    print(paste("No", item_name, product, "data available for download"))
  }
}
