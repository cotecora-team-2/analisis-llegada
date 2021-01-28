FROM rocker/verse:4.0.3

# Geoespacial

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    lbzip2 \
    libfftw3-dev \
    libgdal-dev \
    libgeos-dev \
    libgsl0-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    libjq-dev \
#    liblwgeom-dev \
    libpq-dev \
    libproj-dev \
    libprotobuf-dev \
    libnetcdf-dev \
    libsqlite3-dev \
    libssl-dev \
    libudunits2-dev \
    netcdf-bin \
    postgis \
    protobuf-compiler \
    sqlite3 \
    tk-dev \
    unixodbc-dev

RUN install2.r --error \
    RColorBrewer \
    RandomFields \
    RNetCDF \
    classInt \
    deldir \
    gstat \
    hdf5r \
    lidR \
    mapdata \
    maptools \
    mapview \
    ncdf4 \
    proj4 \
    raster \
    rgdal \
    rgeos \
    rlas \
    sf \
    sp \
    spacetime \
    spatstat \
    spdep \
    geoR \
    geosphere \
    ## from bioconductor
    && R -e "BiocManager::install('rhdf5', update=FALSE, ask=FALSE)"


# Global site-wide config -- neeeded for building packages
RUN mkdir -p $HOME/.R/ \
    && echo "CXXFLAGS=-O3 -mtune=native -march=native -Wno-unused-variable -Wno-unused-function -flto -ffat-lto-objects  -Wno-unused-local-typedefs \n" >> $HOME/.R/Makevars

# Config for rstudio user
USER rstudio
RUN mkdir -p /home/rstudio/.R
RUN touch /home/rstudio/.R/Makevars
RUN r -e 'cat("\nCXX14FLAGS=-O3 -march=native -mtune=native -fPIC", "CXX14=g++", file = "/home/rstudio/.R/Makevars", sep = "\n", append = TRUE)'
USER root


# stan
RUN r -e 'install.packages("cmdstanr", repos = c("https://mc-stan.org/r-packages/", getOption("repos")))'
RUN install2.r --error --deps TRUE\
	rstan bayesplot loo \
	rstanarm rstantools shinystan

USER rstudio
COPY ./install_cmdstan.R /home/rstudio/install_cmdstan.R
WORKDIR /home/rstudio
RUN Rscript install_cmdstan.R
USER root

RUN install2.r --error \
    patchwork survminer
