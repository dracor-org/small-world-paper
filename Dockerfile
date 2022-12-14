#need to specify version of dockerized R
FROM rocker/verse:4
# set the API base
ENV DRACOR_APIBASE=http://localhost:8088/api/
# set environment variable corpusname
ENV CORPUSNAME=vebi
#install the packages; should also later use designated versions!
RUN R -e "install.packages(c('purrr', 'igraph', 'stringr', 'jsonlite', 'dplyr'))"
#add the script to use in R Studio server instance
ADD smallworlds-script.R  /home/rstudio/smallworlds-script.R
#create an export folder for the results
RUN mkdir /home/rstudio/export
#expose the port
EXPOSE 8787
