# Misc functions

#' Wrapper for gtools::permutations() with sane syntax
perm <- function(v, r, n = length(v), set = TRUE, repeats.allowed = FALSE) {
  gtools::permutations(n, r, v, set, repeats.allowed)
}

#' Paste route nodes together 2 at a time to get links
get_route_links <- function(route) {
  len <- length(route)
  links <- c()
  for (i in 1:(len - 1)){
    links[i] <- paste(route[i], route[i+1], sep = "_")
  }
  
  links
}

#' Take character vectors and make them lubridate intervals
make_peak <- function(peak_hour) {
  if(!is_list(peak_hour)) peak_hour <- list(peak_hour)
  map(peak_hour, \(t) {
    t %>% 
      hm() %>% 
      as_datetime() %>% 
      {interval(.[1], .[2])}
  })
}

make_hcm_los <- function(file){
  file %>%
    read_csv() %>%
    mutate(signalized = case_when(
      Type == "Signalized" ~ TRUE,
      Type == "Unsignalized" ~ FALSE
    )) %>% 
    select(-Type)
}

get_vissim_results <- function(results_file, signalized, net, hcm){
  
  turns <- net$edges_df %>% 
    select(from, to, leg, turn) %>% 
    filter(turn != "internal")
  
  results <- results_file %>% 
    read_delim(delim = ";", skip = 25) %>% 
    transmute(
      iter = `$MOVEMENTEVALUATION:SIMRUN`,
      # time = TIMEINT,
      movement = `MOVEMENT\\DIRECTION`,
      qlen = QLEN,
      maxqlen = QLENMAX,
      avgdelay = `VEHDELAY(ALL)`,
      intersection = `MOVEMENT\\NODE`,
      to = `MOVEMENT\\TOLINK`,
      to = replace(to, to == 44, 10122),
      from = `MOVEMENT\\FROMLINK`,
    ) %>% 
    filter(iter == "AVG") %>% 
    select(-iter) %>% 
    mutate(across(c(to, from), \(x) str_sub(x,1,4) %>% as.numeric())) %>% 
    left_join(turns, join_by(from, to)) %>% 
    left_join(signalized, join_by(intersection)) %>% 
    select(-c(from, to)) %>% 
    relocate(intersection) %>% 
    mutate(type = if_else(movement == "Total", "Intersection", "Movement")) %>% 
    select(-movement) %>% 
    left_join(hcm, join_by(signalized, between(avgdelay, Lower, Upper, bounds = "(]"))) %>% 
    select(-c(signalized, Lower, Upper))
  
  results
  
}