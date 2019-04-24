# planetR

Some R tools to search, activate and download satellite imgery from the Planet API (https://developers.planet.com/docs/api/). The current purpose of the package is to Search the API, batch activate all assets, and then batch download them. 

### Features

```{r features}
## basic example code
planetR::planet_search()
planetR::planet_activate()
planetR::planet_download()
```

### Installation

You can install planetR directly from this GitHub repository. To do so, you will need the remotes package:

```{r features}
install.packages("remotes")
```

Next, install and load the planetR package using remotes::install_github():

```{r features}
remotes::install_github("bevingtona/planetR")
library(planetR)
```

### Usage

Step 1: Search API (inspired from https://www.lentilcurtain.com/posts/accessing-planet-labs-data-api-from-r/)<br /> 
Step 2: Write a loop to batch activate<br />
Step 3: Write a loop to batch download

#### Example

This is a basic example of how to search, activate and download assets using `planetR`.

```{r example}

#### VARIABLES: Set variables for Get_Planet function ####

# Set API
  api_key = ""
  
# Date range of interest
  start_year = 2018
  end_year   = 2018
  start_doy  = 250
  end_doy    = 300
  date_start = as.Date(paste0(year,"-01-01"))+start_doy
  date_end   = as.Date(paste0(year,"-01-01"))+end_doy


# Metadata filters
  cloud_lim    = 0.1 #less than
  item_names   = c("PSOrthoTile") #PSScene4Band")#,"PSScene3Band") #c(#c("Sentinel2L1C") #"PSOrthoTile"
  products     = c("analytic")#c("analytic_b1","analytic_b2")
  my_aoi       = read_sf("")
  bbox         = extent(my_aoi)

#### PLANET_SEARCH: Search API ####

  response <- planet_search(bbox, date_end, date_start, cloud_lim, cover_lim, item_name)
  print(paste("Images available:",length(response$features), item_name, product))

#### PLANET_ACTIVATE: Batch Activate ####

  if(length(response$features) == 0)
    {print("No images")}
  if(length(response$features) > 0)
    {
    for(i in 1:length(response$features)) {
      planet_activate(i)
      print(paste("Activating", i, "of", length(response$features)))}
  
      print("wait 20 seconds")
      Sys.sleep(20)

#### PLANET_DOWNLOAD: Batch Download ####

  for(i in 1:length(response$features)) {
    planet_download(i)
    print(paste("Downloading", i, "of", length(response$features)))}
```

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
```

