## This is based on code generated by HubPub::create_pkg()

context("metadata validity")

test_that("metadata is valid", {
    if (!requireNamespace("ExperimentHubData", quietly = TRUE)) {
        BiocManager::install("ExperimentHubData")
    }

    path <- find.package("TENET.ExperimentHub")
    metadata <- system.file(
        "extdata", "metadata.csv",
        package = "TENET.ExperimentHub"
    )
    expect_true(ExperimentHubData::makeExperimentHubMetadata(path, metadata))
})
