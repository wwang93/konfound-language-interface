project_library <- file.path(
  getwd(),
  "library",
  paste(R.version$major, strsplit(R.version$minor, "\\.")[[1]][1], sep = ".")
)
dir.create(project_library, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(
  normalizePath(project_library, winslash = "/"),
  normalizePath(R.home("library"), winslash = "/")
))

packages <- c(
  "shiny",
  "httr2",
  "jsonlite",
  "konfound",
  "testthat"
)

missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0) {
  install.packages(
    missing,
    lib = project_library,
    repos = "https://cloud.r-project.org",
    dependencies = c("Depends", "Imports", "LinkingTo"),
    type = if (.Platform$OS.type == "windows") "binary" else "source"
  )
}

still_missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(still_missing) > 0L) {
  stop(
    "Dependency installation did not complete: ",
    paste(still_missing, collapse = ", "),
    call. = FALSE
  )
}

versions <- vapply(packages, function(package) {
  as.character(utils::packageVersion(package))
}, character(1))
message("MVP dependencies are installed: ", paste(names(versions), versions, collapse = ", "))
