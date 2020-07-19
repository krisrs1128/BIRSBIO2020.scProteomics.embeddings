FROM bioconductor/bioconductor_docker:devel

WORKDIR /home/rstudio

COPY --chown=rstudio:rstudio . /home/rstudio/

RUN Rscript -e "options(repos = c(CRAN = 'https://cran.r-project.org')); BiocManager::install(ask=FALSE)"
RUN Rscript -e "install.packages(c('dplyr', 'ggplot2', 'scales', 'igraph', 'pracma', 'raster', 'readr', 'reshape2', 'shiny', 'spdep', 'stars', 'sf', 'viridis', 'forecats', 'tidyr'))"
RUN Rscript -e "install.packages(c('umap', 'keras', 'htmlwidgets'))
RUN Rscript -e "BiocManager::install('SingleCellExperiment', ask=FALSE)
RUN Rscript -e "options(repos = c(CRAN = 'https://cran.r-project.org')); devtools::install('.', dependencies=TRUE, build_vignettes=TRUE, repos = BiocManager::repositories())"
