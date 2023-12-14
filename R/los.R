get_vissim_los <- function(results, signalized, net, hcm) {
  turns <- net$edges_df %>%
    select(from, to, leg, turn) %>%
    filter(turn != "internal")
  
  los <- results %>%
    transmute(
      iter = `$MOVEMENTEVALUATION:SIMRUN`,
      # time = TIMEINT,
      movement = `MOVEMENT\\DIRECTION`,
      qlen = QLEN,
      maxqlen = QLENMAX,
      avgdelay = `VEHDELAY(ALL)`,
      intersection = `MOVEMENT\\NODE\\NO`,
      to = `MOVEMENT\\TOLINK\\NO`,
      to = replace(to, to == 44, 10122),
      from = `MOVEMENT\\FROMLINK\\NO`,
    ) %>%
    filter(iter == "AVG") %>%
    select(-iter) %>%
    mutate(across(c(to, from), \(x) str_sub(x, 1, 4) %>% as.numeric())) %>%
    left_join(turns, join_by(from, to)) %>%
    left_join(signalized, join_by(intersection)) %>%
    select(-c(from, to)) %>%
    relocate(intersection) %>%
    mutate(type = if_else(movement == "Total", "Intersection", "Movement")) %>%
    select(-movement) %>%
    left_join(hcm, join_by(signalized, between(avgdelay, Lower, Upper, bounds = "(]"))) %>%
    select(-c(signalized, Lower, Upper))
  
  los
}

format_los <- function(results, intersection_translation) {
  formatted <- results %>%
    format_turns(intersection_translation) %>%
    filter(!is.na(avgdelay)) %>%
    left_join(
      filter(., type == "Intersection") %>%
        select(Intersection, avgdelay, LOS),
      join_by(Intersection),
      suffix = c("_m", "_i")
    ) %>%
    filter(type != "Intersection") %>%
    select(-type, -maxqlen) %>%
    relocate(Intersection, leg, turn) %>%
    mutate(turn = case_when(
      turn == "l" ~ "Left",
      turn == "t" ~ "Thru",
      turn == "r" ~ "Right",
      TRUE ~ turn
    )) %>% 
    rename(
      Approach = leg,
      Movement = turn,
      `Avg. Queue Length (ft)` = qlen,
      `Avg. Vehicle Delay_m` = avgdelay_m,
      `Level of Service_m` = LOS_m,
      `Avg. Vehicle Delay_i` = avgdelay_i,
      `Level of Service_i` = LOS_i
    )
  
  formatted
}

format_turns <- function(data, intersection_translation) {
  formatted <- data %>%
    mutate(
      turn = case_when(
        turn == 1 ~ "l",
        turn == 3 ~ "r",
        turn == 4 ~ "\u2192I-15",
        turn == 5 ~ "\u2192800 N",
        TRUE ~ turn
      ),
      leg = if_else(leg == "OB", "800 N", leg)
    ) %>%
    left_join(intersection_translation,
              join_by(intersection == intersection_num)) %>%
    relocate(intersection_name) %>%
    rename(Intersection = intersection_name) %>%
    select(-intersection)
  
  formatted
}

compare_los <- function(ref_los, comp_los, los_names = c("ref", "comp")) {
  comp <- ref_los %>% 
    full_join(
      comp_los,
      join_by(intersection, leg, turn, type),
      suffix = paste0(" (", los_names, ")")) %>% 
    filter(
      type == "Movement",
    ) %>% 
    select(-contains("qlen"), -type) %>% 
    relocate(intersection, leg, turn, contains(los_names[1]), contains(los_names[2])) %>% 
    filter(!is.na(leg), !is.na(turn))
  
  comp
}

format_los_comp <- function(los_comp, intersection_translation) {
  comp <- los_comp %>% 
    format_turns(intersection_translation) %>% 
    mutate(turn = case_when(
      turn == "l" ~ "Left",
      turn == "t" ~ "Thru",
      turn == "r" ~ "Right",
      TRUE ~ turn
    )) %>% 
    rename_with(
      \(x) str_replace_all(x, c("avgdelay" = "Avg. Vehicle Delay", "LOS" = "Level of Service")),
      .cols = -c(Intersection, leg, turn)
    ) %>% 
    rename(
      Approach = leg,
      Movement = turn
    )
  
  comp
}

compare_intersection_los <- function(scenarios = list()){
  comp <- scenarios %>% 
    map(
      function(x){
        filter(x, type == "Intersection") %>% 
          select(intersection, avgdelay, LOS)
      }
    ) %>% 
    bind_rows(.id = "scenario") %>% 
    separate_wider_delim(scenario, "_", names = c("scenario", "time")) %>% 
    mutate(
      delay = paste0(LOS, " (", signif(avgdelay,3), " s/veh)"),
      intersection = if_else(
        intersection == 101,
        "101*",
        as.character(intersection)
      )) %>% 
    select(scenario, time, intersection, delay) %>% 
    pivot_wider(names_from = scenario, values_from = delay) %>% 
    arrange(time, intersection)
  
  comp
}