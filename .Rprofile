project_library <- file.path(
  getwd(),
  "library",
  paste(R.version$major, strsplit(R.version$minor, "\\.")[[1]][1], sep = ".")
)
if (dir.exists(project_library)) {
  .libPaths(c(normalizePath(project_library, winslash = "/"), .libPaths()))
}
options(repos = c(CRAN = "https://cloud.r-project.org"))
