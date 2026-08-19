openai_extraction_instructions <- function() {
  paste(
    "You extract statistical inputs for a KonFound sensitivity analysis.",
    "Use only information explicitly supported by the supplied text.",
    "Never infer or invent a missing estimate, standard error, sample size,",
    "covariate count, cell count, alpha level, or tail count.",
    "Use null for missing numeric values and unknown for missing categories.",
    "Prefer the focal treatment effect in the fully adjusted model when the",
    "text clearly identifies it; otherwise add an ambiguity warning.",
    "Distinguish a standard error from a t statistic, confidence interval,",
    "standard deviation, odds ratio, and log-odds coefficient.",
    "For every extracted value, include a short exact supporting quote and",
    "a human-readable location. Recommend IT for a continuous-outcome linear",
    "model and RIR when replacement-case interpretation is more appropriate.",
    "The user will review and confirm every value before calculation."
  )
}

openai_response_text <- function(body) {
  if (is.character(body$output_text) && length(body$output_text) == 1L) {
    return(body$output_text)
  }

  if (!is.list(body$output)) {
    stop("The OpenAI response did not contain output text.", call. = FALSE)
  }

  candidates <- unlist(lapply(body$output, function(item) {
    if (!is.list(item$content)) return(character())
    unlist(lapply(item$content, function(content) {
      if (identical(content$type, "output_text") && is.character(content$text)) {
        content$text
      } else {
        character()
      }
    }), use.names = FALSE)
  }), use.names = FALSE)

  if (length(candidates) == 0L) {
    stop("The OpenAI response did not contain output text.", call. = FALSE)
  }
  paste(candidates, collapse = "\n")
}

extract_statistics_openai <- function(
    article_text,
    api_key = Sys.getenv("OPENAI_API_KEY"),
    model = Sys.getenv("OPENAI_MODEL", unset = "gpt-5.6-sol"),
    request_performer = httr2::req_perform) {
  if (!nzchar(trimws(api_key))) {
    stop(
      "OPENAI_API_KEY is not configured. Add it to your local .Renviron, restart R, and try again.",
      call. = FALSE
    )
  }
  if (!nzchar(trimws(article_text))) {
    stop("Paste article text or statistical output before extracting.", call. = FALSE)
  }

  schema <- konfound_extraction_schema()
  request_body <- list(
    model = model,
    store = FALSE,
    instructions = openai_extraction_instructions(),
    input = article_text,
    text = list(
      format = list(
        type = "json_schema",
        name = "konfound_statistical_extraction",
        strict = TRUE,
        schema = schema
      )
    )
  )

  request <- httr2::request("https://api.openai.com/v1/responses") |>
    httr2::req_auth_bearer_token(api_key) |>
    httr2::req_headers(`Content-Type` = "application/json") |>
    httr2::req_body_json(request_body, auto_unbox = TRUE) |>
    httr2::req_timeout(90) |>
    httr2::req_error(body = function(response) {
      parsed <- tryCatch(httr2::resp_body_json(response), error = function(...) NULL)
      if (is.list(parsed$error) && nzchar(parsed$error$message %||% "")) {
        parsed$error$message
      } else {
        paste("OpenAI request failed with HTTP", httr2::resp_status(response))
      }
    })

  response <- request_performer(request)
  body <- httr2::resp_body_json(response, simplifyVector = FALSE)
  parsed <- jsonlite::fromJSON(openai_response_text(body), simplifyVector = FALSE)
  normalize_extraction(parsed, source = "OpenAI")
}

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) y else x
}
