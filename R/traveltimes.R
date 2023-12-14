format_traveltimes <- function(traveltimes) {
  # simplify data and format
  df <- traveltimes %>%
    filter(`$VEHICLETRAVELTIMEMEASUREMENTEVALUATION:SIMRUN` == "AVG") %>% 
    select(
      Movement = `VEHICLETRAVELTIMEMEASUREMENT`,
      Vehicles = `VEHS(ALL)`,
      tt = `TRAVTM(ALL)`,
      dist = `DISTTRAV(ALL)`
    ) %>%
    mutate(
      Movement = case_match(
        Movement,
        1 ~ "nbt",
        2 ~ "nbn",
        3 ~ "nbs",
        4 ~ "sbt",
        5 ~ "sbn",
        6 ~ "sbs"
      ),
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
