library(testthat)

invisible(lapply(sort(list.files("R", full.names = TRUE, pattern = "\\.R$")), source))

plot_sink <- tempfile(fileext = ".pdf")
grDevices::pdf(plot_sink)
tryCatch(
  test_dir("tests/testthat"),
  finally = {
    grDevices::dev.off()
    unlink(plot_sink)
  }
)
