# planetR

Some R tools to search, activate and download satellite imagery from the Planet API (https://developers.planet.com/docs/api/). The current purpose of the package is to Search the API, batch activate all assets, and then batch download them. 

There are two API's: 
- v1 Planet API
- v2 Planet Orders API (can clip and pre-process scenes to AOI on server)

### Functions

```{r functions}

## current functions (API v1)
planetR::planet_search()
planetR::planet_activate()
planetR::planet_download()

## current functions (Orders API v2)
planetR::planet_order_request()
planetR::planet_order_download()
planetR::planet_order()

```

### Installation

You can install planetR directly from this GitHub repository. To do so, you will need the remotes package. Next, install and load the planetR package using remotes::install_github():

```{r installation}
install.packages("remotes")
remotes::install_github("bevingtona/planetR")
library(planetR)
```

#### Example

This is an example of how to search, activate and download assets using `planetR`.

```{r example}

#### LIBRARIES ####
library(planetR)
library(httr)
library(jsonlite)
library(raster)
library(stringr)

#### USER VARIABLES ####

# Site name that will be used in the export folder name
site = "MySite"

# Set Workspace (optional)
setwd("")

# Set API
api_key = "" 

# Date range of interest
start_year = 2016
end_year   = 2020
start_doy  = 290 # OR FROM DATE as.numeric(format(as.Date('2000-07-15'),"%j"))
end_doy    = 300 # OR FROM DATE as.numeric(format(as.Date('2000-08-15'),"%j"))
date_start = as.Date(paste0(start_year,"-01-01"))+start_doy
date_end   = as.Date(paste0(end_year,"-01-01"))+end_doy

# Metadata filters
cloud_lim    = 0.02 # percent from 0-1
item_name    = "PSScene4Band" 
  # PSOrthoTile, PSScene3Band, Sentinel2L1C 
  # (see https://developers.planet.com/docs/data/items-assets/)
product      = "analytic_sr" 
  # analytic_b1, analytic_b2 
  # (see https://developers.planet.com/docs/data/items-assets/)

# Set AOI (many ways to set this!) ultimately just need an extent()
# OPTION 1: Import feature
my_aoi       = read_sf("path_to_file.sqlite") # KML, SHP, SQLITE, or other
bbox         = extent(my_aoi)
# OPTION 2: Digitize om map
my_aoi       = mapedit::editMap() # Set in GUI
bbox         = extent(my_aoi)
# OPTION 3: Set bounding box manually
bbox         = extent(-129,-127,50,51)

# Set/Create Export Folder
exportfolder = paste(site, item_name, product, start_year, end_year, start_doy, end_doy, sep = "_")
dir.create(exportfolder, showWarnings = F)

# Planet Orders API
planet_order(api_key = api_key, 
             bbox = bbox, 
             date_start = date_start, 
             date_end = date_end, 
             start_doy = start_doy, 
             end_doy = end_doy, 
             cloud_lim = cloud_lim, 
             item_name = item_name, 
             product = product,
             order_name = exportfolder)

```

OR 

```{r example_v1}

# PLANET_SEARCH: Search API

  response <- planet_search(bbox, date_end, date_start, cloud_lim, item_name)
  print(paste("Images available:", nrow(response), item_name, product))

# PLANET_ACTIVATE: Batch Activate 

for(i in 1:nrow(response)) {
  planet_activate(i, item_name = item_name)
  print(paste("Activating", i, "of", nrow(response)))}

# PLANET_DOWNLOAD: Batch Download 

for(i in 1:nrow(response)) {
  planet_download(i)
  print(paste("Downloading", i, "of", nrow(response)))}
  
```
![](images/download_example.png)


### Project Status

Very early/experimental status. 

### Getting Help or Reporting an Issue

To report bugs/issues/feature requests, please file an [issue](https://github.com/bevingtona/planetR/issues/).

### How to Contribute

If you would like to contribute to the package, please see our 
[CONTRIBUTING](CONTRIBUTING.md) guidelines.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

### License

```
Licensed under the Apache License, Version 2.0 (the &quot;License&quot;);
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an &quot;AS IS&quot; BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
