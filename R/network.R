make_net_graph <- function(nf, ef, legf){
  leg_translation <- read_csv(legf)
  
  nodes <- read_csv(nf, comment = "#") %>% 
    mutate(
      label = as.character(id),
      intersection = str_sub(id, 1, 3),
      leg_num = str_sub(id, 4, 4)) %>% 
    mutate(across(-c(type, label), as.numeric)) %>% 
    left_join(leg_translation, join_by(leg_num))
  
  edges <- read_csv(ef, comment = "#") %>% 
    left_join(
      select(nodes, -c(type, label)),
      join_by(from == id)) %>% 
    left_join(
      select(nodes, -c(type, label)),
      join_by(to == id),
      suffix = c(".o", ".d")) %>% 
    mutate(
      turn = case_when(
        leg_num.d == leg_num.o ~ "u",
        leg_num.o > 4 | leg_num.d > 4 ~ as.character(leg_num.d),
        intersection.d != intersection.o ~ "internal",
        (leg_num.d - leg_num.o)%%4 == 1 ~ "l",
        (leg_num.d - leg_num.o)%%4 == 2 ~ "t",
        (leg_num.d - leg_num.o)%%4 == 3 ~ "r"
      )) %>% 
    transmute(
      from,
      to,
      rel = NA,
      link = paste(from, to, sep = "_"),
      intersection = intersection.o,
      leg = leg_dir.o,
      turn
    )
  
  net <- create_graph(nodes, edges)
  
  net
}

get_od_routes <- function(net){
  ex_nodes <- net$nodes_df %>% 
    filter(type == "ex") %>% 
    {.$id}
  
  routes <- perm(ex_nodes, 2) %>% 
    as_tibble(.name_repair = "universal") %>% 
    `colnames<-`(c("from", "to")) %>% 
    mutate(
      route = pmap(
        .l = list(from = from, to = to),
        .f = \(from, to) get_paths(net, from, to, shortest_path = TRUE)[[1]]
      ))
  
  routes
}

get_od_pcts <- function(counts, routes, out_file){
  wide_counts <- counts %>%
    mutate(Time = format(Time, "%H:%M")) %>% 
    pivot_wider(names_from = Time, values_from = frac) %>% 
    mutate(across(-link, \(x) replace_na(x,0)))
    
  od_pcts <- routes %>% 
    filter(!is.na(route)) %>% 
    mutate(
      links = map(route, get_route_links)
    ) %>% 
    select(-route) %>% 
    unnest(links) %>% 
    left_join(wide_counts, join_by(links == link)) %>% 
    # mutate(across(-c(from,to,links), \(x) replace_na(x,1))) %>% 
    group_by(from, to) %>% 
    summarise(across(-c(links), \(x) prod(x, na.rm = TRUE)), .groups = "drop") %>% 
    mutate(vissim_route = paste0(from,to), .after = to) %>% 
    arrange(vissim_route)
  
  write_csv(od_pcts, out_file, na = "")
  
  od_pcts
}
