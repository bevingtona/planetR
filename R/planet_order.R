## PlanetR Request Orders API

#' A function to order Planet imagery
#'
#' This function allows you to search and activate orders from the Planet Orders API
#' @param api_key a string containing your API Key for your planet account
#' @param bbox bounding box made with extent() from the raster package; must be EPSG:4326 Projection; no default.
#' @param date_start a date object
#' @param date_end a date object
#' @param cloud_lim Cloud percentage from 0-1; defaults to 0.1, or 10%.
#' @param item_name Defaults to "PSScene4Band".
#' @param product Defaults to "analytic_sr"
#' @param order The name you want to assign to your order. Defaults to "AutomationTEST"
#' @keywords Planet
#' @export
#' @examples
#' planet_search()

library(sf)
library(here)
library(httr)
library(jsonlite)
library(raster)
library(stringr)

planet_order_request <-
  function(api_key,
           bbox,
           date_start,
           date_end,
           start_doy,
           end_doy,
           cloud_lim,
           item_name,
           product,
           order_name = exportfolder) {
    #SEARCH FOR IMAGES

    response <- planet_search(bbox,
                              start_doy,
                              end_doy,
                              date_end,
                              date_start,
                              cloud_lim,
                              item_name,
                              api_key)



    #ORDER API

    items = response[, 1]


    products = list(
      list(
        item_ids = items,
        item_type = jsonlite::unbox(item_name),
        product_bundle = jsonlite::unbox(product)
      )
    )

    aoi = list(type = jsonlite::unbox("Polygon"),
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
               )))

    #json structure needs specific nesting, double nested for tools hence the list(list())
    clip = list(aoi = aoi)
    tools <-  list(list(clip = clip))

    #Build request body and convert to json
    order_name = jsonlite::unbox(order_name)
    order_body <-
      list(name = order_name,
           products = products,
           tools = tools)
    order_json <- jsonlite::toJSON(order_body, pretty = TRUE)

    url = "https://api.planet.com/compute/ops/orders/v2"

    #Sent request (will make order, NOT REVERSIBLE, will show up on planet account)
    request <- httr::POST(url,
                          body = order_json,
                          httr::content_type_json(),
                          username = api_key)

    #request content
    post_content <- httr::content(request)

    if (!is.null(post_content$field$Details[[1]]$message)) {
      print(post_content$field$Details[[1]]$message)
    }

    order_id <- post_content$id

    print(paste("Save the Order ID:", order_id))
    print("You can restart the download with `planet_order_download(order_id, order_name)`")

    return(order_id)
  }

## PlanetR Orders API Download

#' A function to order Planet imagery
#'
#' This function allows you to download orders from the Planet Orders API
#' @param order_id request order id (output from `planet_order_request()`)
#' @param order_name The name you want to assign to your order
#' @keywords Planet
#' @export
#' @examples

planet_order_download <- function(order_id, order_name) {
  #GET order for download
  #If you lose the order_id, don't redo the request, log onto planet and find it in the orders menu
  #order_id for example SMV2 order: "dab92990-ce3a-456c-8ad6-ca0c569b4a1a"
  url2 = paste0("https://api.planet.com/compute/ops/orders/v2/", order_id)

  get_order <- httr::GET(url = url2,
                         username = api_key)
  #Download links are in here, under _links>results>location
  get_content <- httr::content(get_order)
  #When state = 'success', ready for download

  #check if order is ready
  while (get_content$state != "success") {
    print("Order still being proccessed, trying again in 60 seconds...")
    print(get_content$state)
    Sys.sleep(60)
    get_order <- httr::GET(url = url2, username = api_key)
    get_content <- httr::content(get_order)
  }

  ##Time to download!
  print("Starting download")

  #First create download folder:
  dir.create(order_name, showWarnings = F)

  #Download each item in order
  for (i in 1:length(get_content$`_links`$results)) {
    print(paste0("Download: ", signif(100 * (
      i / length(get_content$`_links`$results)
    ), 1), "%"))
    #find item names in order contents
    name <- get_content$`_links`$results[[i]]$name
    findslash <- gregexpr("/", name)
    startchar <- findslash[[1]][length(findslash[[1]])] + 1
    filename <- substr(name, startchar, nchar(name))

    download_url <- get_content$`_links`$results[[i]]$location

    httr::RETRY(
      "GET",
      url = download_url,
      username = api_key,
      write_disk(
        path = paste(order_name, filename, sep = "/"),
        overwrite = TRUE
      )
    )

  }

  print(paste0("Download complete"))
  print(paste0("Items located in ", getwd(), "/", order_name))

}

## PlanetR Orders API Search, Activate, Download

#' A function to order Planet imagery
#'
#' This function allows you to download orders from the Planet Orders API
#' @param api_key a string containing your API Key for your planet account
#' @param bbox bounding box made with extent() from the raster package; must be EPSG:4326 Projection; no default.
#' @param date_start a date object
#' @param date_end doy start
#' @param start_doy doy end
#' @param end_doy a date object
#' @param cloud_lim Cloud percentage from 0-1; defaults to 0.1, or 10%.
#' @param item_name Defaults to "PSScene4Band".
#' @param product Defaults to "analytic_sr"
#' @param order_name The name you want to assign to your order
#' @keywords Planet
#' @export
#' @examples
#' planet_order_request
#' planet_order_download

planet_order <- function(api_key,
                         bbox,
                         date_start,
                         date_end,
                         start_doy,
                         end_doy,
                         cloud_lim,
                         item_name,
                         product,
                         order_name) {
  order_id <- planet_order_request(
    api_key,
    bbox,
    date_start,
    date_end,
    start_doy,
    end_doy,
    cloud_lim,
    item_name,
    product,
    order_name = "test"
  )

  planet_order_download(order_id, order_name)

}
