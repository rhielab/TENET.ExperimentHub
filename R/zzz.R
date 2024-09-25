## Based on https://github.com/Bioconductor/ExperimentHub/blob/aed0138b7c83e3c86a153e4e1ba380f80353f6f0/R/utilities.R
## Artistic License 2.0, which allows relicensing under GPLv2 via section
## 4(c)(ii) - see https://github.com/Bioconductor/ExperimentHub/blob/aed0138b7c83e3c86a153e4e1ba380f80353f6f0/DESCRIPTION

## These functions are used by data.R

.ExperimentHubEnv <- new.env(parent = emptyenv())

.getExperimentHubVariable <- function() get("eh", envir = .ExperimentHubEnv)

.setExperimentHubVariable <- function(value) {
    assign("eh", value, envir = .ExperimentHubEnv)
}

.getExperimentHub <- function() {
    eh <- try(.getExperimentHubVariable(), silent = TRUE)
    if (inherits(eh, "try-error")) {
        eh <- ExperimentHub::ExperimentHub()
        .setExperimentHubVariable(eh)
    }
    eh
}

.getExperimentHubDataset <- function(title, metadata = FALSE) {
    ehub <- .getExperimentHub()
    pkgname <- methods::getPackageName()
    eh1 <- ehub[ExperimentHub::package(ehub) == pkgname & ehub$title == title]
    if (length(eh1) == 0L) {
        stop("\"", title, "\" not found in ExperimentHub")
    }
    if (length(eh1) != 1L) {
        stop("\"", title, "\" matches more than 1 ExperimentHub resource")
    }
    if (metadata) {
        eh1
    } else {
        eh1[[1L]]
    }
}
