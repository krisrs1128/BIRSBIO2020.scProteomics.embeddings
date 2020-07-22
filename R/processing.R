
unify_row_data <- function(row_data_list) {
  do.call(rbind, row_data_list) %>%
    as_tibble() %>%
    unique() %>%
    arrange(channel_name, marker_name)
}

unify_col_data <- function(col_data_list) {
  col_union <- lapply(col_data_list, function(x) as_tibble(colData(x)))
  bind_rows(col_union, .id = "cell_type") %>%
    select(sample_id, starts_with("patient"), everything()) %>%
    select(-file_name) %>%
    mutate_at(vars(matches("Age|percent|Score")), as.numeric) %>%
    mutate_at(vars(-matches("Age|percent|Score")), as_factor)
}

subsample_experiments <- function(x_list, p_keep = 0.05) {
  for (i in seq_along(x_list)) {
    D <- ncol(x_list[[i]])
    sample_ix <- sample(D, D * p_keep, replace = FALSE)
    x_list[[i]] <- x_list[[i]][, sample_ix]
  }
  x_list
}

#' Download Data for Experiments
#'
#' Attempts to download data to directory if it's not already found.
#' @param directory Directory to which all the data is downloaded.
#' @export
download_data <- function(directory) {
  dir.create(directory, recursive = TRUE)
  data_paths <- list(
    file.path(directory, "mibiSCE.rda"),
    file.path(directory, "masstagSCE.rda"),
    file.path(directory, "TNBC_shareCellData")
  )

  if (!file.exists(data_paths[[1]])) {
    download.file("https://uwmadison.box.com/shared/static/yl667qrpgr53l9iw7t1bmnmlk6v99n4o.rda", data_paths[[1]])
  }

  if (!file.exists(data_paths[[2]])) {
    download.file("https://uwmadison.box.com/shared/static/hcb7i89v5xn90vdf3d5hc0z62rdb1jp9.rda3", data_paths[[2]])
  }

  if (!file.exists(data_paths[[3]])) {
    zip_path <- file.path(directory, "tnbc.zip")
    download.file("https://ff46df02-0fce-4001-88ae-41336ee05310.filesusr.com/archives/302cbc_72cbeda2c99342c0a1b3940d6bac144f.zip?dn=TNBC_shareCellData.zip", zip_path)
    dir.create(data_paths[[3]])
    unzip(zip_path, exdir = data_paths[[3]])
  }

  data_paths
}

#' Wrapper to get SCE data
#' @export
data_list <- function(pattern) {
  global <- ls(envir = .GlobalEnv)
  cell_types <- global[grep(pattern, global)]
  x <- lapply(cell_types, get)
  names(x) <- cell_types
  x
}

#' Polygonize a Raster Image
#'
#'  Light wrapper around stars::st_as_stars
#' @importFrom stars st_as_stars
#' @importFrom sf st_as_sf st_cast st_buffer
#' @importFrom dplyr mutate group_by summarise select n
#' @export
polygonize <- function(im) {
  polys <- st_as_stars(im) %>%
    st_as_sf(merge = TRUE) %>%
    st_cast("POLYGON")

  colnames(polys)[1] <- "cellLabelInImage"
  polys %>%
    mutate(geometry = st_buffer(geometry, dist = 0)) %>%
    group_by(cellLabelInImage) %>%
    summarise(n_polys = n(), .groups = "drop") %>%
    select(-n_polys)
}

#' Proportion of image that's Background
#'
#' This is an example of a function that can be called in `loop_stats`.
#' @export
background_prop <- function(x, ...) {
  if (nrow(x) == 0) { # case of no neighbors
    return (tibble(immuneGroup = NA, props = NA))
  }

  props <- table(x$cellLabelInImage %in% c(0, 1))
  tibble(background = names(props), props = as.numeric(props / sum(props)))
}

#' Proportion of Cell Types
#' 
#' Function to extract proportion of cell types within each subgraph.
#' @export
type_props <- function(x, ...) {
  if (nrow(x) == 0) { # case of no neighbors
    return (tibble(cell_type = NA, props = NA))
  }

  props <- table(x$cell_type, useNA = "ifany")
  tibble(cellType = names(props), props = as.numeric(props) / sum(props)) %>%
    filter(props != 0)
}

#' Helper to get Cell Type
#'
#' Combines the tumor and immune group variables into a generic cell type.
#'
#' @param exper A SummarizedExperiment representation of the MIBI data.
#' @importFrom SummarizedExperiment colData
#' @importFrom forcats as_factor
#' @importFrom dplyr select mutate
#' @export
cell_type <- function(exper) {
  colData(exper) %>%
    as.data.frame() %>%
    select(tumor_group, immune_group) %>%
    mutate(
      cell_type = paste0(tumor_group, immune_group),
      cell_type = gsub("not immune", "", cell_type),
      cell_type = gsub("Immune", "", cell_type),
      ) %>%
    .[["cell_type"]] %>%
    as_factor()
}

#' Apply fun to Graph Neighborhoods
#'
#' @param cell_id The ID of the cell to extract a local neighborhood around.
#' @param G The graph object giving the connections between cell_ids.
#' @param polys A spatial data.frame with a column (geometry) giving the spatial
#'   geometry of each cell.
#' @param fun A function that can be applied to a data.frame whose rows are
#'   pixels and whose columns give features of those pixels (e.g., immune
#'   group).
#' @importFrom igraph neighbors
#' @importFrom dplyr filter group_map mutate select everything
#' @return result A tibble mapping the cell to statistics calculated by fun.
graph_stats_cell <- function(cell_id, G, polys, fun, ...) {
  ball <- neighbors(G, as.character(cell_id))
  cell_stats <- polys %>%
    filter(cellLabelInImage %in% names(ball)) %>%
    group_map(fun)

  cell_stats[[1]] %>%
    mutate(cellLabelInImage = cell_id) %>%
    select(cellLabelInImage, everything())
}

#' Extract a KNN Graph from Polygons
#'
#' Sometimes we want to put neighboring polygons into one big graph.
#' @param geometries The data.frame containing the polygons and their labels.
#' @param K The number of nearest neighbors to which each polygon will be
#'   linked.
#' @importFrom spdep knn2nb knearneigh
#' @importFrom sf st_centroid
#' @importFrom pracma distmat
#' @importFrom igraph graph_from_data_frame
#' @importFrom dplyr bind_rows
#' @export
extract_graph <- function(geometries, K = 5) {
  nb <- knn2nb(knearneigh(st_centroid(geometries), K)
  )
  labels <- unique(geometries$cellLabelInImage)
  dists <- sapply(geometries$geometry, st_centroid) %>%
    t()

  relations_data <- list()
  for (i in seq_along(nb)) {
    relations_data[[i]] <- tibble(
      from = labels[i],
      to = labels[nb[[i]]]
    )

    relations_data[[i]]$dist <- distmat(
      dists[i, ], dists[nb[[i]], ]
    ) %>%
      as.numeric()
  }

  relations_data <- bind_rows(relations_data)
  graph_from_data_frame(relations_data, labels)
}

#' Apply fun to Local Neighborhoods
#'
#' @param cell_id The ID of the cell to extract a local neighborhood around.
#' @param im The raster object giving the pixel-level information about the
#'   sample.
#' @param polys A spatial data.frame with a column (geometry) giving the spatial
#'   geometry of each cell.
#' @param fun A function that can be applied to a data.frame whose rows are
#'   pixels and whose columns give features of those pixels (e.g., immune
#'   group).
#' @param buffer_radius The size of the window around cell_id, to use to subset
#'   the raster on which to apply fun.
#' @param plot_masks If you want to see what the subsets of cells looks like,
#'   you can use this.
#' @return result A tibble mapping the cell to statistics calculated by fun.
#' @importFrom dplyr filter select left_join group_map mutate everything
#' @importFrom raster mask as.matrix
#' @importFrom reshape2 melt
#' @importFrom sf st_centroid st_buffer as_Spatial
#' @importFrom sp plot
raster_stats_cell <- function(cell_id, im, polys, fun, buffer_radius=90,
                              plot_masks=TRUE) {
  sub_poly <- polys %>%
    filter(cellLabelInImage == cell_id) %>%
    select(geometry) %>%
    st_centroid() %>%
    st_buffer(dist = buffer_radius)

  im_ <- mask(im, as_Spatial(sub_poly))
  if (plot_masks) {
    plot(im_)
  }

  melted_im <- as.matrix(im_) %>%
    melt(na.rm = TRUE, value.name = "cellLabelInImage") %>%
    left_join(polys, by = "cellLabelInImage") %>%
    group_map(fun)

  melted_im[[1]] %>%
    mutate(cellLabelInImage = cell_id) %>%
    select(cellLabelInImage, everything())
}

#' Wrapper for Local Statistics
#'
#' Loop functions that can be applied on a cell by cell basis.
#'
#' @param cell_ids A vector of cell IDs on which to apply a function to
#' @param type Either "raster" or "graph". Specifies the types of neighborhoods
#'   (image or graph) on which to compute statistics.
#' @importFrom dplyr bind_rows
#' @export
loop_stats <- function(cell_ids, type="raster", ...) {
  cell_fun <- ifelse(type == "raster", raster_stats_cell, graph_stats_cell)

  result <- list()
  for (i in seq_along(cell_ids)) {
    result[[i]] <- cell_fun(cell_ids[i], ...)
  }

  bind_rows(result)
}

#' Multitask Regression Model
#'
#' @importFrom keras keras_model_sequential layer_dense layer_activation compile optimizer_adam
#' @export
generate_model <- function(n_ft) {
  keras_model_sequential() %>%
    layer_dense(units = 32, input_shape = n_ft) %>%
    layer_activation("relu") %>%
    layer_dense(units = 32, input_shape = 32) %>%
    layer_activation("relu") %>%
    layer_dense(units = 32, input_shape = 32) %>%
    layer_activation("relu") %>%
    layer_dense(units = 32, input_shape = 32) %>%
    layer_activation("relu") %>%
    layer_dense(units = 32, input_shape = 32) %>%
    layer_activation("relu") %>%
    layer_dense(units = 2) %>%
    compile(optimizer = optimizer_adam(lr = 1e-2), loss = "mae")
}

#' Load MIBI-ToF into List
#'
#' Helper function to load MIBI-TOF data.
#'
#' @param data_dir The directory containing the MIBI single cell binary as well
#'   as a directory containing all rasters.
#' @param n_paths If you want to subsample to a small number of images, set the
#'   limit to n_paths.
#' @importFrom stringr str_extract
#' @importFrom SingleCellExperiment colData
#' @export
load_mibi <- function(data_dir, n_paths = NULL) {
  load(file.path(data_dir, "mibiSCE.rda"))
  tiff_paths <- list.files(
    file.path(data_dir, "TNBC_shareCellData"),
    "*.tiff",
    full = T
  )

  if (is.null(n_paths)) {
    n_paths <- length(tiff_paths)
  }

  tiff_paths <- tiff_paths[1:n_paths]
  sample_names <- str_extract(tiff_paths, "[0-9]+")
  list(
    tiffs = tiff_paths,
    mibi = mibi.sce[, colData(mibi.sce)$SampleID %in% sample_names]
  )
}

#' Subsample Rasters
#'
#' This lets you subsample a large raster image and the associated experiment
#' object, for quicker experimentation.
#' @param tiff_paths The paths containing the full raster images.
#' @param exper A summarized experiment object, containing measurements for each
#'   cell.
#' @param qsize How large should the rasters be?
#' @importFrom dplyr rename select
#' @importFrom raster raster crop extent unique
#' @importFrom stringr str_extract
#' @importFrom tidyr unite
#' @export
spatial_subsample <- function(tiff_paths, exper, qsize=500) {
  ims <- list()
  for (i in seq_along(tiff_paths)) {
    print(paste0("cropping ", i, "/", length(tiff_paths)))
    r <- raster(tiff_paths[[i]])
    ims[[i]] <- crop(r, extent(1, qsize, 1, qsize))
  }

  names(ims) <- str_extract(tiff_paths, "[0-9]+")
  cur_cells <- sapply(ims, unique) %>%
    melt() %>%
    rename(cellLabelInImage = "value", SampleID = "L1") %>%
    unite(sample_by_cell, SampleID, cellLabelInImage, remove = F)

  scell <- colData(exper) %>%
    as.data.frame() %>%
    select(SampleID, cellLabelInImage) %>%
    unite(sample_by_cell, SampleID, cellLabelInImage) %>%
    .[["sample_by_cell"]]

  list(
    ims = ims,
    exper = exper[, scell %in% cur_cells$sample_by_cell]
  )
}

#' Division of Samples into Clusters
#'
#' Get each samples' distribution across clusters.
#'
#' @param SampleID The sample IDs associated with each cell.
#' @param cluster The cluster membership of each cell.
#' @export
sample_proportions <- function(SampleID, cluster) {
  tab <- table(SampleID, cluster)
  props <- tab / rowSums(tab)
  props[hclust(dist(props))$order, ]
}

#' All Subgraphs of a Graph
#'
#' @param G A graph whose subgraphs we want to find.
#' @param order The size of the subgraphs.
#' @importFrom igraph ego induced_subgraph
#' @export
subgraphs <- function(G, order = 3) {
  ids <- V(G)
  SG <- list()

  for (i in seq_along(ids)) {
    ball <- do.call(c, ego(G, ids[[i]], order = order))
    SG[[i]] <- induced_subgraph(G, ball)
  }

  names(SG) <- ids
  SG
}

#' Cluster Entropy of Subgraphs
#'
#' How much variation in cluster memberships does each subgraph have?
#'
#' @param G A graph whose subgraphs we want to find.
#' @param clusters_ The cluster membership of each cell. Indices must correspond
#'   to indices of V(G).
#' @export
entropies <- function(G, clusters_) {
  ents <- list()
  for (g in seq_along(G)) {
    counts <- table(clusters_[names(V(G[[g]]))])
    fq <- counts / sum(counts)
    ents[[g]] <- -sum(fq * log(fq))
  }

  do.call(c, ents)
}

#' Average Pairwise Distance within Subgraphs
#'
#' @param G A graph whose subgraphs we want to find.
#' @export
avg_dists <- function(G) {
  dists <- list()

  for (g in seq_along(G)) {
    dists[[g]] <- mean(edge_attr(G[[g]], "dist"))
  }

  do.call(c, dists)
}

#' Helper to Plot Model Results
#' @export
plot_fits <- function(x, y, glmnet_fit, rf_fit) {
  y_hat <- predict(glmnet_fit, x)
  plot(y, y_hat, ylim = range(y), xlim = range(y))
  abline(0, 1)
  y_hat <- predict(rf_fit, x)
  points(y, y_hat, col = "red")
}

#' Helper to Fit Models
#' @importFrom caret train
#' @importFrom glmnet cv.glmnet
#' @export
fit_wrapper <- function(x, y) {
  glmnet_fit <- cv.glmnet(x, y)
  plot(glmnet_fit)
  rf_fit <- train(x, y)
  print(rf_fit)
  list(rf = rf_fit, glmnet = glmnet_fit)
}
