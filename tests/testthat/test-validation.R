test_that("demo extraction normalizes to analysis-ready values", {
  result <- demo_extraction()
  expect_identical(result$outcome_type, "continuous")
  expect_identical(result$model_type, "linear")
  expect_equal(result$estimate, 0.214)
  expect_equal(result$n_covariates, 5L)
  expect_length(result$evidence, 3L)
})

test_that("continuous specification requires core values", {
  spec <- list(
    outcome_type = "continuous", source_type = "linear", analysis = "IT",
    estimate = NULL, standard_error = NULL, n_observations = NULL,
    n_covariates = NULL, n_treat = NULL, a = NULL, b = NULL, c = NULL, d = NULL,
    alpha = 0.05, tails = 2L, standard_error_type = "ols"
  )
  result <- validate_specification(spec)
  expect_false(result$valid)
  expect_true(length(result$errors) >= 4L)
})

test_that("valid demo specification passes", {
  spec <- list(
    outcome_type = "continuous", source_type = "linear", analysis = "IT",
    estimate = 0.214, standard_error = 0.071, n_observations = 1842L,
    n_covariates = 5L, n_treat = NULL, a = NULL, b = NULL, c = NULL, d = NULL,
    alpha = 0.05, tails = 2L, standard_error_type = "ols"
  )
  expect_true(validate_specification(spec)$valid)
})

test_that("generated code includes confirmed inputs", {
  spec <- list(
    outcome_type = "continuous", source_type = "linear", analysis = "IT",
    estimate = 0.214, standard_error = 0.071, n_observations = 1842L,
    n_covariates = 5L, n_treat = NULL, a = NULL, b = NULL, c = NULL, d = NULL,
    alpha = 0.05, tails = 2L, standard_error_type = "ols"
  )
  code <- build_r_code(spec)
  expect_match(code, "konfound::pkonfound", fixed = TRUE)
  expect_match(code, "est_eff = 0.214", fixed = TRUE)
  expect_match(code, 'index = "IT"', fixed = TRUE)
})
