## Overview
In this showcase, we take the “Small World” concept from general network theory (introduced by Duncan J. Watts and Steven H. Strogatz) and try to identify "Small World"-structured texts in a huge multilingual corpus of almost 3,000 plays. We then analyze the distribution with regard to the different national language corpora (shown in Figure) and with regard to the temporal dimension (shown in Figure). The showcase is based on the methods and the results provided in this repository: https://github.com/dracor-org/small-world-paper 

## Operationalization of the small world concept
We operationalize the small world concept in two ways:
1. Assuming a broad understanding of small world and defining it as a continuous term, which is based on a value for so-called "small-world-ness" (swn) (Humphries and Gurney, 2008).
2. Assuming a narrow understanding of "small world" and concepztualizing it as a categorical term (cf. Trilcke et al. 2016). This is tested with:
  * the small world test (swt), which considers small worlds to be a rare, structurally exceptional phenomenon,
  * the scale-free test (sft): a specific variant of small world described by Albert and Barabási (2002)

The tests are based on measures from social network analysis (clustering coefficient, average path length, node degree distribution) for each play.  

## Research question(s) and objective(s)
* Which theater plays in a huge multilingual corpus can be typified as "Small Worlds"?
* What are the descriptive benefits and limitations of different conceptualizations of dramatic small worlds?
* What is the historical distribution of the "dramatic small worlds" in our huge multilingual corpus?

## Data
For our analyses we use VeBiDraCor - our "very big drama corpus", which we created by aggregating all individual corpora available through [DraCor](https://dracor.org). VeBiDraCor was created on August 09, 2022 using a dedicated, fully functional Docker image of DraCor (incl. metrics services and API functions). Cf. https://github.com/dracor-org/vebidracor
