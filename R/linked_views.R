#' Interactive Linked_Viewss
#'
#' @import htmlwidgets
#' @export
linked_views <- function(polys, dimred, width = 400, height = 130, elementId = NULL) {
  print("testing...")
  htmlwidgets::createWidget(
    name = "linked_views",
    list(polys = polys, dimred = dimred),
    width = width,
    height = height,
    elementId  = elementId,
    package = "BIRSBIO2020.scProteomics.embeddings"
  )
}
