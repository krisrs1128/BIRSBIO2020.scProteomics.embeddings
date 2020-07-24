# Embeddings in Integrative Analysis of Spatial 'omics

It used to be the case that, to obtain measurements of a biological system, one
had to be something of a specialist in the particular sensing technology. Even
if a technology produced a very high-dimensional description of a system, you
would only typically have one of these types of data to have to analyze at a
time.

Now, in contrast, a broad array of sensing technologies are easily accessible,
and it's not uncommon for a researcher interested in a system to obtain several
complementary views using several technologies. This is the starting point for
integrative analysis.

This package describes analysis done for the workshop [Mathematical Frameworks
for Integrative Analysis of Emerging Biological Data
Types](https://www.birs.ca/events/2020/5-day-workshops/20w5197). The original
data and questions are described
[https://github.com/BIRSBiointegration/Hackathon/tree/master/sc-targeted-proteomics](here).
These analysis formed the basis of a short
[talk](https://drive.google.com/file/d/1PHaiz7yGJcF8d8Sym0Aj9vN1jo8ltz6g/view?usp=sharing).

The running theme across the four vignettes included here is that each
measurement technology gives a slightly different view of the same overall
system. Our goal is to measure the extent to which these different views give
redundant vs. orthogonal information. Which combinations of sensing technologies
are likely to give the most diverse set of findings, or the strongest evidence
for conclusions, about a single underlying system?

The primary methodological device used across the vignettes is the reduction of
raw data into directly inspectable features. These representations are easier to
work with than raw pixel values, say, and they facilitate statistical analysis
of the relationship between data sources.

The different vignettes have different emphases,
* *Deriving Graph and Image Features* shows how to build meaningful features
  manually, based on source MIBI-TOF raster data.
* *Interactive Visualization using Linked Views* considers the use of
  visualization interfaces to streamline inspection of learned cell atlases.
* *Disentangling Composition and Ecological Effects* is focused on the extent to
  which ecological features of a sample can be recovered from the cells that it
  contains.
* *Mapping between Cell-Level Embeddings* considers the analogous problem at the
  cellular level.

# Running the code

The goal of packaging these analysis is to make them easy to rerun with minimal
effort. You don't even need to download R -- just pull the docker image and
enter the vignettes. Specifically, pull and run the docker image using,

```sh
docker run -e PASSWORD=<make_up_a_password_here> -p 8787:8787 krisrs1128/birs2020_scproteomics_embeddings
```

and then navigate to [localhost:8787](localhost:8787) and enter username =
rstudio and password = your password. In the console, install all dependencies
using `remotes::install_deps(dependencies = TRUE, repos = BiocManager::repositories())`. 
Then, you can then browse to the vignettes folder and run all the analysis on
this site.
