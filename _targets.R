#### Setup #####################################################################

library(targets)
library(tarchetypes)

tar_option_set(
  packages = c("tidyverse", "DiagrammeR"),
)

#Source R functions
r_files <- list.files("R", full.names = TRUE)
sapply(r_files, source)


#### List targets ##############################################################

misc_targets <- tar_plan(
  tar_target(leg_translation_file, "data/leg_translation.csv"),
)

network_ex_targets <- tar_plan(
  
  #### Data
  tar_target(ex_nodes_file, "data/nodes_existing.csv", format = "file"),
  tar_target(ex_edges_file, "data/edges_existing.csv", format = "file"),
  
  ex_graph = make_net_graph(ex_nodes_file, ex_edges_file, leg_translation_file),
  
)


#### Run all targets ###########################################################

tar_plan(
  misc_targets,
  network_ex_targets,
)