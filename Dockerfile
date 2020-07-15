FROM r-base

RUN apt-get update
RUN apt-get install -y software-properties-common libgdal-dev gfortran libudunits2-dev
RUN Rscript -e "install.packages(c('spdep', 'raster'))"
RUN Rscript -e "install.packages(c('devtools', 'dplyr', 'reshape2', 'viridis', 'igraph', 'glmnet', 'stars', 'forcats', 'tidyr', 'plotly', 'stringr', 'umap'))"
RUN Rscript -e "devtools::install('.', dependencies=TRUE, build_vignettes=TRUE, repos = BiocManager::repositories())"
