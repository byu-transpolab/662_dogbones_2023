format_traveltimes <- function(traveltimes) {
  # simplify data and format
  df <- traveltimes %>%
    filter(`$VEHICLETRAVELTIMEMEASUREMENTEVALUATION:SIMRUN` == "AVG") %>%
    select(
      Movement = `VEHICLETRAVELTIMEMEASUREMENT\\NAME`,
      Vehicles = `VEHS(ALL)`,
      tt = `TRAVTM(ALL)`,
      dist = `DISTTRAV(ALL)`
    ) %>%
    mutate(
      Movement = toupper(Movement),
      tt = round(tt, 0),
      dist = round(dist, 0)
    ) %>%
    rename(
      `Average Travel Time (sec)` = tt,
      `Average Distance Traveled (ft)` = dist
    )
  # return dataframe
  return(df)
}