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

RUN Rscript -e "devtools::install()"