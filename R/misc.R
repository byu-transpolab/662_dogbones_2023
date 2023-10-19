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