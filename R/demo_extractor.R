example_article_text <- function() {
  paste(
    "An OLS model estimated the treatment effect on mathematics achievement",
    "as 0.214 (SE = 0.071, p = .003; N = 1,842). The fully adjusted model",
    "controlled for prior achievement, gender, household income, school size,",
    "and urbanicity. All hypothesis tests were two-sided with alpha = .05."
  )
}

demo_extraction <- function() {
  normalize_extraction(list(
    outcome_type = "continuous",
    model_type = "linear",
    recommended_analysis = "IT",
    estimate = 0.214,
    standard_error = 0.071,
    n_observations = 1842L,
    n_covariates = 5L,
    n_treat = NULL,
    a = NULL,
    b = NULL,
    c = NULL,
    d = NULL,
    alpha = 0.05,
    tails = 2L,
    standard_error_type = "ols",
    summary = paste(
      "The example describes a fully adjusted OLS treatment-effect estimate",
      "for a continuous outcome with five named covariates."
    ),
    evidence = list(
      list(
        field = "estimate, standard_error, n_observations",
        quote = "0.214 (SE = 0.071, p = .003; N = 1,842)",
        location = "First sentence"
      ),
      list(
        field = "n_covariates",
        quote = paste(
          "prior achievement, gender, household income, school size,",
          "and urbanicity"
        ),
        location = "Second sentence"
      ),
      list(
        field = "tails, alpha",
        quote = "two-sided with alpha = .05",
        location = "Final sentence"
      )
    ),
    warnings = character()
  ), source = "Built-in example")
}
