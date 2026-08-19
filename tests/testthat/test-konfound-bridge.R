test_that("continuous IT analysis runs through the installed package", {
  skip_if_not_installed("konfound")
  spec <- list(
    outcome_type = "continuous", source_type = "linear", analysis = "IT",
    estimate = 0.214, standard_error = 0.071, n_observations = 1842L,
    n_covariates = 5L, n_treat = NULL, a = NULL, b = NULL, c = NULL, d = NULL,
    alpha = 0.05, tails = 2L, standard_error_type = "ols"
  )
  result <- suppressWarnings(suppressMessages(run_konfound_analysis(spec)))
  expect_equal(result$raw$itcvGz, 0.0256239, tolerance = 1e-6)
  expect_match(result$summary$headline, "Impact Threshold")
})

test_that("2 x 2 RIR analysis runs without regression inputs", {
  skip_if_not_installed("konfound")
  spec <- list(
    outcome_type = "dichotomous", source_type = "two_by_two", analysis = "RIR",
    estimate = NULL, standard_error = NULL, n_observations = NULL,
    n_covariates = NULL, n_treat = NULL, a = 30L, b = 20L, c = 10L, d = 40L,
    alpha = 0.05, tails = 2L, standard_error_type = "unknown"
  )
  result <- suppressWarnings(suppressMessages(run_konfound_analysis(spec)))
  expect_equal(result$raw$RIR_primary, 17)
  expect_equal(result$raw$RIR_perc, 42.5)
  expect_length(result$warnings, 0L)
})
