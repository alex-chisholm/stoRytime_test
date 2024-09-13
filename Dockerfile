FROM rocker/shiny:4.3.2
ENV RENV_CONFIG_REPOS_OVERRIDE https://packagemanager.rstudio.com/cran/latest

# Install system dependencies including Quarto CLI
RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libicu-dev \
    libssl-dev \
    libxml2-dev \
    make \
    pandoc \
    zlib1g-dev \
    wget && \
  wget https://github.com/quarto-dev/quarto-cli/releases/download/v1.5.57/quarto-1.5.57-linux-amd64.deb && \
  dpkg -i quarto-1.5.57-linux-amd64.deb && \
  rm quarto-1.5.57-linux-amd64.deb && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Copy and restore renv environment
COPY shiny_renv.lock renv.lock
RUN Rscript -e "install.packages('renv')"
RUN Rscript -e "renv::restore()"

# Copy Shiny app to server directory
COPY . /srv/shiny-server/

EXPOSE 3838

# Start Shiny server
CMD ["/usr/bin/shiny-server"]

