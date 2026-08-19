as_nullable_number <- function(x) {
  if (is.null(x) || length(x) == 0L || is.na(x) || identical(x, "")) return(NULL)
  value <- suppressWarnings(as.numeric(x))
  if (is.na(value)) NULL else value
}

as_nullable_integer <- function(x) {
  value <- as_nullable_number(x)
  if (is.null(value)) NULL else as.integer(round(value))
}

normalize_evidence <- function(evidence) {
  if (is.null(evidence) || length(evidence) == 0L) return(list())
  lapply(evidence, function(item) {
    list(
      field = as.character(item$field %||% ""),
      quote = as.character(item$quote %||% ""),
      location = as.character(item$location %||% "")
    )
  })
}

normalize_extraction <- function(x, source = "Unknown") {
  list(
    source = source,
    outcome_type = as.character(x$outcome_type %||% "unknown"),
    model_type = as.character(x$model_type %||% "unknown"),
    recommended_analysis = as.character(x$recommended_analysis %||% "unknown"),
    estimate = as_nullable_number(x$estimate),
    standard_error = as_nullable_number(x$standard_error),
    n_observations = as_nullable_integer(x$n_observations),
    n_covariates = as_nullable_integer(x$n_covariates),
    n_treat = as_nullable_integer(x$n_treat),
    a = as_nullable_integer(x$a),
    b = as_nullable_integer(x$b),
    c = as_nullable_integer(x$c),
    d = as_nullable_integer(x$d),
    alpha = as_nullable_number(x$alpha),
    tails = as_nullable_integer(x$tails),
    standard_error_type = as.character(x$standard_error_type %||% "unknown"),
    summary = as.character(x$summary %||% ""),
    evidence = normalize_evidence(x$evidence),
    warnings = as.character(unlist(x$warnings %||% character(), use.names = FALSE))
  )
}

collect_specification <- function(input) {
  source_type <- input$source_type %||% "linear"
  list(
    outcome_type = input$outcome_type %||% "continuous",
    source_type = source_type,
    analysis = input$analysis %||% if (source_type == "linear") "IT" else "RIR",
    estimate = as_nullable_number(input$estimate),
    standard_error = as_nullable_number(input$standard_error),
    n_observations = as_nullable_integer(input$n_observations),
    n_covariates = as_nullable_integer(input$n_covariates),
    n_treat = as_nullable_integer(input$n_treat),
    a = as_nullable_integer(input$a),
    b = as_nullable_integer(input$b),
    c = as_nullable_integer(input$c),
    d = as_nullable_integer(input$d),
    alpha = as_nullable_number(input$alpha),
    tails = as_nullable_integer(input$tails),
    standard_error_type = input$standard_error_type %||% "unknown"
  )
}

validate_specification <- function(spec) {
  errors <- character()
  warnings <- character()

  if (identical(spec$source_type, "two_by_two")) {
    cells <- unlist(spec[c("a", "b", "c", "d")])
    if (length(cells) != 4L || any(is.na(cells)) || any(cells < 0)) {
      errors <- c(errors, "All four 2 x 2 table cell counts must be non-negative integers.")
    }
  } else {
    if (is.null(spec$estimate)) errors <- c(errors, "Estimate is required.")
    if (is.null(spec$standard_error) || spec$standard_error <= 0) {
      errors <- c(errors, "Standard error must be greater than zero.")
    }
    if (is.null(spec$n_observations) || spec$n_observations < 3) {
      errors <- c(errors, "Number of observations must be at least 3.")
    }
    if (is.null(spec$n_covariates) || spec$n_covariates < 0) {
      errors <- c(errors, "Number of covariates must be zero or greater.")
    }
    if (!is.null(spec$n_observations) && !is.null(spec$n_covariates) &&
        spec$n_observations <= spec$n_covariates + 2) {
      errors <- c(errors, "Observations must exceed covariates by more than two.")
    }
  }

  if (is.null(spec$alpha) || spec$alpha <= 0 || spec$alpha >= 1) {
    errors <- c(errors, "Alpha must be between 0 and 1.")
  }
  if (is.null(spec$tails) || !spec$tails %in% c(1L, 2L)) {
    errors <- c(errors, "Tails must be 1 or 2.")
  }
  if (identical(spec$source_type, "logistic") &&
      (is.null(spec$n_treat) || spec$n_treat < 1)) {
    errors <- c(errors, "Logistic input requires the number in the treatment group.")
  }
  if (identical(spec$analysis, "IT") &&
      !spec$standard_error_type %in% c("ols", "unknown")) {
    warnings <- c(
      warnings,
      "ITCV assumptions may not match robust or clustered standard errors; review the method choice."
    )
  }
  if (!identical(spec$source_type, "two_by_two") &&
      identical(spec$standard_error_type, "unknown")) {
    warnings <- c(warnings, "The standard-error type is unknown; confirm it against the source.")
  }

  list(valid = length(errors) == 0L, errors = unique(errors), warnings = unique(warnings))
}
