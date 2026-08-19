konfound_extraction_schema <- function() {
  nullable_number <- list(type = c("number", "null"))
  nullable_integer <- list(type = c("integer", "null"))

  list(
    type = "object",
    additionalProperties = FALSE,
    required = c(
      "outcome_type", "model_type", "recommended_analysis",
      "estimate", "standard_error", "n_observations", "n_covariates",
      "n_treat", "a", "b", "c", "d", "alpha", "tails",
      "standard_error_type", "summary", "evidence", "warnings"
    ),
    properties = list(
      outcome_type = list(
        type = "string",
        enum = c("continuous", "dichotomous", "unknown")
      ),
      model_type = list(
        type = "string",
        enum = c("linear", "logistic", "two_by_two", "unknown")
      ),
      recommended_analysis = list(
        type = "string",
        enum = c("IT", "RIR", "unknown")
      ),
      estimate = nullable_number,
      standard_error = nullable_number,
      n_observations = nullable_integer,
      n_covariates = nullable_integer,
      n_treat = nullable_integer,
      a = nullable_integer,
      b = nullable_integer,
      c = nullable_integer,
      d = nullable_integer,
      alpha = nullable_number,
      tails = list(type = c("integer", "null"), enum = list(1L, 2L, NULL)),
      standard_error_type = list(
        type = "string",
        enum = c("ols", "robust", "cluster_robust", "unknown")
      ),
      summary = list(type = "string"),
      evidence = list(
        type = "array",
        items = list(
          type = "object",
          additionalProperties = FALSE,
          required = c("field", "quote", "location"),
          properties = list(
            field = list(type = "string"),
            quote = list(type = "string"),
            location = list(type = "string")
          )
        )
      ),
      warnings = list(type = "array", items = list(type = "string"))
    )
  )
}
