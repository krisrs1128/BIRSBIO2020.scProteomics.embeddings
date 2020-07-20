#' Interactive Linked_Viewss
#'
#' @import htmlwidgets
#' @export
linked_views <- function(message, width = 60, height = 20, elementId = NULL) {
  print("testing...")
  htmlwidgets::createWidget(
    name = "linked_views",
    list(message = message),
    width = width,
    height = height,
    elementId  = elementId,
    package = "BIRSBIO2020.scProteomics.embeddings"
  )
}
