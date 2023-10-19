#### Setup #####################################################################

library(targets)
library(tarchetypes)
library(lubridate)

tar_option_set(
  packages = c("tidyverse", "DiagrammeR", "gtools", "readxl"),
)

#Source R functions
r_files <- list.files("R", full.names = TRUE)
sapply(r_files, source)


#### List targets ##############################################################

misc_targets <- tar_plan(
  count_bin_length <- 15, #minutes
  tar_target(leg_translation_file, "data/leg_translation.csv", format = "file"),
  tar_target(intersection_translation_file, "data/intersection_translation.csv", format = "file"),
  intersection_translation = readr::read_csv(intersection_translation_file),
  tar_target(hcm_los_file, "data/hcm_los_key.csv", format = "file"),
  hcm_los = make_hcm_los(hcm_los_file),
  signalized_intersections = tibble::tribble(
    ~intersection, ~signalized,
    100, FALSE,
    101, TRUE,
    102, FALSE,
    103, TRUE,
  ),
  
  peak_hour = list(AM = c("7:15", "8:14"), PM = c("16:30", "17:29")),
  peak = make_peak(peak_hour),
)

counts_targets <- tar_plan(
  tar_target(int100_file, "data/turning_counts/int100.xlsx", format = "file"),
  tar_target(int101_file, "data/turning_counts/int101.xlsx", format = "file"),
  tar_target(int102_file, "data/turning_counts/int102.xlsx", format = "file"),
  tar_target(int103_file, "data/turning_counts/int103.xlsx", format = "file"),
  
  int100 = format_counts(int100_file, peak),
  int101 = format_counts(int101_file, peak),
  int102 = format_counts(int102_file, peak),
  int103 = format_counts(int103_file, peak),
  
  counts_list = list(`100` = int100, `101` = int101, `102` = int102, `103` = int103),
  counts = combine_counts(counts_list),
)

network_ex_targets <- tar_plan(
  
  #### Data
  tar_target(ex_nodes_file, "data/nodes_existing.csv", format = "file"),
  tar_target(ex_edges_file, "data/edges_existing.csv", format = "file"),
  
  #### Analysis
  ex_graph = make_net_graph(ex_nodes_file, ex_edges_file, leg_translation_file),
  ex_turn_pcts = get_turn_pcts(counts, ex_graph),
  ex_od_routes = get_od_routes(ex_graph),
  ex_od_pcts = get_od_pcts(ex_turn_pcts, ex_od_routes, "data/vissim_inputs/ex_od_pcts.csv"),
  ex_approach_vols = get_approach_vols(counts, ex_graph, peak, count_bin_length, "data/vissim_inputs/ex_vols.csv"),
  
)

memo_targets <- tar_plan(
  
  #### Memo 1: Existing Interchange ####
  am_peak_turn_counts = get_hourly_turn_counts(counts, peak$AM),
  pm_peak_turn_counts = get_hourly_turn_counts(counts, peak$PM),
  
  tar_target(ex_am_results_file, "vissim/existing_2023_AM/existing_AM_Node Results.att", format = "file"),
  ex_am_results = read_att(ex_am_results_file, lineskip = 28),
  ex_am_los = get_vissim_los(ex_am_results, signalized_intersections, ex_graph, hcm_los),
  ex_am_los_formatted = format_los(ex_am_los, intersection_translation),
  
  tar_target(ex_pm_results_file, "vissim/existing_2023_PM/existing_PM_Node Results.att", format = "file"),
  ex_pm_results = read_att(ex_pm_results_file, lineskip = 28),
  ex_pm_los = get_vissim_los(ex_pm_results, signalized_intersections, ex_graph, hcm_los),
  ex_pm_los_formatted = format_los(ex_pm_los, intersection_translation),
  
  tar_target(ex_am_traveltimes_file, "vissim/existing_2023_AM/existing_AM_Vehicle Travel Time Results.att", format = "file"),
  ex_am_traveltimes = read_att(ex_am_traveltimes_file, lineskip = 19),
  ex_am_traveltimes_formatted = format_traveltimes(ex_am_traveltimes),
  
  tar_target(ex_pm_traveltimes_file, "vissim/existing_2023_PM/existing_PM_Vehicle Travel Time Results.att", format = "file"),
  ex_pm_traveltimes = read_att(ex_pm_traveltimes_file, lineskip = 19),
  ex_pm_traveltimes_formatted = format_traveltimes(ex_pm_traveltimes),
  
  #### Memo 2: New Interchange ####
  tar_target(build_am_results_file, "vissim/build_doubleln_2023_AM/build_2023_AM_Node Results.att", format = "file"),
  build_am_results = read_att(build_am_results_file, lineskip = 28),
  build_am_los = get_vissim_los(build_am_results, signalized_intersections, ex_graph, hcm_los),
  build_am_los_formatted = format_los(build_am_los, intersection_translation),
  
  tar_target(build_pm_results_file, "vissim/build_doubleln_2023_PM/build_2023_PM_Node Results.att", format = "file"),
  build_pm_results = read_att(build_pm_results_file, lineskip = 28),
  build_pm_los = get_vissim_los(build_pm_results, signalized_intersections, ex_graph, hcm_los),
  build_pm_los_formatted = format_los(build_pm_los, intersection_translation),
  
  tar_target(build_am_traveltimes_file, "vissim/build_doubleln_2023_AM/build_2023_AM_Vehicle Travel Time Results.att", format = "file"),
  build_am_traveltimes = read_att(build_am_traveltimes_file, lineskip = 20),
  build_am_traveltimes_formatted = format_traveltimes(build_am_traveltimes),
  
  tar_target(build_pm_traveltimes_file, "vissim/build_doubleln_2023_PM/build_2023_PM_Vehicle Travel Time Results.att", format = "file"),
  build_pm_traveltimes = read_att(build_pm_traveltimes_file, lineskip = 19),
  build_pm_traveltimes_formatted = format_traveltimes(build_pm_traveltimes),
)

  

#### Run all targets ###########################################################

tar_plan(
  misc_targets,
  counts_targets,
  network_ex_targets,
  memo_targets,
)
