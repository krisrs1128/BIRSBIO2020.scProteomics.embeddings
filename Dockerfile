FROM bioconductor/bioconductor_docker:devel

WORKDIR /home/rstudio

COPY --chown=rstudio:rstudio . /home/rstudio/

RUN apt-get update
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update
RUN apt-get install -y python3.6

RUN Rscript -e "options(repos = c(CRAN = 'https://cran.r-project.org')); BiocManager::install(ask=FALSE)"
RUN Rscript -e "install.packages('igraph')"
RUN Rscript -e "install.packages(c('dplyr', 'ggplot2', 'scales', 'pracma', 'raster', 'readr', 'reshape2', 'shiny', 'spdep', 'stars', 'sf', 'viridis', 'forcats', 'tidyr'))"
RUN Rscript -e "install.packages(c('umap', 'tensorflow', 'keras', 'htmlwidgets'))"
RUN Rscript -e "tensorflow::install_tensorflow()"
RUN Rscript -e "install.packages(c('glmnet', 'caret', 'randomForest', 'randomForestSRC'))"
RUN Rscript -e "BiocManager::install('SingleCellExperiment', ask=FALSE)"
RUN Rscript -e "options(repos = c(CRAN = 'https://cran.r-project.org')); devtools::install('.', dependencies=TRUE, build_vignettes=TRUE, repos = BiocManager::repositories())"
