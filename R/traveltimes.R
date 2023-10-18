format_traveltimes <- function(traveltimes) {
  # simplify data
  df <- traveltimes %>%
    filter(`$VEHICLETRAVELTIMEMEASUREMENTEVALUATION:SIMRUN` == "AVG") %>%
    select(
      movement = `VEHICLETRAVELTIMEMEASUREMENT\\NAME`,
      vehicles = `VEHS(ALL)`,
      avg_travel_time_sec = `TRAVTM(ALL)`,
      avg_distance_traveled_ft = `DISTTRAV(ALL)`
    )
}