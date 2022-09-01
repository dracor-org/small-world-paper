# Detecting Small Worlds in a Corpus of Thousands of Theater Plays – A DraCor Study in Comparative Literary Network Analysis

This repository contains the code and data used for the paper presented at the "Workshop on Computational Drama Analysis" (September 2022) at Cologne University.

## Abstract

Although homogenized TEI corpora of plays from different languages are becoming more and more available, research on plays with a comparative angle is still rare in the field of Computational Literary Studies (CLS). This is where approaches of formal network analysis come into play, which have been elaborated in recent years in particular with focus on theater plays. They bear huge potential for comparative research due to their modeling of texts as asemantic structures. An attempt to integrate the paradigm of such a formal analysis with general network research on the one hand and literary history on the other hand is the approach of a typification of networks with respect to the “Small World” concept. However, studies have so far remained limited to smaller and monolingual corpora. In this study, we conceptualize different operationalizations of the “Small World” concept and apply the measures to a larger, DraCor-based corpus of almost 3,000 plays. Looking at the results of these analyses, we examine how the different operationalizations of the “Small World” concept relate to each other and discuss how they could be used for a network-based typology of dramatic forms. We finally develop initial ideas for a network-grounded history of dramatic forms in a transnational perspective.

## Code used for the analysis

Calculations were made using the R script `conference-version-script.R`. It consists of three parts:

* reading all necessary data and combining it into one dataframe, 
* intermediate calculations of values for the criteria, 
* and checking of conditions of different tests.

The file `results/results.csv` contains the output of the script, that is further discussed in the paper.

## Further work
The branch [`develop`](https://github.com/dracor-org/small-world-paper/tree/develop) contains the current state of data and code of the workflow creating a fully reproducible study using Docker and the "Programmable Corpus" prototype of our Very Big Drama Corpus [VeBiDraCor](https://github.com/dracor-org/vebidracor).