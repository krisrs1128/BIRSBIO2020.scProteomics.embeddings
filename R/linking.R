
#' Visualize Linked Data
#'
#' @export
linked_views <- function(polys, dimred, width = NULL, height = NULL, display_opts = list()) {
  x <- list(polys, dimred)
  htmlwidgets::createWidget(
    name = "linked_views",
    x,
    width = width,
    height = height,
    package = "linking"
  )
}
