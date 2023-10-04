#' Read and format raw traffic counts
format_counts <- function(raw_counts_file, peak) {
  sheets_list <- excel_sheets(raw_counts_file)
  
  if(!all(c("Cars", "Trucks") %in% sheets_list)) {
    stop('The counts file is missing either a "Cars" or "Trucks" sheet (or both).')
  }
  
  car_counts <- read_excel(raw_counts_file, sheet = "Cars") %>% 
    mutate(Time = hm(Time) %>% as_datetime()) %>% 
    select(-contains("Peds")) %>% 
    filter(Time %within% peak)
  
  truck_counts <- read_excel(raw_counts_file, sheet = "Trucks") %>% 
    mutate(Time = hm(Time) %>% as_datetime()) %>% 
    select(-contains("Bikes")) %>% 
    filter(Time %within% peak)
  
  counts <- bind_rows(
    car = car_counts,
    truck = truck_counts,
    .id = "bank"
  )
  
  counts
}

#' Combine all turning counts
combine_counts <- function(counts_list) {
  bind_rows(counts_list, .id = "intersection") %>% 
    pivot_longer(-c(intersection, bank, Time), names_to = "mvmt", values_to = "count") %>% 
    filter(count > 0) %>%
    separate(mvmt, c("leg", "turn")) %>% 
    mutate(
      turn = str_to_lower(str_sub(turn,1,1)),
      intersection = as.numeric(intersection)
      )
}

#' Get approach vols
get_approach_vols <- function(counts, net, peak) {
  
  peak_starts <- peak %>% 
    map(\(x) int_start(x) %>% format("%H:%M")) %>% 
    unlist()
  
  counts %>% 
    group_by(bank, intersection, Time, leg) %>% 
    summarise(volume = sum(count), .groups = "drop") %>% 
    left_join(net$nodes_df, join_by(intersection, leg == leg_dir)) %>% 
    filter(type == "ex") %>% 
    select(bank, label, Time, volume) %>% 
    pivot_wider(names_from = "bank", values_from = "volume") %>% 
    replace_na(list(car = 0, truck = 0)) %>% 
    transmute(
      label,
      Time = format(Time, "%H:%M"),
      # car,
      # truck,
      volume = car + truck,
      truck_pct = truck / (car + truck)
    ) %>%
    mutate(load = case_when(
      Time %in% peak_starts ~ names(peak_starts[match(Time, peak_starts)])
    )) %>% 
    uncount(if_else(is.na(load), 1, 2)) %>% 
    group_by(label, Time) %>% 
    mutate(
      load = replace(load, 1, NA),
      Time = if_else(is.na(load), Time, paste("load", load, sep = "_"))) %>% 
    select(-load) %>% 
    ungroup() %>% 
    pivot_wider(names_from = "Time", values_from = c("volume", "truck_pct"))
}