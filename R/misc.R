# Misc functions

#' Wrapper for gtools::permutations() with sane syntax
perm <- function(v, r, n = length(v), set = TRUE, repeats.allowed = FALSE){
  gtools::permutations(n, r, v, set, repeats.allowed)
}

#' Vectorize DiagrammeR::get_paths() for use in dplyr verbs
get_shortest_path <- Vectorize(
  function(graph, from, to){
    DiagrammeR::get_paths(graph, from, to, shortest_path = TRUE)[[1]]
  },
  vectorize.args = c("from", "to")
)
