# Use the official R Shiny image as a base
FROM rocker/shiny:latest

# Install system dependencies for Quarto CLI and other required packages
RUN apt-get update && apt-get install -y \
    curl \
    pandoc \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libxt-dev \
    zlib1g-dev

# Install Quarto CLI
RUN curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb && \
    dpkg -i quarto-linux-amd64.deb && \
    rm quarto-linux-amd64.deb

# Copy your app code to the Docker image
COPY . /srv/shiny-server/

# Install R packages (e.g., quarto package)
RUN R -e "install.packages('remotes')" && \
    R -e "remotes::install_cran('shiny')" && \
    R -e "remotes::install_cran('quarto')" && \
    R -e "remotes::install_cran('bslib')" && \
    R -e "remotes::install_cran('bsicons')" && \
    R -e "remotes::install_cran('httr2')" && \
    R -e "remotes::install_cran('base64enc')"

# Set the working directory
WORKDIR /srv/shiny-server/

# Expose the port for the Shiny app
EXPOSE 3838

# Run the Shiny app
CMD ["/usr/bin/shiny-server"]
