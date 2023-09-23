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

get_turn_counts <- function(counts_file, net){
  
  counts <- read_csv(counts_file)
  
  counts %>%
    left_join(net$edges_df, join_by(intersection, leg, turn)) %>% 
    select(-c(id, rel)) %>% 
    pivot_longer(
      -c(intersection, leg, turn, from, to, link),
      names_to = "time",
      values_to = "count"
    ) %>% 
    group_by(intersection, leg, time) %>% 
    mutate(frac = count / sum(count)) %>% 
    ungroup() %>% 
    transmute(
      link = paste(from, to, sep = "_"),
      time,
      frac
    ) %>% 
    arrange(time, link)
}

get_od_routes <- function(counts, net){
  
  ex_nodes <- net$nodes_df %>% 
    filter(type == "ex") %>% 
    {.$id}
  
  routes <- perm(ex_nodes, 2) %>% 
    as_tibble() %>% 
    `colnames<-`(c("from", "to")) %>% 
    head(6) %>%  ##### TESTING!!! #########################################
    mutate(
      route = get_shortest_path(net, from, to)
    )
  
  routes
}