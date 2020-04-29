library(parallel)
library(doFuture)

cores <- detectCores()
cl <- makeCluster(cores-1)
registerDoFuture(cl)
plan(sequential)

x <- foreach(i = 1:nrow(response), .export = c("item_name")) %dopar% {
  print(i)
  planet_activate(i, item_name = item_name)
  Sys.sleep(10)}


cores <- detectCores()
cl <- makeCluster(cores-1)
registerDoFuture(cl)
plan(sequential)

x <- foreach(i = 1:nrow(response)) %dopar% {
  print(i)
  planet_download(i)
  Sys.sleep(10)}

