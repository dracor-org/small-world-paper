# Detecting Small Worlds in a Corpus of Thousands of Theater Plays – A DraCor Study in Comparative Literary Network Analysis

## Abstract

While homogenized TEI corpora of plays from different languages are becoming more and more available, there has been almost no comparative research on plays in the field of Computational Literary Studies (CLS). Yet the approach of formal network analysis, which has been elaborated in recent years in particular with focus on theatre plays, bears huge potential for comparative research due to its modeling of texts as asemantic structures. An attempt to integrate the paradigm of such a formal analysis with general network research on the one hand and literary history on the other hand is the approach of a typification of networks with respect to the “Small World” concept. However, studies have so far remained limited to smaller and monolingual corpora. In this study, we conceptualize different operationalizations of the “Small World” concept and apply the measures to a quite huge, DraCor based corpus of almost 3000 plays. Looking at the results of these analyses, we examine how the different operationalizations of the “Small World” concept relate to each other and discuss how they could be used for a network-based typology of dramatic forms. We finally develop initial ideas for a network-grounded history of dramatic forms in a transnational perspective.

## About this repository

This repository contains the current state of the code and data that will be used to prepare the final version of the paper. The script and data that was used for the conference version is contained in the branch [`conference-version`](https://github.com/dracor-org/small-world-paper/tree/conference-version).

## Corpus
(todo: add notes on the corpus, link to VeBiDraCor – https://github.com/dracor-org/vebidracor)

## Results of the analysis

The results of the analysis are contained in the file `results.csv` in the `results` folder.

## Some Notes on re-doing the analysis

A user wanting to reproduce the analysis or build on the results has two options to re-create the whole environment using the provided docker-compose files (1) `docker-compose.pre.yml` and (2) `docker-compose.post.yml` as described below. It is necessary to have Docker and docker-compose installed.

### (1) Pre-analysis state

To setup the environment in the state before the analysis was run use the command `docker-compose -f docker-compose.pre.yml up`. This will (by default) create the following containers as defined in the compose-file:

* Programmable corpus VeBiDraCor (exist-DB with plays loaded)
* DraCor frontend http://localhost:8088
* RStudio server instance (using a Docker image from the [Rocker Project](https://rocker-project.org)) with the packages pre-installed. It can be accessed at http://localhost:8787 (user: `rstudio` password: `smallworld`)

The script `smallworlds-script.R` used to generate the metics for the plays is loaded to RStudio container. From inside RStudio the VeBiDraCor container and the API of thecan be reached via http://frontend:80/api/info or http://api:8080/exist/restxq/info. The provided docker-compose file will set the environment variable accordingly.

The script will run and store the csv file containing the results of the analysis `results.csv` in the folder `results` which is mapped to the host machine.

Using the pre-analysis state would allow a user to change the version of the data used for the analyis, e.g. use another version of VeBiDraCor or even another one of the DraCor corpora. This can be achived by changing the image of the `api` service [here](https://github.com/dracor-org/small-world-paper/blob/develop/docker-compose.pre.yml#L4) and possibly setting the environment variable `DRACOR_CORPUSNAME` in the part defining the `rstudio` service accordingly.

### (2) Post-analysis state
To setup the environment in the state after the analysis was run use the command `docker-compose -f docker-compose.post.yml up`.

### Creating and pushing a post-analysis image to dockerhub

We propose the following workflow to store the state after the analysis was run: after commiting the `results.csv` to the repository, get the short HEAD hash to use as tag for the container as well `git rev-parse --short HEAD` To get the id of the container use `docker ps | grep smallworld`; then commit the container and tag it using the commit hash as version-tag:
`docker commit -m "ran analysis, created results.csv based on commit {commithash}" {container-id} ingoboerner/smallworld-rstudio:{commithash}`. Push the image to dockerhub: `docker push ingoboerner/smallworld-rstudio:{commithash}`