required <- c("shiny", "httr2", "jsonlite", "konfound")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing) > 0) {
  stop(
    "Missing packages: ", paste(missing, collapse = ", "),
    ". Run source('setup.R') first.",
    call. = FALSE
  )
}

shiny::runApp(".", launch.browser = TRUE)
