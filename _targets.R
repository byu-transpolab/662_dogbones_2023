#### Setup #####################################################################

library(targets)
library(tarchetypes)

tar_option_set(
  packages = c("tidyverse", "wesanderson"),
)

#Source R functions
r_files <- list.files("R", full.names = TRUE)
sapply(r_files, source)


#### List targets ##############################################################

temp_targets <- tar_plan(
  cars = mtcars,
  sumnum = add2(5),
)


#### Run all targets ###########################################################

tar_plan(
  temp_targets,
)