required <- c("shiny", "httr2", "jsonlite", "konfound")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing) > 0L) {
  stop(
    "Missing packages: ", paste(missing, collapse = ", "),
    ". Run source('setup.R') first.",
    call. = FALSE
  )
}

port <- as.integer(Sys.getenv("KONFOUND_PORT", unset = "3838"))
shiny::runApp(".", host = "127.0.0.1", port = port, launch.browser = FALSE)
