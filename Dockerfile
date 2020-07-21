FROM bioconductor/bioconductor_docker:devel

WORKDIR /home/rstudio

COPY --chown=rstudio:rstudio . /home/rstudio/

RUN apt-get update
RUN sudo apt-get install -y libglpk-dev
RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update
RUN apt-get install -y python3.7
RUN apt-get install -y libpython3.7-dev
RUN apt-get install -y python3-pip
RUN apt-get install -y python3-venv python3-virtualenv

RUN Rscript -e "install.packages(c('reticulate', 'tensorflow'))"
RUN Rscript -e "install.packages('keras')"
RUN Rscript -e "tensorflow::install_tensorflow(envname='/.virtualenvs/r-reticulate')"
RUN Rscript -e "install.packages('igraph')"
RUN Rscript -e "install.packages('rmarkdown')"
RUN Rscript -e "install.packages(c('dplyr', 'ggplot2', 'scales', 'pracma', 'raster', 'readr', 'reshape2', 'shiny', 'spdep', 'stars', 'sf', 'viridis', 'forcats', 'tidyr'))"
RUN Rscript -e "install.packages(c('umap', 'htmlwidgets', 'geojsonio', 'rmapshaper'))"
RUN Rscript -e "install.packages(c('glmnet', 'caret', 'randomForest', 'randomForestSRC'))"
RUN Rscript -e "BiocManager::install('SummarizedExperiment', ask=FALSE)"
RUN Rscript -e "BiocManager::install('SingleCellExperiment', ask=FALSE)"
RUN Rscript -e "devtools::install()"