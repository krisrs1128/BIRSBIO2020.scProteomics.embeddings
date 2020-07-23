#' Interactive Linked_Viewss
#'
#' @param polys A geojson object containing the cell coordinates.
#' @param dimred A dataframe with columns V1 and V2 containing the U-Map layout
#'   of the cells.
#' @param width The width of the output visualization.
#' @param height The width of the output visualization.
#' @param elementId The ID of the new htmlwidgets element within which to put
#'   the vis.
#' @import htmlwidgets
#' @export
linked_views <- function(polys, dimred, width = 900, height = 450, elementId = NULL) {
  htmlwidgets::createWidget(
    name = "linked_views",
    list(polys = polys, dimred = dimred),
    width = width,
    height = height,
    elementId  = elementId,
    package = "BIRSBIO2020.scProteomics.embeddings"
  )
}
