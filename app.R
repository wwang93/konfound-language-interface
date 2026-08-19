required_packages <- c("shiny", "httr2", "jsonlite")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing packages: ", paste(missing_packages, collapse = ", "),
    ". Run source('setup.R') before starting the app.",
    call. = FALSE
  )
}

invisible(lapply(sort(list.files("R", full.names = TRUE, pattern = "\\.R$")), source))

library(shiny)

logo_block <- tags$div(
  class = "brand-block",
  tags$div(class = "brand-mark", tags$span(), tags$span(), tags$span()),
  tags$div(
    class = "brand-copy",
    tags$div(class = "brand-name", "KonFound-it!"),
    tags$div(class = "brand-tagline", "Sensitivity analysis, now with a language interface")
  )
)

app_header <- tags$header(
  class = "hero",
  tags$div(
    class = "hero-top",
    logo_block,
    tags$label(
      class = "theme-switch",
      tags$input(id = "theme_toggle", type = "checkbox"),
      tags$span(class = "theme-slider"),
      tags$span(class = "theme-label", "Dark mode")
    )
  ),
  tags$div(
    class = "hero-copy",
    tags$h1("Quantify the Robustness of Causal Inferences"),
    tags$p("Extract, verify, and analyze published statistical results without hiding the assumptions."),
    tags$div(
      class = "hero-actions",
      actionButton("jump_to_input", "Start with article text", class = "btn-brand"),
      tags$span(class = "powered-by", "Powered locally by konfound; language extraction uses the OpenAI API")
    )
  )
)

step_card <- function(number, title, ...) {
  tags$section(
    class = "step-card",
    tags$div(
      class = "step-heading",
      tags$span(class = "step-number", number),
      tags$h3(title)
    ),
    ...
  )
}

ui <- fluidPage(
  tags$head(
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$script(src = "app.js")
  ),
  class = "app-shell",
  app_header,
  tags$nav(
    class = "app-nav",
    tags$button(type = "button", class = "nav-item active", `data-tab` = "home", icon("house"), " Home"),
    tags$button(type = "button", class = "nav-item", `data-tab` = "resources", icon("screwdriver-wrench"), " Resources")
  ),
  tags$main(
    class = "content-wrap",
    tags$div(
      id = "home",
      class = "tab-page active",
      tags$div(
        class = "workspace-grid",
        tags$aside(
          id = "specification_panel",
          class = "panel specification-panel",
          tags$div(class = "panel-title", icon("sliders"), tags$h2("Specification")),
          step_card(
            "0", "Bring your evidence",
            textAreaInput(
              "article_text", NULL,
              placeholder = paste(
                "Paste a results paragraph, regression table copied as text,",
                "or statistical software output..."
              ),
              rows = 9,
              width = "100%"
            ),
            tags$div(
              class = "input-actions",
              actionButton("extract", "Extract statistics", icon = icon("wand-magic-sparkles"), class = "btn-brand"),
              actionButton("load_example", "Load example", icon = icon("flask"), class = "btn-secondary")
            ),
            uiOutput("api_status")
          ),
          step_card(
            "1", "What type of outcome variable?",
            radioButtons(
              "outcome_type", NULL,
              choices = c("Continuous" = "continuous", "Dichotomous" = "dichotomous"),
              selected = "continuous"
            )
          ),
          step_card("2", "What is the data source?", uiOutput("source_type_ui")),
          step_card("3", "What analysis do you want?", uiOutput("analysis_ui")),
          step_card(
            "4", "Review and confirm inputs",
            tags$p(class = "microcopy", "AI suggestions are drafts. Compare each value with the evidence before calculating."),
            uiOutput("parameter_inputs"),
            uiOutput("standard_error_type_ui"),
            checkboxInput("confirmed", "I reviewed these values against the source text.", FALSE),
            actionButton("run_analysis", "Run sensitivity analysis", icon = icon("chart-line"), class = "btn-run")
          )
        ),
        tags$section(
          class = "panel results-panel",
          tags$div(class = "panel-title", icon("chart-column"), tags$h2("Results")),
          uiOutput("extraction_review"),
          uiOutput("analysis_result")
        )
      )
    ),
    tags$div(
      id = "resources",
      class = "tab-page",
      tags$section(
        class = "panel resource-panel",
        tags$div(class = "panel-title", icon("book-open"), tags$h2("Resources & privacy")),
        tags$div(
          class = "resource-grid",
          tags$article(
            tags$h3("How this MVP works"),
            tags$p("The Shiny interface and sensitivity calculations run on this computer. When you click Extract statistics, the pasted text is sent to the OpenAI API and is not sent anywhere by the demo example button."),
            tags$p("The extraction returns structured fields plus evidence quotes. Nothing is calculated until you review the fields and explicitly confirm them.")
          ),
          tags$article(
            tags$h3("API configuration"),
            tags$p("Store OPENAI_API_KEY only in your local .Renviron file. The key is read by the R backend and is never rendered in the browser."),
            tags$p("OPENAI_MODEL is optional. The default is gpt-5.6-sol and can be changed without editing the app.")
          ),
          tags$article(
            tags$h3("Method boundaries"),
            tags$p("A language model can misread tables, choose the wrong model, or confuse a standard error with another statistic. Evidence review is a required part of the workflow, not a cosmetic step."),
            tags$a(href = "https://konfound-project.github.io/konfound/", target = "_blank", "KonFound documentation ", icon("arrow-up-right-from-square"))
          )
        )
      )
    )
  ),
  tags$footer(
    tags$span("Standalone local MVP • No upstream pull request"),
    tags$span("OpenAI extraction is optional; konfound calculation is deterministic")
  )
)

server <- function(input, output, session) {
  extraction <- reactiveVal(NULL)
  analysis <- reactiveVal(NULL)
  api_error <- reactiveVal(NULL)

  output$api_status <- renderUI({
    configured <- nzchar(trimws(Sys.getenv("OPENAI_API_KEY")))
    tags$div(
      class = paste("status-pill", if (configured) "ready" else "waiting"),
      icon(if (configured) "circle-check" else "circle-info"),
      if (configured) {
        paste("API ready •", Sys.getenv("OPENAI_MODEL", unset = "gpt-5.6-sol"))
      } else {
        "API key not configured • example mode is available"
      }
    )
  })

  output$source_type_ui <- renderUI({
    if (identical(input$outcome_type, "dichotomous")) {
      current_source <- isolate(input$source_type %||% "logistic")
      extracted <- extraction()
      extracted_source <- if (!is.null(extracted)) {
        switch(extracted$model_type, logistic = "logistic", two_by_two = "two_by_two", NULL)
      } else {
        NULL
      }
      selected_source <- if (!is.null(extracted_source)) extracted_source else current_source
      radioButtons(
        "source_type", NULL,
        choices = c("Logistic regression" = "logistic", "2 x 2 table" = "two_by_two"),
        selected = if (selected_source %in% c("logistic", "two_by_two")) selected_source else "logistic"
      )
    } else {
      radioButtons("source_type", NULL, choices = c("Linear regression" = "linear"), selected = "linear")
    }
  })

  output$analysis_ui <- renderUI({
    if (identical(input$outcome_type, "dichotomous")) {
      radioButtons(
        "analysis", NULL,
        choices = c("RIR — replacement cases" = "RIR"),
        selected = "RIR"
      )
    } else {
      current_analysis <- isolate(input$analysis %||% "IT")
      extracted <- extraction()
      recommended <- if (!is.null(extracted)) extracted$recommended_analysis else ""
      selected_analysis <- if (recommended %in% c("IT", "RIR")) recommended else current_analysis
      radioButtons(
        "analysis", NULL,
        choices = c(
          "ITCV — impact threshold" = "IT",
          "RIR — replacement cases" = "RIR"
        ),
        selected = if (selected_analysis %in% c("IT", "RIR")) selected_analysis else "IT"
      )
    }
  })

  output$parameter_inputs <- renderUI({
    source_type <- input$source_type %||% "linear"
    extracted <- extraction()
    extracted_value <- function(name, default = NA) {
      if (!is.null(extracted) && !is.null(extracted[[name]])) extracted[[name]] else default
    }
    if (identical(source_type, "two_by_two")) {
      tagList(
        tags$div(
          class = "input-grid two-by-two-grid",
          numericInput("a", "Treatment + outcome", value = extracted_value("a"), min = 0, step = 1),
          numericInput("b", "Treatment + no outcome", value = extracted_value("b"), min = 0, step = 1),
          numericInput("c", "Control + outcome", value = extracted_value("c"), min = 0, step = 1),
          numericInput("d", "Control + no outcome", value = extracted_value("d"), min = 0, step = 1)
        ),
        tags$div(
          class = "input-grid",
          numericInput("alpha", "Alpha", value = extracted_value("alpha", 0.05), min = 0.001, max = 0.999, step = 0.001),
          selectInput("tails", "Tails", choices = c("Two-sided" = 2L, "One-sided" = 1L), selected = extracted_value("tails", 2L))
        )
      )
    } else {
      tagList(
        tags$div(
          class = "input-grid",
          numericInput("estimate", "Effect estimate", value = extracted_value("estimate")),
          numericInput("standard_error", "Standard error", value = extracted_value("standard_error"), min = 0),
          numericInput("n_observations", "Observations", value = extracted_value("n_observations"), min = 3, step = 1),
          numericInput("n_covariates", "Covariates", value = extracted_value("n_covariates"), min = 0, step = 1),
          if (identical(source_type, "logistic")) {
            numericInput("n_treat", "Treatment-group N", value = extracted_value("n_treat"), min = 1, step = 1)
          },
          numericInput("alpha", "Alpha", value = extracted_value("alpha", 0.05), min = 0.001, max = 0.999, step = 0.001),
          selectInput("tails", "Tails", choices = c("Two-sided" = 2L, "One-sided" = 1L), selected = extracted_value("tails", 2L))
        )
      )
    }
  })

  output$standard_error_type_ui <- renderUI({
    if (identical(input$source_type, "two_by_two")) return(NULL)
    extracted <- extraction()
    selected_type <- if (!is.null(extracted)) extracted$standard_error_type else "unknown"
    selectInput(
      "standard_error_type", "Standard-error type",
      choices = c(
        "Ordinary least squares" = "ols",
        "Robust" = "robust",
        "Cluster robust" = "cluster_robust",
        "Unknown / not reported" = "unknown"
      ),
      selected = selected_type %||% "unknown"
    )
  })

  apply_extraction <- function(result) {
    extraction(result)
    api_error(NULL)

    if (result$outcome_type %in% c("continuous", "dichotomous")) {
      updateRadioButtons(session, "outcome_type", selected = result$outcome_type)
    }
  }

  observeEvent(input$load_example, {
    updateTextAreaInput(session, "article_text", value = example_article_text())
    apply_extraction(demo_extraction())
    analysis(NULL)
    showNotification("Example loaded. Review the highlighted evidence and inputs.", type = "message")
  })

  observeEvent(input$extract, {
    article_text <- trimws(input$article_text %||% "")
    if (!nzchar(article_text)) {
      showNotification("Paste article text or software output first.", type = "warning")
      return()
    }
    max_input_chars <- suppressWarnings(as.integer(Sys.getenv("KONFOUND_MAX_INPUT_CHARS", unset = "20000")))
    if (is.na(max_input_chars) || max_input_chars < 1L) max_input_chars <- 20000L
    if (nchar(article_text, type = "chars") > max_input_chars) {
      showNotification(
        sprintf("This MVP accepts up to %s characters per extraction.", format(max_input_chars, big.mark = ",")),
        type = "warning"
      )
      return()
    }
    if (!nzchar(trimws(Sys.getenv("OPENAI_API_KEY")))) {
      api_error("OPENAI_API_KEY is not configured. Follow the Resources tab, or use Load example now.")
      showNotification("API key is not configured; the built-in example remains available.", type = "warning")
      return()
    }

    result <- tryCatch(
      withProgress(message = "Extracting statistical evidence...", value = 0.35, {
        extract_statistics_openai(article_text)
      }),
      error = function(error) error
    )
    if (inherits(result, "error")) {
      api_error(conditionMessage(result))
      showNotification(conditionMessage(result), type = "error", duration = NULL)
    } else {
      apply_extraction(result)
      analysis(NULL)
      showNotification("Extraction complete. Confirm every value before analysis.", type = "message")
    }
  })

  output$extraction_review <- renderUI({
    result <- extraction()
    error <- api_error()
    if (!is.null(error)) {
      return(tags$div(class = "alert-card alert-error", icon("triangle-exclamation"), tags$div(tags$strong("Extraction unavailable"), tags$p(error))))
    }
    if (is.null(result)) {
      return(tags$div(
        class = "empty-state",
        tags$div(class = "empty-icon", icon("file-circle-question")),
        tags$h3("Your reviewable extraction will appear here"),
        tags$p("Paste a result, or load the built-in example to walk through the complete workflow."),
        tags$ol(
          tags$li("Extract candidate statistics and their supporting quotes."),
          tags$li("Correct any value that does not match the source."),
          tags$li("Confirm the inputs, then run the deterministic KonFound calculation.")
        )
      ))
    }

    evidence_rows <- lapply(result$evidence, function(item) {
      tags$tr(
        tags$td(tags$code(item$field)),
        tags$td(tags$q(item$quote)),
        tags$td(item$location)
      )
    })
    warning_items <- c(result$warnings, if (length(result$warnings) == 0L) "No extraction warnings were returned." else character())

    tags$section(
      class = "result-block extraction-block",
      tags$div(
        class = "result-block-heading",
        tags$div(tags$span(class = "eyebrow", "EXTRACTION REVIEW"), tags$h3(result$summary)),
        tags$span(class = "source-badge", result$source)
      ),
      tags$div(
        class = "warning-strip",
        icon(if (length(result$warnings) == 0L) "circle-check" else "triangle-exclamation"),
        tags$ul(lapply(warning_items, tags$li))
      ),
      tags$div(
        class = "table-scroll",
        tags$table(
          class = "evidence-table",
          tags$thead(tags$tr(tags$th("Field"), tags$th("Evidence quote"), tags$th("Location"))),
          tags$tbody(evidence_rows)
        )
      )
    )
  })

  observeEvent(input$run_analysis, {
    if (!isTRUE(input$confirmed)) {
      showNotification("Review the source and confirm the inputs before calculating.", type = "warning")
      return()
    }
    spec <- collect_specification(input)
    validation <- validate_specification(spec)
    if (!validation$valid) {
      showNotification(paste(validation$errors, collapse = " "), type = "error", duration = NULL)
      return()
    }

    result <- tryCatch(
      withProgress(message = "Running KonFound analysis...", value = 0.5, {
        run_konfound_analysis(spec)
      }),
      error = function(error) error
    )
    analysis(list(spec = spec, result = result))
    if (inherits(result, "error")) {
      showNotification(conditionMessage(result), type = "error", duration = NULL)
    }
  })

  output$robustness_plot <- renderPlot({
    state <- analysis()
    req(state, !inherits(state$result, "error"))
    raw <- state$result$raw
    spec <- state$spec
    old_par <- par(no.readonly = TRUE)
    on.exit(par(old_par))
    par(mar = c(4.2, 4.2, 2.1, 1.2), family = "sans")

    if (identical(spec$analysis, "IT")) {
      r_x <- as.numeric(named_value(raw, c("rxcvGz", "r_x_cv", "cor_x_cv")) %||% 0)
      r_y <- as.numeric(named_value(raw, c("rycvGz", "r_y_cv", "cor_y_cv")) %||% 0)
      plot(
        r_x, r_y,
        xlim = c(-1, 1), ylim = c(-1, 1), pch = 21, cex = 2.2,
        bg = "#7EA335", col = "#315965",
        xlab = "Confounder–predictor correlation",
        ylab = "Confounder–outcome correlation"
      )
      abline(h = 0, v = 0, col = "#D5DEE1", lty = 2)
      text(r_x, r_y, labels = " threshold", pos = 4, col = "#315965")
    } else {
      pct <- as.numeric(named_value(raw, c("RIR_perc", "rir_perc", "perc_bias_to_change", "percent_replaced")) %||% 0)
      pct <- min(max(pct, 0), 100)
      barplot(
        pct,
        horiz = TRUE,
        xlim = c(0, 100), axes = FALSE, border = NA, col = "#7EA335",
        xlab = "Percent of observations represented by the RIR"
      )
      axis(1, at = seq(0, 100, 20), labels = paste0(seq(0, 100, 20), "%"))
      abline(v = 50, lty = 3, col = "#6B7B80")
    }
  }, bg = "transparent", height = 310)

  output$analysis_result <- renderUI({
    state <- analysis()
    if (is.null(state)) return(NULL)
    if (inherits(state$result, "error")) {
      return(tags$div(class = "alert-card alert-error", icon("circle-xmark"), tags$div(tags$strong("Analysis could not run"), tags$p(conditionMessage(state$result)))))
    }

    result <- state$result
    tags$section(
      class = "result-block analysis-block",
      tags$div(
        class = "result-block-heading",
        tags$div(tags$span(class = "eyebrow", "SENSITIVITY RESULT"), tags$h3(result$summary$headline)),
        tags$span(class = "source-badge", paste("konfound", result$package_version))
      ),
      tags$p(class = "result-explanation", result$summary$detail),
      if (length(result$warnings) > 0L) {
        tags$div(class = "warning-strip", icon("triangle-exclamation"), tags$ul(lapply(result$warnings, tags$li)))
      },
      tags$div(class = "plot-card", plotOutput("robustness_plot")),
      tags$details(
        class = "details-card",
        tags$summary("Package output"),
        tags$pre(result$printed)
      ),
      tags$details(
        class = "details-card",
        tags$summary("Reproducible R code"),
        tags$div(class = "code-toolbar", actionButton("copy_code", "Copy code", icon = icon("copy"), class = "btn-small")),
        tags$pre(class = "code-block", result$code)
      )
    )
  })

  observeEvent(input$copy_code, {
    state <- analysis()
    req(state, !inherits(state$result, "error"))
    session$sendCustomMessage("copyText", state$result$code)
    showNotification("R code copied to the clipboard.", type = "message")
  })

  observeEvent(input$jump_to_input, {
    session$sendCustomMessage("scrollTo", "specification_panel")
  })
}

shinyApp(ui, server)
