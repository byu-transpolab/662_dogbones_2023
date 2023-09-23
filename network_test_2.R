library(tidyverse)
library(DiagrammeR)

nodes <-
  tibble(
    id = c(1001:1003, 1011:1014, 1021:1025, 1031, 1033, 1034),
    label = as.character(id)
  ) %>% 
  mutate(
    type = case_when(
      id %in% c(1003, 1031) ~ "out", #most N and most S
      str_detect(id, "1$|3$") ~ "in",
      TRUE ~ "out"),
    .after = id
  )

edges <- read_csv("data/edges_existing.csv", comment = "#")

create_graph(nodes, edges) %>% 
  render_graph()
