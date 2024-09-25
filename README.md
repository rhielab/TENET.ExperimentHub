# TENET.ExperimentHub

### ExperimentHub package containing datasets for use in the TENET package's function examples and vignettes

# Introduction

The TENET.ExperimentHub package contains 6 datasets for use in the [TENET](https://github.com/rhielab/TENET) package's examples and vignettes. These datasets include an example MultiAssayExperiment object with matched gene expression and DNA methylation data from a subset of both tumor (case) and adjacent normal (control) samples in The Cancer Genome Atlas (TCGA)'s breast adenocarcinoma (BRCA) cohort with essential information used in all TENET functions, an example GRanges object produced by the TENET `step1MakeExternalDatasets` function, a SummarizedExperiment object with example purity data to pass to the TENET `step2GetDifferentiallyMethylatedSites` function, a data frame with example patient clinical data (matching the data in the example MultiAssayExperiment object), and two additional GRanges objects containing example peak and topologically associating domain (TAD) data, respectively. Where applicable, all datasets are aligned to the hg38 human genome.

# Acquiring and installing TENET.ExperimentHub

R 4.4 or a newer version is required.

On Ubuntu 22.04, installation was successful in a fresh R environment after adding the official R Ubuntu repository using the instructions at <https://cran.r-project.org/bin/linux/ubuntu/> and running the following command in a terminal:

`sudo apt-get install r-base-core r-base-dev libcurl4-openssl-dev libfreetype6-dev libfribidi-dev libfontconfig1-dev libharfbuzz-dev libtiff5-dev libxml2-dev`

No dependencies other than R are required on macOS or Windows.

Two versions of this package are available.

To install the stable version from Bioconductor, start R and run:

```r
## Install BiocManager, which is required to install packages from Bioconductor
if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
}

BiocManager::install(version = "devel")
BiocManager::install("TENET.ExperimentHub")
```
The development version containing the most recent updates is available from [our GitHub repository](https://github.com/rhielab/TENET.ExperimentHub).

To install the development version from GitHub, start R and run:

```r
## Install prerequisite packages to install the development version from GitHub
if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
}
if (!requireNamespace("remotes", quietly = TRUE)) {
    install.packages("remotes")
}

BiocManager::install(version = "devel")
BiocManager::install("rhielab/TENET.ExperimentHub")
```

# Loading TENET.ExperimentHub

To load the TENET.ExperimentHub package, start R and run:

```r
library(TENET.ExperimentHub)
```

# Using the included datasets

Wrapper functions are provided to allow easy access to all included datasets. See the vignette for more details.

## [Package documentation and vignette](https://bioconductor.org/packages/devel/data/experiment/html/TENET.ExperimentHub.html)
