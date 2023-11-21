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

make_hcm_los <- function(file) {
  file %>%
    read_csv() %>%
    mutate(signalized = case_when(
      Type == "Signalized" ~ TRUE,
      Type == "Unsignalized" ~ FALSE
    )) %>% 
    select(-Type)
}

read_att <- function(file, lineskip) {
  read_delim(file, delim = ";", skip = lineskip)
}

make_pretty_intersection_table <- function(table, trans, renames = c()) {
  table %>% 
    left_join(trans, join_by(intersection == intersection_num)) %>% 
    mutate(
      turn = case_when(
        turn == 1 ~ "l",
        turn == 3 ~ "r",
        turn == 4 ~ "\u2192I-15",
        turn == 5 ~ "\u2192800 N",
        TRUE ~ turn
      ),
      turn = case_when(
        turn == "l" ~ "Left",
        turn == "t" ~ "Thru",
        turn == "r" ~ "Right",
        TRUE ~ turn
      ),
      leg = if_else(leg == "OB", "800 N", leg),
      intersection = intersection_name
    ) %>%
    select(-intersection_name) %>% 
    relocate(intersection, leg, turn) %>%
    rename(
      "Intersection" = intersection,
      "Approach" = leg,
      "Movement" = turn
    ) %>% 
    rename(all_of(renames))
}