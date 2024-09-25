## The code placed here by HubPub::create_pkg() resulted in tests being unable
## to find extdata. This code, which works, is based on
## https://stackoverflow.com/questions/8898469/is-it-possible-to-use-r-package-data-in-testthat-tests-or-run-examples

library(testthat)
test_package("TENET.ExperimentHub")
