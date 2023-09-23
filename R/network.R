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
        leg_num.o > 4 | leg_num.d > 4 ~ "o",
        intersection.d != intersection.o ~ "i",
        (leg_num.d - leg_num.o)%%4 == 1 ~ "l",
        (leg_num.d - leg_num.o)%%4 == 2 ~ "t",
        (leg_num.d - leg_num.o)%%4 == 3 ~ "r",
        (leg_num.d - leg_num.o)%%4 == 0 ~ "u"
      ),
      movement = case_when(
        turn == "o" ~ paste(leg_num.o, leg_num.d, sep = "->"),
        turn == "i" ~ "internal",
        TRUE ~ paste0(leg_dir.o, turn)
      )) %>% 
    transmute(
      from,
      to,
      rel = NA,
      intersection = intersection.o,
      turn,
      movement
    )
  
  net <- create_graph(nodes, edges)
  
  net
}