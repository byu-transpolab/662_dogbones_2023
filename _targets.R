#### Setup #####################################################################

library(targets)
library(tarchetypes)

tar_option_set(
  packages = c("tidyverse", "DiagrammeR", "gtools", "readxl"),
)

#Source R functions
r_files <- list.files("R", full.names = TRUE)
sapply(r_files, source)


#### List targets ##############################################################

misc_targets <- tar_plan(
  count_bin_length <- 15, #minutes
  tar_file(leg_translation_file, "data/leg_translation.csv"),
  tar_file(intersection_translation_file, "data/intersection_translation.csv"),
  intersection_translation = readr::read_csv(intersection_translation_file),
  tar_file(hcm_los_file, "data/hcm_los_key.csv"),
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
  
  tar_file(int100_file, "data/turning_counts/int100.xlsx"),
  tar_file(int101_file, "data/turning_counts/int101.xlsx"),
  tar_file(int102_file, "data/turning_counts/int102.xlsx"),
  tar_file(int103_file, "data/turning_counts/int103.xlsx"),
  
  int100 = format_counts(int100_file, peak),
  int101 = format_counts(int101_file, peak),
  int102 = format_counts(int102_file, peak),
  int103 = format_counts(int103_file, peak),
  
  counts = combine_counts(
    list(`100` = int100, `101` = int101, `102` = int102, `103` = int103)),
)

network_ex_targets <- tar_plan(
  
  #### Data
  tar_file(ex_nodes_file, "data/nodes_existing.csv"),
  tar_file(ex_edges_file, "data/edges_existing.csv"),
  
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
  am_counts_formatted = format_turning_counts(am_peak_turn_counts, intersection_translation),
  pm_peak_turn_counts = get_hourly_turn_counts(counts, peak$PM),
  pm_counts_formatted = format_turning_counts(pm_peak_turn_counts, intersection_translation),
  
  tar_file(ex_am_results_file, "vissim/existing_2023_AM/existing_AM_Node Results.att"),
  ex_am_results = read_att(ex_am_results_file, lineskip = 28),
  ex_am_los = get_vissim_los(ex_am_results, signalized_intersections, ex_graph, hcm_los),
  ex_am_los_formatted = format_los(ex_am_los, intersection_translation),
  
  tar_file(ex_pm_results_file, "vissim/existing_2023_PM/existing_PM_Node Results.att"),
  ex_pm_results = read_att(ex_pm_results_file, lineskip = 28),
  ex_pm_los = get_vissim_los(ex_pm_results, signalized_intersections, ex_graph, hcm_los),
  ex_pm_los_formatted = format_los(ex_pm_los, intersection_translation),
  
  tar_file(ex_am_traveltimes_file, "vissim/existing_2023_AM/existing_AM_Vehicle Travel Time Results.att"),
  ex_am_traveltimes = read_att(ex_am_traveltimes_file, lineskip = 19),
  ex_am_traveltimes_formatted = format_traveltimes(ex_am_traveltimes),
  
  tar_file(ex_pm_traveltimes_file, "vissim/existing_2023_PM/existing_PM_Vehicle Travel Time Results.att"),
  ex_pm_traveltimes = read_att(ex_pm_traveltimes_file, lineskip = 19),
  ex_pm_traveltimes_formatted = format_traveltimes(ex_pm_traveltimes),
  
  #### Memo 2: New Interchange ####
  tar_file(build_am_results_file, "vissim/build_doubleln_2023_AM/build_2023_AM_Node Results.att"),
  build_am_results = read_att(build_am_results_file, lineskip = 28),
  build_am_los = get_vissim_los(build_am_results, signalized_intersections, ex_graph, hcm_los),
  build_am_los_formatted = format_los(build_am_los, intersection_translation),
  
  tar_file(build_pm_results_file, "vissim/build_doubleln_2023_PM/build_2023_PM_Node Results.att"),
  build_pm_results = read_att(build_pm_results_file, lineskip = 28),
  build_pm_los = get_vissim_los(build_pm_results, signalized_intersections, ex_graph, hcm_los),
  build_pm_los_formatted = format_los(build_pm_los, intersection_translation),
  
  ex_build_am_los_comp = compare_los(
    ex_am_los,
    build_am_los,
    los_names = c("Existing", "Build (2023)")),
  ex_build_am_los_comp_formatted = format_los_comp(ex_build_am_los_comp, intersection_translation),
  ex_build_pm_los_comp = compare_los(
    ex_pm_los,
    build_pm_los,
    los_names = c("Existing", "Build (2023)")),
  ex_build_pm_los_comp_formatted = format_los_comp(ex_build_pm_los_comp, intersection_translation),
  
  tar_file(build_am_traveltimes_file, "vissim/build_doubleln_2023_AM/build_2023_AM_Vehicle Travel Time Results.att"),
  build_am_traveltimes = read_att(build_am_traveltimes_file, lineskip = 20),
  build_am_traveltimes_formatted = format_traveltimes(build_am_traveltimes),
  
  tar_file(build_pm_traveltimes_file, "vissim/build_doubleln_2023_PM/build_2023_PM_Vehicle Travel Time Results.att"),
  build_pm_traveltimes = read_att(build_pm_traveltimes_file, lineskip = 19),
  build_pm_traveltimes_formatted = format_traveltimes(build_pm_traveltimes),
  
  #### Memo 3: Future Volumes ####
  tar_file(matsim_counts_file, "data/turning_counts/matsim_counts.csv"),
  matsim_growth = get_matsim_growth(matsim_counts_file),
  vissim_growth = make_vissim_growth(matsim_growth, am_peak_turn_counts, pm_peak_turn_counts),
  pretty_vissim_growth = make_pretty_intersection_table(
    vissim_growth,
    intersection_translation,
    renames = c(
      "2022 AM Peak Hour Volume (AM)" = "am",
      "2022 PM Peak Hour Volume (PM)" = "pm",
      "Growth Rate (2022\u20132050)" = "growth_rate",
      "2050 Peak Hour Volume (AM)" = "new_am",
      "2050 Peak Hour Volume (PM)" = "new_pm"
    )),
  
  new_counts = grow_counts(counts, matsim_growth),
  
  #### Analysis
  #ex_graph = make_net_graph(ex_nodes_file, ex_edges_file, leg_translation_file),
  new_turn_pcts = get_turn_pcts(new_counts, ex_graph),
  #ex_od_routes = get_od_routes(ex_graph),
  new_od_pcts = get_od_pcts(new_turn_pcts, ex_od_routes, "data/vissim_inputs/new_od_pcts.csv"),
  new_approach_vols = get_approach_vols(new_counts, ex_graph, peak, count_bin_length, "data/vissim_inputs/new_vols.csv"),
)

no_build_targets <- tar_plan(
  tar_file(nobuild_am_results_file, "vissim/existing_2050_AM/existing2050_AM_Node Results.att"),
  nobuild_am_results = read_att(nobuild_am_results_file, lineskip = 28),
  nobuild_am_los = get_vissim_los(nobuild_am_results, signalized_intersections, ex_graph, hcm_los),
  nobuild_am_los_formatted = format_los(nobuild_am_los, intersection_translation),
  
  tar_file(nobuild_pm_results_file, "vissim/existing_2050_PM/existing2050_PM_Node Results.att"),
  nobuild_pm_results = read_att(nobuild_pm_results_file, lineskip = 28),
  nobuild_pm_los = get_vissim_los(nobuild_pm_results, signalized_intersections, ex_graph, hcm_los),
  nobuild_pm_los_formatted = format_los(nobuild_pm_los, intersection_translation),
)

build_2050_targets <- tar_plan(
  tar_file(build_2050_am_results_file, "vissim/build_doubleln_2050_AM/build_2050_AM_Node Results.att"),
  build_2050_am_results = read_att(build_2050_am_results_file, lineskip = 28),
  build_2050_am_los = get_vissim_los(build_2050_am_results, signalized_intersections, ex_graph, hcm_los),
  build_2050_am_los_formatted = format_los(build_2050_am_los, intersection_translation),
  
  tar_file(build_2050_pm_results_file, "vissim/build_doubleln_2050_PM/build_2050_PM_Node Results.att"),
  build_2050_pm_results = read_att(build_2050_pm_results_file, lineskip = 28),
  build_2050_pm_los = get_vissim_los(build_2050_pm_results, signalized_intersections, ex_graph, hcm_los),
  build_2050_pm_los_formatted = format_los(build_2050_pm_los, intersection_translation),
)

final_analysis_targets <- tar_plan(
  
  final_am_los_comp = compare_los(
    nobuild_am_los,
    build_2050_am_los,
    los_names = c("No-Build", "Build")),
  final_am_los_comp_formatted = format_los_comp(final_am_los_comp, intersection_translation),
  final_pm_los_comp = compare_los(
    nobuild_pm_los,
    build_2050_pm_los,
    los_names = c("No-Build", "Build")),
  final_pm_los_comp_formatted = format_los_comp(final_pm_los_comp, intersection_translation),

  tar_file(build_2050_am_traveltimes_file, "vissim/build_doubleln_2050_AM/build_2050_AM_Vehicle Travel Time Results.att"),
  build_2050_am_traveltimes = read_att(build_2050_am_traveltimes_file, lineskip = 20),
  build_2050_am_traveltimes_formatted = format_traveltimes(build_2050_am_traveltimes),

  tar_file(build_2050_pm_traveltimes_file, "vissim/build_doubleln_2050_PM/build_2050_PM_Vehicle Travel Time Results.att"),
  build_2050_pm_traveltimes = read_att(build_2050_pm_traveltimes_file, lineskip = 19),
  build_2050_pm_traveltimes_formatted = format_traveltimes(build_2050_pm_traveltimes),
  
  intersection_los_comp = compare_intersection_los(
    list(
      "Existing_am" = ex_am_los,
      "Existing_pm" = ex_pm_los,
      "No-Build_am" = nobuild_am_los,
      "No-Build_pm" = nobuild_pm_los,
      "Build_am" = build_2050_am_los,
      "Build_pm" = build_2050_pm_los
      )
    ),
  
)

#### Run all targets ###########################################################

tar_plan(
  misc_targets,
  counts_targets,
  network_ex_targets,
  memo_targets,
  no_build_targets,
  build_2050_targets,
  final_analysis_targets,
)
