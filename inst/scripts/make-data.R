### Necessary packages to create datasets

## TENET is required to generate the example TENET MultiAssayExperiment
if (!require("TENET", quietly = TRUE)) {
    stop("Please install the main TENET package before running this script.")
}

## BiocManager is required to install other dependencies
if (!require("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
}

## Switch Bioconductor to the development release
BiocManager::install(version = "devel", ask = FALSE)

## GenomicRanges is required to assemble the datasets
if (!require("GenomicRanges", quietly = TRUE)) {
    BiocManager::install("GenomicRanges")
}

## SummarizedExperiment is necessary as the example TENET dataset contains
## SummarizedExperiment objects
if (!require("SummarizedExperiment", quietly = TRUE)) {
    BiocManager::install("SummarizedExperiment")
}

## MultiAssayExperiment is necessary as the example TENET dataset is a
## MultiAssayExperiment object
if (!require("MultiAssayExperiment", quietly = TRUE)) {
    BiocManager::install("MultiAssayExperiment")
}

## TCGAbiolinks is required to download TCGA data to create some of the datasets
if (!require("TCGAbiolinks", quietly = TRUE)) {
    BiocManager::install("TCGAbiolinks")
}

## TCGAbiolinks requires sesameData to download methylation data, but
## does not depend on it for installation
if (!require("sesameData", quietly = TRUE)) {
    BiocManager::install("sesameData")
}

## S4Vectors::queryHits is required to do probe overlapping
if (!require("S4Vectors", quietly = TRUE)) {
    BiocManager::install("S4Vectors")
}

### Dataset descriptions

## Objects created by this script are used to illustrate examples in the
## functions and vignette of the TENET Bioconductor package.

## exampleTENETMultiAssayExperiment,
## exampleTENETClinicalDataFrame,
## exampleTENETStep1MakeExternalDatasetsGRanges,
## exampleTENETStep2GetDifferentiallyMethylatedSitesPuritySummarizedExperiment:

## For these datasets, functions in the TCGAbiolinks package are used to
## download The Cancer Genome Atlas's (TCGA) Breast Adenocarcinoma (BRCA)
## dataset, including gene expression, DNA methylation, and patient clinical
## data. Additionally, functions from the TENET package itself are utilized to
## create example datasets which can be used to illustrate functions further
## downstream in the TENET workflow.

## First, TCGA BRCA expression data were log-2 transformed and FPKM-UQ values
## were calculated, along with the most up-to-date survival information for
## each patient. Additionally, patients which lacked both methylation and
## expression data were removed, as well as data from duplicate tumor samples
## taken from the same patient (i.e. the first tumor sample per patient was kept
## by alphanumeric order of the sample barcodes).

## In order to reduce the size/complexity of the datasets (as they are
## meant for use as examples), we then subsetted the downloaded datasets. First,
## only 200 randomly selected tumor samples and half (42) of the adjacent normal
## samples were kept. Then, we identified probes which were located in distal
## enhancer regulatory elements (REs) relevant to BRCA using the TENET
## step1MakeExternalDatasets function. We sampled 10,000 of these RE probes
## along with an additional 10,000 probes which were not found within these
## regions, and subsetted the methylation data to just these probes (20,000
## total). Finally, the genes included in the gene expression dataset were also
## subsetted, with all annotated transcription factor (TF) genes being included,
## along with an additional 10,000 non-TF genes (11,637 total).

## The final exampleTENETMultiAssayExperiment object consists of two
## SummarizedExperiment objects "expression" and "methylation", which hold the
## matched, subsetted expression and methylation data from the BRCA patients.
## A mapping object has been included, which includes the standard "assay",
## "primary", and "colname" columns as well as an additional "sampleType"
## column, which notes whether each sample is a 'Case' or 'Control' sample.
## Additionally, each dataset has rowRanges with information on the position of
## each gene/probe in the human hg38 genome, but no colData on samples. Instead,
## patient data are contained in the colData of the outer MultiAssayExperiment
## object, and are mapped to each expression and methylation sample using the
## aforementioned mapping object.

## The exampleTENETClinicalDataFrame is a simple data frame that contains
## the same clinical information as the colData of the
## exampleTENETMultiAssayExperiment object. It is a seperate object used to
## illustrate the functionality of downstream TENET step 7 functions to load
## clinical data from a supplied data frame if it is not contained in the
## user's MultiAssayExperiment object.

## The exampleTENETStep1MakeExternalDatasetsGRanges dataset is a GRanges object
## which is a copy of the BRCA-relevant distal enhancer regions dataset used to
## identify RE probes for subsetting when creating the
## exampleTENETMultiAssayExperiment. It is used in examples for the
## step2GetDifferentiallyMethylatedSites function, which imports a GRanges
## object containing REs of interest.

## The
## exampleTENETStep2GetDifferentiallyMethylatedSitesPuritySummarizedExperiment
## object is a SummarizedExperiment with methylation values from adjacent
## normal, colorectal adenocarcinoma (COAD) TCGA samples, which represent data
## from potentially confounding cell types/tissues. This dataset is built for
## use in examples for the step2GetDifferentiallyMethylatedSites function. This
## object consists of three datasets with 10 samples each, with methylation
## values for each of the subsetted RE probes contained in the
## exampleTENETMultiAssayExperiment object.

## exampleTENETPeakRegions, exampleTENETTADRegions:

## These final two datasets are both GRanges objects generated from publicly-
## available .bed-like files, used to illustrate examples in downstream TENET
## step 7 functions.

## The exampleTENETPeakRegions dataset is composed of IDR thresholded peaks
## from the ENCODE consortium from FOXA1 ChIP-seq in MCF-7 breast cancer cells,
## annotated to the hg38 genome. (see
## https://www.encodeproject.org/files/ENCFF112JVK/)

## The exampleTENETTADRegions dataset contains regions within topologically
## associating domains (TADs) from the 3D Genome Browser website
## (http://3dgenome.fsm.northwestern.edu/publications.html)
## annotated to the hg38 genome. This dataset is composed only of TADs from the
## "T470" cells. Note: T470 is probably T47D, a breast cancer cell line, as
## T470 cells don't seem to exist.

### Code to prepare datasets

## First, we will need to create a "data" subdirectory if one doesn't already
## exist. This is because the AzureStor package functions, which will be used
## to upload these datasets to the Bioconductor Data Lake, look for the .Rda
## objects in the data subdirectory.
if (!dir.exists("data")) {
    dir.create("data")
}

## We will also create a data-raw directory if it does not already exist. It
## will be used to store the raw data downloaded during dataset preparation.
if (!dir.exists("data-raw")) {
    dir.create("data-raw")
}

## Code to prepare the `exampleTENETMultiAssayExperiment` dataset

## Requires TENET to be already installed, as the
## exampleTENETMultiAssayExperiment object contains data generated by the step
## 1-6 TENET functions on the expression/methylation data contained within the
## object

## Set a seed for reproducible random sampling
set.seed(2024)

## Specify some settings which will be used to access and process the
## TCGA data downloaded by the TCGAbiolinks package. More information about
## these settings can be found in the documentation for the TENET package's
## TCGADownloader() function.

## Specify the column of expression data we want
expressionColumn <- "fpkm_uq_unstrand"

## Set the TCGA dataset to be downloaded
TCGAStudyAbbreviation <- "BRCA"

## Set the directory used for downloads
rawDataDownloadDirectory <- "data-raw"

## Enable the option to remove the tumor samples that are duplicates from the
## same patient (leaving one per patient)
removeDupTumor <- TRUE

## Select tumor and normal samples with at least one methylation and expression
## sample annotated to their patient
matchingExpAndMetSamples <- TRUE

## Set the RNASeqWorkflow and enable the option to correct for FPKM UQ values
## similar to ones TCGA used to use prior to Data Release 37.0 - March 29,
## 2023
RNASeqWorkflow <- "STAR - FPKM-UQ - old formula"

## Enable log2 transformation of the expression values
RNASeqLog2Normalization <- TRUE

## Use clinical information from the 'patient' and 'follow_up' datasets in the
## BCR Biotab files, as well as data from the BCR XML files
clinicalSurvivalData <- "combined"

## --- Start of code modified from TENET's TCGADownloader function ---

## Internal functions used by TCGADownloader

## See https://docs.gdc.cancer.gov/Encyclopedia/pages/TCGA_Barcode/

## Internal function to extract the sample type from one or more TCGA sample IDs
.getSampleType <- function(sampleIDs) {
    return(as.numeric(substring(sampleIDs, 14, 15)))
}

## Internal function to get the TCGA sample IDs in a list that correspond to
## tumor samples
.getTumorSamples <- function(sampleIDs) {
    return(sampleIDs[.getSampleType(sampleIDs) < 10])
}

## Internal function to get the TCGA sample IDs in a list that correspond to
## normal or control samples
.getNormalAndControlSamples <- function(sampleIDs) {
    return(sampleIDs[.getSampleType(sampleIDs) >= 10])
}

## Internal function to extract the patient ID from one or more TCGA sample IDs
.getPatientIDs <- function(sampleIDs) {
    return(substring(sampleIDs, 1, 12))
}

## Internal function to strip the assay and center info from one or more TCGA
## sample IDs, to allow matching them between expression and methylation samples
.stripAssayAndCenterInfo <- function(sampleIDs) {
    return(substring(sampleIDs, 1, 19))
}

## By default, leave the expression values alone
expressionMultiplier <- 1
if (RNASeqWorkflow == "STAR - FPKM") {
    expressionColumn <- "fpkm_unstrand"
} else if (RNASeqWorkflow == "STAR - FPKM-UQ") {
    expressionColumn <- "fpkm_uq_unstrand"
} else if (RNASeqWorkflow == "STAR - FPKM-UQ - old formula") {
    expressionColumn <- "fpkm_uq_unstrand"
    ## Multiply the expressionData values by 19,029 to
    ## correct for FPKM UQ values similar to ones TCGA used to use
    ## prior to Data Release 37.0 - March 29, 2023
    ## See
    ## https://docs.gdc.cancer.gov/Data/Bioinformatics_Pipelines/Expression_mRNA_Pipeline/
    ## "Number of protein coding genes on autosomes: 19,029"
    expressionMultiplier <- 19029
} else if (RNASeqWorkflow == "STAR - TPM") {
    expressionColumn <- "tpm_unstrand"
} else {
    ## STAR - Counts
    expressionColumn <- "unstrand"
}

## Create the all-caps TCGA abbreviation used for downloads
TCGAStudyAbbreviationDownload <- paste0(
    "TCGA-", toupper(TCGAStudyAbbreviation)
)

## Set up the expression query
expressionQuery <- TCGAbiolinks::GDCquery(
    project = TCGAStudyAbbreviationDownload,
    data.category = "Transcriptome Profiling",
    data.type = "Gene Expression Quantification",
    experimental.strategy = "RNA-Seq",
    workflow.type = "STAR - Counts"
)

## Download the expression data
TCGAbiolinks::GDCdownload(
    expressionQuery,
    directory = rawDataDownloadDirectory
)

## Assemble the expression SummarizedExperiment object
expressionExperiment <- TCGAbiolinks::GDCprepare(
    expressionQuery,
    directory = rawDataDownloadDirectory
)

message("Expression SummarizedExperiment assembled.")

## Set up the methylation query
methylationQuery <- TCGAbiolinks::GDCquery(
    project = TCGAStudyAbbreviationDownload,
    data.category = "DNA Methylation",
    data.type = "Methylation Beta Value",
    platform = "Illumina Human Methylation 450"
)

## Download the methylation data
TCGAbiolinks::GDCdownload(
    methylationQuery,
    directory = rawDataDownloadDirectory
)

## Assemble the methylation SummarizedExperiment object
methylationExperiment <- TCGAbiolinks::GDCprepare(
    methylationQuery,
    directory = rawDataDownloadDirectory
)

message("Methylation SummarizedExperiment assembled.")

## Set up the clinical query for the BCR Biotab data
clinicalQueryBcrBiotab <- TCGAbiolinks::GDCquery(
    project = TCGAStudyAbbreviationDownload,
    data.category = "Clinical",
    data.type = "Clinical Supplement",
    data.format = "BCR Biotab"
)

## Download the BCR Biotab data
TCGAbiolinks::GDCdownload(
    clinicalQueryBcrBiotab,
    directory = rawDataDownloadDirectory
)

## Load the BCR Biotab clinical data into a data frame
clinicalDataBcrBiotab <- TCGAbiolinks::GDCprepare(
    clinicalQueryBcrBiotab,
    directory = rawDataDownloadDirectory
)

## The BCR Biotab data have a few different sub-datasets, so we will
## get only the patient datasets
clinicalDataBcrBiotabPatient <- clinicalDataBcrBiotab[[
    grep("patient", names(clinicalDataBcrBiotab))
]]

## Organize the datasets properly by extracting the true column
## names from the first row, then removing the first two rows of
## now irrelevant data
colnames(clinicalDataBcrBiotabPatient) <- unname(
    unlist(clinicalDataBcrBiotabPatient[1, ])
)

clinicalDataBcrBiotabPatient <- clinicalDataBcrBiotabPatient[
    seq(from = 3, to = nrow(clinicalDataBcrBiotabPatient), by = 1),
]

## Add a time variable
clinicalDataBcrBiotabPatient$time <- ifelse(
    clinicalDataBcrBiotabPatient$vital_status == "Alive",
    clinicalDataBcrBiotabPatient$days_to_last_followup,
    clinicalDataBcrBiotabPatient$days_to_death
)

## Remove the tribble class from the data frame
clinicalDataBcrBiotabPatient <- as.data.frame(clinicalDataBcrBiotabPatient)

## Add rownames to the dataset
rownames(clinicalDataBcrBiotabPatient) <- clinicalDataBcrBiotabPatient$
    bcr_patient_barcode

## Convert factors to characters
for (i in seq_len(ncol(clinicalDataBcrBiotabPatient))) {
    if (is.factor(clinicalDataBcrBiotabPatient[, i])) {
        clinicalDataBcrBiotabPatient[, i] <- as.character(
            clinicalDataBcrBiotabPatient[, i]
        )
    }
}

if (clinicalSurvivalData == "combined") {
    ## TCGAbiolinks downloads various types of clinical data for patients.
    ## Some of these datasets have more updated patient survival
    ## information, but don't contain data for all patients. Thus, the
    ## strategy here is to grab all the relevant datasets, then extract the
    ## most recent data for each patient where they are available.

    ## Get the BCR XML data, which are useful if the 'combined' survival
    ## option is selected
    clinicalQueryBcrXml <- TCGAbiolinks::GDCquery(
        project = TCGAStudyAbbreviationDownload,
        data.category = "Clinical",
        data.format = "bcr xml"
    )

    ## Download the BCR XML data
    TCGAbiolinks::GDCdownload(
        clinicalQueryBcrXml,
        directory = rawDataDownloadDirectory
    )

    ## Load the BCR XML data as a data frame
    clinicalDataBcrXml <- TCGAbiolinks::GDCprepare_clinic(
        clinicalQueryBcrXml,
        clinical.info = "patient",
        directory = rawDataDownloadDirectory
    )

    ## The BCR Biotab data have a few different sub-datasets, so we will
    ## get only the follow_up datasets
    clinicalDataFollowUpNames <- grep(
        "follow_up", names(clinicalDataBcrBiotab),
        value = TRUE
    )

    ## We don't want any _nte_ datasets, as those seem to lack clinical data
    ## in the follow_up datasets
    clinicalDataFollowUpNames <- grep(
        "_nte_", clinicalDataFollowUpNames,
        value = TRUE, invert = TRUE
    )

    ## Sort the names so the most recent of the non-nte datasets is last;
    ## it will be the BCR Biotab follow-up dataset
    clinicalDataFollowUpNames <- sort(clinicalDataFollowUpNames)

    clinicalDataBcrBiotabFollowUp <- clinicalDataBcrBiotab[[
        clinicalDataFollowUpNames[length(clinicalDataFollowUpNames)]
    ]]

    ## Organize the BCR Biotab follow-up data properly by extracting
    ## the true column names from the first row, then removing the first
    ## two rows of now irrelevant data
    colnames(clinicalDataBcrBiotabFollowUp) <- unname(
        unlist(clinicalDataBcrBiotabFollowUp[1, ])
    )

    clinicalDataBcrBiotabFollowUp <- clinicalDataBcrBiotabFollowUp[
        seq(from = 3, to = nrow(clinicalDataBcrBiotabFollowUp), by = 1),
    ]

    ## Add a time variable to the datasets
    clinicalDataBcrXml$time <- ifelse(
        clinicalDataBcrXml$vital_status == "Alive",
        clinicalDataBcrXml$days_to_last_followup,
        clinicalDataBcrXml$days_to_death
    )

    clinicalDataBcrBiotabFollowUp$time <- ifelse(
        clinicalDataBcrBiotabFollowUp$vital_status == "Alive",
        clinicalDataBcrBiotabFollowUp$days_to_last_followup,
        clinicalDataBcrBiotabFollowUp$days_to_death
    )

    ## Remove duplicates from the BCR Biotab follow-up data.
    ## suppressWarnings() is here due to use of as.numeric, which
    ## intentionally induces NAs to non-numeric values of the time
    ## variable.
    suppressWarnings(
        clinicalDataBcrBiotabFollowUp <- clinicalDataBcrBiotabFollowUp[
            order(
                as.numeric(clinicalDataBcrBiotabFollowUp$time),
                decreasing = TRUE
            ),
        ]
    )

    clinicalDataBcrBiotabFollowUpDedup <- clinicalDataBcrBiotabFollowUp[
        !duplicated(clinicalDataBcrBiotabFollowUp$bcr_patient_barcode),
    ]

    ## Remove the tribble class from the BiotabFollowUpDedup data frame (the
    ## BcrXml dataset is not a tribble)
    clinicalDataBcrBiotabFollowUpDedup <- as.data.frame(
        clinicalDataBcrBiotabFollowUpDedup
    )

    ## Add rownames to the datasets
    rownames(clinicalDataBcrXml) <- clinicalDataBcrXml$bcr_patient_barcode
    rownames(clinicalDataBcrBiotabFollowUpDedup) <-
        clinicalDataBcrBiotabFollowUpDedup$bcr_patient_barcode

    ## Convert factors to characters
    for (i in seq_len(ncol(clinicalDataBcrXml))) {
        if (is.factor(clinicalDataBcrXml[, i])) {
            clinicalDataBcrXml[, i] <- as.character(clinicalDataBcrXml[, i])
        }
    }

    for (i in seq_len(ncol(clinicalDataBcrBiotabFollowUpDedup))) {
        if (is.factor(clinicalDataBcrBiotabFollowUpDedup[, i])) {
            clinicalDataBcrBiotabFollowUpDedup[, i] <- as.character(
                clinicalDataBcrBiotabFollowUpDedup[, i]
            )
        }
    }

    ## Create a combined list of patient samples from all the relevant
    ## clinical datasets
    clinicalSamplesCombined <- unique(c(
        rownames(clinicalDataBcrBiotabPatient),
        rownames(clinicalDataBcrBiotabFollowUpDedup),
        rownames(clinicalDataBcrXml)
    ))

    ## For each clinical sample, go through the different
    ## clinical datasets and pull info in a prioritized manner
    ## i.e. the dataset which has the most recent (latest time)
    ## for that patient
    vitalStatusVector <- NULL
    timeVector <- NULL

    for (i in clinicalSamplesCombined) {
        ## Get the time and vital status from the BCR Biotab patient data
        if (i %in% rownames(clinicalDataBcrBiotabPatient)) {
            bcrBiotabPatientStatus <-
                clinicalDataBcrBiotabPatient[i, "vital_status"]
            bcrBiotabPatientTime <- clinicalDataBcrBiotabPatient[i, "time"]
        } else {
            bcrBiotabPatientStatus <- NA
            bcrBiotabPatientTime <- NA
        }

        ## Get the time and vital status from the BCR Biotab follow-up data
        if (i %in% rownames(clinicalDataBcrBiotabFollowUpDedup)) {
            bcrBiotabFollowUpStatus <-
                clinicalDataBcrBiotabFollowUpDedup[i, "vital_status"]
            bcrBiotabFollowUpTime <-
                clinicalDataBcrBiotabFollowUpDedup[i, "time"]
        } else {
            bcrBiotabFollowUpStatus <- NA
            bcrBiotabFollowUpTime <- NA
        }

        ## Get the time and vital status from the BCR XML data
        if (i %in% rownames(clinicalDataBcrXml)) {
            bcrXmlStatus <- clinicalDataBcrXml[i, "vital_status"]
            bcrXmlTime <- clinicalDataBcrXml[i, "time"]
        } else {
            bcrXmlStatus <- NA
            bcrXmlTime <- NA
        }

        ## Combine the values with names
        vitalStatusCombined <- c(
            bcrBiotabFollowUpStatus, bcrBiotabPatientStatus, bcrXmlStatus
        )

        ## Combine the time values. Again, suppressWarnings is here as we
        ## want to convert non-numeric values to NA.
        timeCombined <- suppressWarnings(
            as.numeric(
                c(bcrBiotabFollowUpTime, bcrBiotabPatientTime, bcrXmlTime)
            )
        )

        ## Get the data with the largest time value
        if (all(is.na(timeCombined))) {
            maxTime <- NA
            maxTimeStatus <- NA
        } else {
            maxTime <- max(timeCombined, na.rm = TRUE)
            maxTimeStatus <- vitalStatusCombined[
                which(timeCombined == max(timeCombined, na.rm = TRUE))
            ]
        }

        ## Reduce the max- vectors to a single entry
        ## unless there is conflict on whether the
        ## patient is alive or dead with the same time,
        ## in which case, return NA due to ambiguity
        if (length(maxTimeStatus) > 1) {
            if (length(unique(maxTimeStatus)) > 1) {
                maxTime <- NA
                maxTimeStatus <- NA
            } else {
                maxTimeStatus <- unique(maxTimeStatus)
            }
        }

        ## Add the resulting values to the vectors
        vitalStatusVector <- c(vitalStatusVector, maxTimeStatus)
        timeVector <- c(timeVector, maxTime)
    }

    ## Create a data frame of these new values.
    ## We will keep snake_case variable names here so they match with the
    ## variable names we would see directly out of TCGAbiolinks functions.
    survivalDF <- data.frame(
        "vital_status" = vitalStatusVector,
        "time" = timeVector,
        stringsAsFactors = FALSE
    )
    rownames(survivalDF) <- clinicalSamplesCombined

    ## Add the values to the clinicalDataBcrBiotabPatient DF
    clinicalDataBcrBiotabPatient$vital_status <- survivalDF[
        rownames(clinicalDataBcrBiotabPatient),
        "vital_status"
    ]

    clinicalDataBcrBiotabPatient$time <- survivalDF[
        rownames(clinicalDataBcrBiotabPatient),
        "time"
    ]
}

## Use the final clinicalDataBcrBiotabPatient dataset as the clinicalData
clinicalData <- clinicalDataBcrBiotabPatient

message("Clinical dataset assembled.")

## Multiply the expressionData values by the expressionMultiplier value
SummarizedExperiment::assays(
    expressionExperiment
)[[expressionColumn]] <- SummarizedExperiment::assays(
    expressionExperiment
)[[expressionColumn]] * expressionMultiplier

## Perform log2 normalization if selected
if (RNASeqLog2Normalization) {
    SummarizedExperiment::assays(expressionExperiment)[[
        expressionColumn
    ]] <- log2(
        SummarizedExperiment::assays(
            expressionExperiment
        )[[expressionColumn]] + 1 ## + 1 to avoid log2(0) which is -Inf
    )

    message("Expression dataset log2 transformed.")
}

## Strip the period and trailing number(s) annotation from the gene
## Ensembl IDs in the rowRanges
names(SummarizedExperiment::rowRanges(expressionExperiment)) <- sub(
    "_[0-9]+$", "", sub(
        "\\.[0-9]+", "",
        names(SummarizedExperiment::rowRanges(expressionExperiment))
    )
)

## Strip the period and trailing number(s) annotation from the gene
## Ensembl IDs in the main body of expression data
rownames(
    SummarizedExperiment::assays(expressionExperiment)[[expressionColumn]]
) <- sub("_[0-9]+$", "", sub(
    "\\.[0-9]+", "",
    rownames(
        SummarizedExperiment::assays(
            expressionExperiment
        )[[expressionColumn]]
    )
))

## To expedite later steps, isolate the expression and methylation sample
## names
expNames <- colnames(
    SummarizedExperiment::assays(expressionExperiment)[[expressionColumn]]
)

metNames <- colnames(
    SummarizedExperiment::assays(methylationExperiment)[[1]]
)

## If removeDupTumor is set to TRUE, remove the tumor samples that are
## duplicates from the same patient (leaving one per patient)
if (removeDupTumor) {
    ## Identify the matched expression samples which are from tumor and
    ## normal samples
    expNamesTumor <- .getTumorSamples(expNames)
    expNamesNormal <- .getNormalAndControlSamples(expNames)

    ## Do the same for the matched methylation samples which are from tumor
    ## and normal samples
    metNamesTumor <- .getTumorSamples(metNames)
    metNamesNormal <- .getNormalAndControlSamples(metNames)

    ## Create data frames from the tumor IDs to help in identifying the
    ## tumor samples that come from duplicate patients
    dupTumorExpressionDF <- data.frame(
        "fullID" = expNamesTumor,
        stringsAsFactors = FALSE
    )

    rownames(dupTumorExpressionDF) <- expNamesTumor

    dupTumorMethylationDF <- data.frame(
        "fullID" = metNamesTumor,
        stringsAsFactors = FALSE
    )

    rownames(dupTumorMethylationDF) <- metNamesTumor

    ## Extract the patient IDs from the sample IDs
    dupTumorExpressionDF$patientID <- .getPatientIDs(
        dupTumorExpressionDF$fullID
    )

    dupTumorMethylationDF$patientID <- .getPatientIDs(
        dupTumorMethylationDF$fullID
    )

    ## Sort the data frames alphanumerically to facilitate in keeping the
    ## first sample from each patient based on its alphanumeric ID
    dupTumorExpressionDF <- dupTumorExpressionDF[sort(expNamesTumor), ]
    dupTumorMethylationDF <- dupTumorMethylationDF[sort(metNamesTumor), ]

    ## Identify which of the patient samples are duplicates
    dupTumorExpressionDF$duplicatedPatientID <- duplicated(
        dupTumorExpressionDF$patientID
    )

    dupTumorMethylationDF$duplicatedPatientID <- duplicated(
        dupTumorMethylationDF$patientID
    )

    ## Remove all the duplicated tumor samples, isolate the IDs of the
    ## remaining tumor samples, then add the normal sample names back to
    ## those as ones to keep
    expNamesTumor <- rownames(
        dupTumorExpressionDF[
            dupTumorExpressionDF$duplicatedPatientID == FALSE,
        ]
    )

    metNamesTumor <- rownames(
        dupTumorMethylationDF[
            dupTumorMethylationDF$duplicatedPatientID == FALSE,
        ]
    )
}

## If matchingExpAndMetSamples is set to TRUE, find both
## tumor and normal samples with just matched methylation and expression
## data

## Also, for the purposes of this dataset, subset to 200 tumor samples, and half
## (42) of the normal samples
if (matchingExpAndMetSamples) {
    ## Find the sample names that are present in both datasets
    matchedExpMetNamesSubTumor <- intersect(
        .stripAssayAndCenterInfo(expNamesTumor),
        .stripAssayAndCenterInfo(metNamesTumor)
    )

    matchedExpMetNamesSubNormal <- intersect(
        .stripAssayAndCenterInfo(expNamesNormal),
        .stripAssayAndCenterInfo(metNamesNormal)
    )

    ## Sort the names and match them
    matchedExpNamesTumor <- sort(expNamesTumor[
        .stripAssayAndCenterInfo(expNamesTumor) %in% matchedExpMetNamesSubTumor
    ])

    matchedMetNamesTumor <- sort(metNamesTumor[
        .stripAssayAndCenterInfo(metNamesTumor) %in% matchedExpMetNamesSubTumor
    ])

    matchedExpNamesNormal <- sort(expNamesNormal[
        .stripAssayAndCenterInfo(expNamesNormal) %in%
            matchedExpMetNamesSubNormal
    ])

    matchedMetNamesNormal <- sort(metNamesNormal[
        .stripAssayAndCenterInfo(metNamesNormal) %in%
            matchedExpMetNamesSubNormal
    ])

    ## For the purposes of this dataset, subset to 200 tumor samples, and half
    ## (42) of the normal samples
    normalSampleNumbers <- sample.int(
        length(matchedExpNamesNormal),
        round(length(matchedExpNamesNormal) / 2)
    )
    tumorSampleNumbers <- sample.int(length(matchedExpNamesTumor), 200)

    matchedExpNamesNormalSubset <- matchedExpNamesNormal[normalSampleNumbers]
    matchedMetNamesNormalSubset <- matchedMetNamesNormal[normalSampleNumbers]
    matchedExpNamesTumorSubset <- matchedExpNamesTumor[tumorSampleNumbers]
    matchedMetNamesTumorSubset <- matchedMetNamesTumor[tumorSampleNumbers]

    ## Combine the matched tumor and normal names
    matchedExpNames <- c(
        matchedExpNamesNormalSubset,
        matchedExpNamesTumorSubset
    )

    matchedMetNames <- c(
        matchedMetNamesNormalSubset,
        matchedMetNamesTumorSubset
    )
} else {
    ## Find the names of all the samples with either expression or
    ## methylation data
    matchedExpNames <- expNames
    matchedMetNames <- metNames
}

## Sort the expression and methylation names alphanumerically (for
## later use)
matchedExpNames <- sort(matchedExpNames)
matchedMetNames <- sort(matchedMetNames)

## Process the clinical data so it can be added as the colData of the
## MultiAssayExperiment object

## Combine the exp and met names and sort those as well
matchedExpMetNames <- sort(c(matchedExpNames, matchedMetNames))

## Get the unique samples then add in the patient IDs as the row names
clinical <- unique(clinicalData)
rownames(clinical) <- clinical$bcr_patient_barcode

## Get the patient IDs from the exp and met sample names, which will
## match the patient barcode in the clinical data
expMetClinicalBarcodeMatch <- unique(.getPatientIDs(matchedExpMetNames))

## Get a data frame of the clinical data for the patients in the dataset.
## Rownames are reset so missing expMetClinicalBarcodeMatch values are
## still reflected in the rownames of the multiAssayClinical object with NA
## values, instead of the missing values also having NA rownames.
multiAssayClinical <- clinical[expMetClinicalBarcodeMatch, ]
rownames(multiAssayClinical) <- expMetClinicalBarcodeMatch

## Change the time variable back to numeric in the clinical data
multiAssayClinical$time <- as.numeric(multiAssayClinical$time)

## Add some simulated purity, gene copy number variation (CNV), and somatic
## mutation (SM) status data for use as examples for TENET functions,
## in particular the step7ExpressionVsDNAMethylationScatterplots function

## This is a bit backwards, but we will get the gene IDs of the top 10
## genes by number of linked hypermethylated and hypomethylated probes
## that will come from analyses using this dataset
topHypermethylatedGenes <- c(
    "ENSG00000165821", "ENSG00000169989", "ENSG00000197343", "ENSG00000169083",
    "ENSG00000177842", "ENSG00000234284", "ENSG00000177853", "ENSG00000196345",
    "ENSG00000196653", "ENSG00000162599"
)

topHypomethylatedGenes <- c(
    "ENSG00000129514", "ENSG00000124664", "ENSG00000107485", "ENSG00000091831",
    "ENSG00000118513", "ENSG00000100219", "ENSG00000152192", "ENSG00000105261",
    "ENSG00000178935", "ENSG00000115163"
)

## Simulate purity values for each of the samples. Purity should be
## a number from 0 to 1 to be properly plotted
multiAssayClinical$purity <- runif(nrow(multiAssayClinical))

## For each of the top hypermethylated and hypomethylated genes,
## to simulate CNV and SM data for each gene and add them to the clinical data
for (i in unlist(c(topHypermethylatedGenes, topHypomethylatedGenes))) {
    cnvReturn <- paste0(i, "_CNV")
    smReturn <- paste0(i, "_SM")

    multiAssayClinical[, cnvReturn] <- as.integer(
        sample(c(-2, -1, 0, 1, 2), nrow(multiAssayClinical), replace = TRUE)
    )

    multiAssayClinical[, smReturn] <- as.integer(
        sample(c(0, 1), nrow(multiAssayClinical), replace = TRUE)
    )
}

## Use the TENET step 1 function to create a relevant GRanges object for our
## test dataset
TENETGRNDRHMIntersect <- TENET::step1MakeExternalDatasets(
    extHM = NA,
    extNDR = NA,
    consensusEnhancer = TRUE,
    consensusPromoter = FALSE,
    consensusNDR = TRUE,
    publicEnhancer = TRUE,
    publicPromoter = FALSE,
    publicNDR = TRUE,
    cancerType = "BRCA",
    ENCODEPLS = FALSE,
    ENCODEpELS = FALSE,
    ENCODEdELS = TRUE
)

## Subset the methylation probes, keeping 10,000 each of both the RE and non-RE
## probes to confirm overlapping is done later in examples

## Get the GRanges of the probes of interest from the TCGA data we assembled
hg38Manifest <- SummarizedExperiment::rowRanges(methylationExperiment)

## Create a modified data frame of the hg38 DNA methylation probe annotations
## to later convert to GRanges
hg38ManifestGRangesDF <- data.frame(
    "chr" = as.character(GenomicRanges::seqnames(hg38Manifest)),
    "start" = GenomicRanges::start(hg38Manifest),
    "end" = GenomicRanges::end(hg38Manifest),
    "names" = names(hg38Manifest),
    stringsAsFactors = FALSE
)

## Set the rownames of the hg38ManifestGRangesDF
rownames(hg38ManifestGRangesDF) <- hg38ManifestGRangesDF$names

## Remove the big manifest data frame
rm(hg38Manifest)

## Remove the probes that have NA values
hg38ManifestGRangesDF <- hg38ManifestGRangesDF[
    !is.na(hg38ManifestGRangesDF$chr),
]

## Create a GRanges object from the hg38 annotations data frame
hg38ManifestAnnotationsGRanges <- GenomicRanges::makeGRangesFromDataFrame(
    df = hg38ManifestGRangesDF,
    keep.extra.columns = FALSE,
    starts.in.df.are.0based = FALSE
)
names(hg38ManifestAnnotationsGRanges) <- hg38ManifestGRangesDF$names

## Overlap the probes with the RE genomic ranges object to get the
## names of the probes in RE elements
REProbes <- suppressWarnings(
    names(
        hg38ManifestAnnotationsGRanges[
            unique(
                S4Vectors::queryHits(
                    GenomicRanges::findOverlaps(
                        hg38ManifestAnnotationsGRanges,
                        TENETGRNDRHMIntersect
                    )
                )
            ),
        ]
    )
)

## Get the names of the probes which aren't in regulatory elements
nonREProbes <- setdiff(rownames(hg38ManifestGRangesDF), REProbes)

## Sort the sample names which are present in the
## matchedExpMetNames for the expression and methylation data. This is
## done this way as the matchedExpMetNames samples might be larger than
## the number of samples in the expression and methylation datasets.
expressionSamples <- sort(
    colnames(
        SummarizedExperiment::assays(
            expressionExperiment
        )[[expressionColumn]]
    )[
        colnames(
            SummarizedExperiment::assays(
                expressionExperiment
            )[[expressionColumn]]
        ) %in% matchedExpMetNames
    ]
)

methylationSamples <- sort(
    colnames(
        SummarizedExperiment::assays(
            methylationExperiment
        )[[1]]
    )[
        colnames(
            SummarizedExperiment::assays(
                methylationExperiment
            )[[1]]
        ) %in% matchedExpMetNames
    ]
)

## Get the probes that are present in the methylation object
REProbesPresent <- REProbes[REProbes %in% rownames(
    SummarizedExperiment::assays(methylationExperiment)[[1]]
)]

nonREProbesPresent <- nonREProbes[nonREProbes %in% rownames(
    SummarizedExperiment::assays(methylationExperiment)[[1]]
)]

## Sample 10,000 of the RE and non-RE probes
REProbeSamples <- sample.int(length(REProbesPresent), 10000)
nonREProbeSamples <- sample.int(length(nonREProbesPresent), 10000)
probesToSample <- sort(
    c(REProbesPresent[REProbeSamples], nonREProbesPresent[nonREProbeSamples])
)

## Set up a conversion vector to make sure we can subset the methylation
## SummarizedExperiment properly
methylationConversionVector <- c(
    seq_along(SummarizedExperiment::assays(methylationExperiment)[[1]])
)
names(methylationConversionVector) <- rownames(
    SummarizedExperiment::assays(methylationExperiment)[[1]]
)

## Subset the gene names. We will include all TF genes, plus an additional
## 10,000 genes.

## Get the ENSG_IDs of the TF genes from the TENET package
dataEnv <- new.env(parent = emptyenv())

utils::data(
    "humanTranscriptionFactorsList",
    package = "TENET",
    envir = dataEnv
)

TFIDs <- dataEnv$humanTranscriptionFactorsList

## Remove the non ENSG TFs
TFIDs <- TFIDs[startsWith(TFIDs, "ENSG")]

## Get the TF and non-TF IDs that are present in the MultiAssayExperiment
TFIDsPresent <- TFIDs[
    TFIDs %in% rownames(
        SummarizedExperiment::assays(
            expressionExperiment
        )[[expressionColumn]]
    )
]

nonTFIDsPresent <- setdiff(
    rownames(
        SummarizedExperiment::assays(
            expressionExperiment
        )[[expressionColumn]]
    ),
    TFIDsPresent
)

## Sample 10,000 of the non-TF genes and combine them with the TF genes
nonTFIDsSample <- sample(
    seq_along(nonTFIDsPresent), 10000,
    replace = FALSE
)

genesToSample <- sort(c(TFIDsPresent, nonTFIDsPresent[nonTFIDsSample]))

## Set up a conversion vector to make sure we can subset the
## expression SummarizedExperiment properly
expressionConversionVector <- c(
    seq_along(
        SummarizedExperiment::assays(
            expressionExperiment
        )[[expressionColumn]]
    )
)
names(expressionConversionVector) <- rownames(
    SummarizedExperiment::assays(
        expressionExperiment
    )[[expressionColumn]]
)

## Set up the mapping list we will need to create the
## MultiAssayExperiment object and link expression/methylation samples
## to the clinical colData, along with the sampleType information

## Create the data frames for the expression/methylation maps
expressionMap <- data.frame(
    "primary" = .getPatientIDs(expressionSamples),
    "colname" = expressionSamples,
    "sampleType" = ifelse(
        .getSampleType(expressionSamples) < 10, "Case", "Control"
    ),
    stringsAsFactors = FALSE
)

methylationMap <- data.frame(
    "primary" = .getPatientIDs(methylationSamples),
    "colname" = methylationSamples,
    "sampleType" = ifelse(
        .getSampleType(methylationSamples) < 10, "Case", "Control"
    ),
    stringsAsFactors = FALSE
)

## Create a list of those data frames with the name of the eventual
## components of the MultiAssayExperiment object
mappingList <- list(expressionMap, methylationMap)
names(mappingList) <- c("expression", "methylation")

## Create the MultiAssayExperiment object
TENETMultiAssayExperiment <- MultiAssayExperiment::MultiAssayExperiment(
    experiments = list(
        "expression" = SummarizedExperiment::SummarizedExperiment(
            assays = list(
                "expression" = SummarizedExperiment::assays(
                    expressionExperiment
                )[[expressionColumn]][
                    expressionConversionVector[genesToSample],
                    expressionSamples
                ]
            ),
            rowRanges = SummarizedExperiment::rowRanges(
                expressionExperiment
            )[
                expressionConversionVector[genesToSample],
            ]
        ),
        "methylation" = SummarizedExperiment::SummarizedExperiment(
            assays = list(
                "methylation" = SummarizedExperiment::assays(
                    methylationExperiment
                )[[1]][
                    methylationConversionVector[probesToSample],
                    methylationSamples
                ]
            ),
            rowRanges = SummarizedExperiment::rowRanges(
                methylationExperiment
            )[
                methylationConversionVector[probesToSample],
            ]
        )
    ),
    colData = multiAssayClinical,
    sampleMap = MultiAssayExperiment::listToMap(mappingList)
)

## For whatever reason, when setting the sampleMap of the
## TENETMultiAssayExperiment above, it has lost the "sampleType"
## column that was added, so we manually replace the sampleMap in the object
TENETMultiAssayExperiment@sampleMap <-
    MultiAssayExperiment::listToMap(mappingList)

## Create a metadata data frame with info about how the samples were
## processed
metadataDF <- data.frame(
    "dataset" = TCGAStudyAbbreviationDownload,
    "expressionDataRelease" = unname(
        unlist(expressionExperiment@metadata)
    ),
    "methylationDataRelease" = unname(
        unlist(methylationExperiment@metadata)
    ),
    "RNASeqWorkflow" = RNASeqWorkflow,
    "log2ExpressionNormalization" = RNASeqLog2Normalization,
    "duplicateTumorSamplesFromSamePatientRemoved" = removeDupTumor,
    "expressionAndMethylationSampleMatching" = matchingExpAndMetSamples,
    "clinicalSurvivalData" = clinicalSurvivalData,
    "DNAMethylationDataType" = "DNAMethylationArray",
    stringsAsFactors = FALSE
)

## Add that metadata data frame to the MultiAssayExperiment as a list so
## more data can be added in later TENET steps
TENETMultiAssayExperiment@metadata <- list(
    "TCGADownloaderFunction" = metadataDF
)

## --- End of code modified from TENET's TCGADownloader function ---

## Rename the generated MultiAssayExperiment variable so it can be saved under
## a different name
exampleTENETMultiAssayExperiment <- TENETMultiAssayExperiment
rm(TENETMultiAssayExperiment)

## Note: We will not save the exampleTENETMultiAssayExperiment object now.
## Instead we will wait until the
## exampleTENETStep1MakeExternalDatasetsGRanges object is created.

## Code to prepare the `exampleTENETClinicalDataFrame` dataset

## The exampleTENETClinicalDataFrame is a subsetted copy of the previously
## created multiAssayClinical object, with patient vital status and survival
## time, and the simulated purity values, copy number variation (CNV), and
## somatic mutation (SM) data for the 10 TFs with the most linked
## hypermethylated and hypomethylated probes. This dataset is saved as a data
## frame instead of being included in the exampleTENETMultiAssayExperiment
## object.

## Create the exampleTENETClinicalDataFrame from multiAssayClinical, grabbing
## just the "vital_status" and "time" variables for the moment
exampleTENETClinicalDataFrame <- multiAssayClinical[, c("vital_status", "time")]

## Add the simulated purity, CNV, and SM columns to the
## exampleTENETClinicalDataFrame
exampleTENETClinicalDataFrame <- cbind(
    exampleTENETClinicalDataFrame,
    multiAssayClinical[
        , grepl("(_(CNV|SM)$|^purity$)", colnames(multiAssayClinical))
    ]
)

## Save the exampleTENETClinicalDataFrame
save(
    exampleTENETClinicalDataFrame,
    file = "data/exampleTENETClinicalDataFrame.Rda",
    compress = "xz",
    compression_level = -9 ## Level -n = level n but with xz -e
)

## Code to prepare the `exampleTENETStep1MakeExternalDatasetsGRanges` dataset

## The exampleTENETStep1MakeExternalDatasetsGRanges dataset is a copy of the
## TENETGRNDRHMIntersect GRanges object which was used previously to
## identify RE probes to be included in the exampleTENETMultiAssayExperiment
## object.

## Rename then save the TENETGRNDRHMIntersect dataset
exampleTENETStep1MakeExternalDatasetsGRanges <- TENETGRNDRHMIntersect
rm(TENETGRNDRHMIntersect)

save(
    exampleTENETStep1MakeExternalDatasetsGRanges,
    file = "data/exampleTENETStep1MakeExternalDatasetsGRanges.Rda",
    compress = "xz",
    compression_level = -9 ## Level -n = level n but with xz -e
)

## Finish creating and save the exampleTENETMultiAssayExperiment

## Run the TENET step 2-6 functions on the example TENET MultiAssayExperiment

## Run step 2 (with the exampleTENETStep1MakeExternalDatasetsGRanges object)
exampleTENETMultiAssayExperiment <-
    TENET::step2GetDifferentiallyMethylatedSites(
        TENETMultiAssayExperiment = exampleTENETMultiAssayExperiment,
        regulatoryElementGRanges = exampleTENETStep1MakeExternalDatasetsGRanges,
        geneAnnotationDataset = NA,
        DNAMethylationArray = NA,
        assessPromoter = FALSE,
        TSSDist = 1500,
        purityData = NA,
        methCutoff = NA,
        hypomethCutoff = NA,
        hypermethCutoff = NA,
        unmethCutoff = NA,
        methUnmethProportionOffset = 0.2,
        hypomethHypermethProportionOffset = 0.1,
        minCaseCount = 5,
        cgDNAMethylationSitesOnly = TRUE
    )

## Run step 3
exampleTENETMultiAssayExperiment <- TENET::step3GetAnalysisZScores(
    TENETMultiAssayExperiment = exampleTENETMultiAssayExperiment,
    hypermethAnalysis = TRUE,
    hypomethAnalysis = TRUE,
    includeControl = FALSE,
    TFOnly = TRUE,
    zScoreCalculation = "oneSample",
    sparseResults = TRUE,
    pValue = 0.05,
    coreCount = 1
)

## Run step 4
exampleTENETMultiAssayExperiment <-
    TENET::step4SelectMostSignificantLinksPerDNAMethylationSite(
        TENETMultiAssayExperiment = exampleTENETMultiAssayExperiment,
        hypermethGplusAnalysis = TRUE,
        hypomethGplusAnalysis = TRUE,
        linksPerREDNAMethylationSiteMaximum = 25,
        multipleTestingPValue = 0.05,
        coreCount = 1
    )

## Run step 5
exampleTENETMultiAssayExperiment <- TENET::step5OptimizeLinks(
    TENETMultiAssayExperiment = exampleTENETMultiAssayExperiment,
    hypermethGplusAnalysis = TRUE,
    hypomethGplusAnalysis = TRUE,
    expressionPvalCutoff = 0.05,
    hyperStringency = NA,
    hypoStringency = NA,
    coreCount = 1
)

## Run step 6
exampleTENETMultiAssayExperiment <-
    TENET::step6DNAMethylationSitesPerGeneTabulation(
        TENETMultiAssayExperiment = exampleTENETMultiAssayExperiment,
        geneAnnotationDataset = NA,
        hypermethGplusAnalysis = TRUE,
        hypomethGplusAnalysis = TRUE
    )

## Save the final exampleTENETMultiAssayExperiment object to the data directory
save(
    exampleTENETMultiAssayExperiment,
    file = "data/exampleTENETMultiAssayExperiment.Rda",
    compress = "xz",
    compression_level = -9 ## Level -n = level n but with xz -e
)

## Code to prepare the
## `exampleTENETStep2GetDifferentiallyMethylatedSitesPuritySummarizedExperiment`
## dataset

## This is a SummarizedExperiment object with two methylation
## datasets with 10 adjacent normal COAD TCGA samples each, with data for the
## probes included in the exampleTENETMultiAssayExperiment object.
## This dataset is intended to be used to illustrate the use of the `purity`
## argument in the step2GetDifferentiallyMethylatedSites function of the TENET
## package.

## Set up the purity methylation query
purityMethylationQuery <- TCGAbiolinks::GDCquery(
    project = "TCGA-COAD",
    data.category = "DNA Methylation",
    data.type = "Methylation Beta Value",
    platform = "Illumina Human Methylation 450"
)

## Download the purity methylation data
TCGAbiolinks::GDCdownload(
    purityMethylationQuery,
    directory = rawDataDownloadDirectory
)

## Load the purity methylation data as a SummarizedExperiment object
purityMethylationExperiment <- TCGAbiolinks::GDCprepare(
    purityMethylationQuery,
    directory = rawDataDownloadDirectory
)

## Subset the methylation dataset to just the probes from the BRCA dataset
purityMethylationData <- as.data.frame(
    purityMethylationExperiment@assays@data@listData
)
purityMethylationData <- purityMethylationData[probesToSample, ]

## Sample 2 sets of 10 adjacent normal patients each from this
## COAD dataset to represent an example purity dataset

## Get the normal sample names
purityMetNamesNormal <- .getNormalAndControlSamples(
    colnames(purityMethylationData)
)

## Get 2 sets of 10 samples each. We do this by randomly assigning a sample
## number to all the samples in the dataset, then grabbing the first 20 in two
## parts.
purityMetNamesNormalSample <- sample.int(length(purityMetNamesNormal))
puritySampleA <- purityMetNamesNormal[purityMetNamesNormalSample[seq_len(10)]]
puritySampleB <- purityMetNamesNormal[purityMetNamesNormalSample[c(11:20)]]

## Create data frames with the row names being the methylation probe IDs
## and the column names being NULL
purityMethylationExampleA <- purityMethylationData[, puritySampleA]
rownames(purityMethylationExampleA) <- probesToSample
colnames(purityMethylationExampleA) <- NULL

purityMethylationExampleB <- purityMethylationData[, puritySampleB]
rownames(purityMethylationExampleB) <- probesToSample
colnames(purityMethylationExampleB) <- NULL

## Create the SummarizedExperiment object from the component matrices
exampleTENETStep2GetDifferentiallyMethylatedSitesPuritySummarizedExperiment <-
    SummarizedExperiment::SummarizedExperiment(
        assays = list(
            "purityMethylationExampleA" = purityMethylationExampleA,
            "purityMethylationExampleB" = purityMethylationExampleB
        ),
        rowRanges = SummarizedExperiment::rowRanges(
            methylationExperiment
        )[
            methylationConversionVector[probesToSample],
        ]
    )

## Save the final
## exampleTENETStep2GetDifferentiallyMethylatedSitesPuritySummarizedExperiment
## object
save(
    exampleTENETStep2GetDifferentiallyMethylatedSitesPuritySummarizedExperiment,
    file = paste0(
        "data/exampleTENETStep2GetDifferentiallyMethylatedSites",
        "PuritySummarizedExperiment.Rda"
    ),
    compress = "xz",
    compression_level = -9 ## Level -n = level n but with xz -e
)

## Code to prepare the `exampleTENETPeakRegions` dataset

## This is a GRanges object with example information of genomic
## regions (peaks), in this case, IDR thresholded peaks from the ENCODE
## consortium from FOXA1 ChIP-seq in MCF-7 breast cancer cells, annotated
## to the hg38 genome; see https://www.encodeproject.org/files/ENCFF112JVK/

## Define the URL to the .bed file containing peaks
exampleTENETPeakRegionsURL <- paste0(
    "https://www.encodeproject.org/files/ENCFF112JVK/@@download/",
    "ENCFF112JVK.bed.gz"
)

## Load the .bed file from the URL
exampleTENETPeakRegions <- utils::read.delim(
    gzcon(url(exampleTENETPeakRegionsURL), text = TRUE),
    header = FALSE,
    stringsAsFactors = FALSE
)

## The .bed file contains several columns of data. However, only the first
## three with chromosome, start, and end locations are really needed, so
## those are isolated. Note: Other columns are OK and won't affect analyses,
## they just won't be used.
exampleTENETPeakRegions <- exampleTENETPeakRegions[, seq_len(3)]

## Change the column names so they can be recognized by GenomicRanges
colnames(exampleTENETPeakRegions) <- c("chr", "start", "end")

## Add a dummy strand column
exampleTENETPeakRegions$strand <- "*"

## Convert the data frame into a GRanges object and make sure the values get
## 1-indexed
exampleTENETPeakRegions <- GenomicRanges::makeGRangesFromDataFrame(
    exampleTENETPeakRegions,
    starts.in.df.are.0based = TRUE
)

## Save the final exampleTENETPeakRegions object
save(
    exampleTENETPeakRegions,
    file = "data/exampleTENETPeakRegions.Rda",
    compress = "xz",
    compression_level = -9 ## Level -n = level n but with xz -e
)

## Code to prepare the `exampleTENETTADRegions` dataset

## This is a GRanges object with information for topologically
## associating domains (TAD) from the 3D Genome Browser website
## (http://3dgenome.fsm.northwestern.edu/publications.html)
## annotated to the hg38 genome. We only use the TADs from the "T470" cells.
## Note: T470 is probably T47D, a breast cancer cell line, as T470 cells
## don't seem to exist.

## Define the URL to the .zip file containing hg38 TADs
TADFileURL <- "http://3dgenome.fsm.northwestern.edu/downloads/hg38.TADs.zip"

## Download the .zip file
download.file(TADFileURL, "data-raw/hg38.TADs.zip")

## Unzip the file
unzip("data-raw/hg38.TADs.zip", exdir = "data-raw")

## Load the data for the "T470" cells, adding column names that GenomicRanges
## can recognize
exampleTENETTADRegions <- utils::read.delim(
    "data-raw/hg38/T470_raw-merged_TADs.txt",
    header = FALSE,
    stringsAsFactors = FALSE,
    col.names = c("chr", "start", "end")
)

## Delete the downloaded files
file.remove("data-raw/hg38.TADs.zip")
unlink("data-raw/hg38", recursive = TRUE)

## Add a dummy strand column
exampleTENETTADRegions$strand <- "*"

## One row seems to be improperly formatted, so remove it
exampleTENETTADRegions <- exampleTENETTADRegions[
    ((exampleTENETTADRegions$end - exampleTENETTADRegions$start) > 0),
]

## Convert the data frame into a GRanges object and make sure the values get
## 1-indexed
exampleTENETTADRegions <- GenomicRanges::makeGRangesFromDataFrame(
    exampleTENETTADRegions,
    starts.in.df.are.0based = TRUE
)

## Save the final exampleTENETTADRegions object
save(
    exampleTENETTADRegions,
    file = "data/exampleTENETTADRegions.Rda",
    compress = "xz",
    compression_level = -9 ## Level -n = level n but with xz -e
)
