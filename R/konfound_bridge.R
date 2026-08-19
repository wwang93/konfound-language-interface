format_number <- function(x, digits = 3L) {
  if (is.null(x) || length(x) == 0L || is.na(x)) return("not available")
  formatC(as.numeric(x), digits = digits, format = "fg", flag = "#")
}

named_value <- function(x, candidates) {
  if (is.null(x)) return(NULL)
  for (candidate in candidates) {
    if (!is.null(x[[candidate]])) return(x[[candidate]])
  }
  NULL
}

build_konfound_args <- function(spec, to_return = "raw_output") {
  args <- list(
    alpha = spec$alpha,
    tails = spec$tails,
    index = spec$analysis,
    to_return = to_return
  )

  if (identical(spec$source_type, "two_by_two")) {
    args[c("a", "b", "c", "d")] <- spec[c("a", "b", "c", "d")]
    args$model_type <- "logistic"
  } else {
    args$est_eff <- spec$estimate
    args$std_err <- spec$standard_error
    args$n_obs <- spec$n_observations
    args$n_covariates <- spec$n_covariates
    if (identical(spec$source_type, "logistic")) {
      args$model_type <- "logistic"
      args$n_treat <- spec$n_treat
    }
  }
  args
}

build_r_code <- function(spec) {
  args <- build_konfound_args(spec, to_return = "raw_output")
  rendered <- vapply(names(args), function(name) {
    value <- args[[name]]
    if (is.character(value)) value <- dQuote(value)
    paste0("  ", name, " = ", value)
  }, character(1))
  paste0("result <- konfound::pkonfound(\n", paste(rendered, collapse = ",\n"), "\n)")
}

summarize_konfound_result <- function(raw, spec) {
  if (identical(spec$analysis, "IT")) {
    itcv <- named_value(raw, c("itcvGz", "itcv", "ITCV", "impact_threshold"))
    r_x <- named_value(raw, c("rxcvGz", "r_x_cv", "cor_x_cv"))
    r_y <- named_value(raw, c("rycvGz", "r_y_cv", "cor_y_cv"))
    headline <- paste0("Impact Threshold: ", format_number(itcv))
    detail <- paste0(
      "A confounder would need component correlations of about ",
      format_number(r_x), " with the predictor and ", format_number(r_y),
      " with the outcome to move the inference across the chosen threshold."
    )
  } else {
    rir <- named_value(raw, c("RIR", "rir", "RIR_primary", "replacement_cases"))
    pct <- named_value(raw, c("RIR_perc", "rir_perc", "perc_bias_to_change", "percent_replaced"))
    headline <- paste0("Robustness of Inference to Replacement: ", format_number(rir, 0L))
    detail <- paste0(
      "The result corresponds to approximately ", format_number(pct),
      "% of observations under the package's replacement-case formulation."
    )
  }
  list(headline = headline, detail = detail)
}

run_konfound_analysis <- function(spec) {
  validation <- validate_specification(spec)
  if (!validation$valid) {
    stop(paste(validation$errors, collapse = " "), call. = FALSE)
  }
  if (!requireNamespace("konfound", quietly = TRUE)) {
    stop("The konfound package is not installed. Run source('setup.R').", call. = FALSE)
  }

  args <- build_konfound_args(spec, to_return = "raw_output")
  raw <- do.call(konfound::pkonfound, args)
  printed <- paste(utils::capture.output(
    do.call(konfound::pkonfound, build_konfound_args(spec, to_return = "print"))
  ), collapse = "\n")

  list(
    raw = raw,
    printed = printed,
    summary = summarize_konfound_result(raw, spec),
    warnings = validation$warnings,
    code = build_r_code(spec),
    package_version = as.character(utils::packageVersion("konfound"))
  )
}
