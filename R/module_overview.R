#' Overview module — landing page summarising the panel audit.
#'
#' Renders `subpanel_summary_v2.csv` as a `DT::datatable` and a `plotly`
#' bar chart of `n_genes`. Selecting a row sets `app_state$selected_subpanel`
#' and `app_state$nav_target = "panel_browser"`, which the app-level server
#' watches to switch tabs and pre-select the panel.

overview_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 320,
      shiny::h5("Audit overview"),
      shiny::p("Source: ", shiny::code("subpanel_summary_v2.csv")),
      shiny::p("Click a row to open the panel browser pre-filtered to ",
               "that subpanel."),
      shiny::uiOutput(ns("counts"))
    ),
    shiny::uiOutput(ns("env_card")),
    bslib::card(
      bslib::card_header("Genes per subpanel"),
      plotly::plotlyOutput(ns("nbar"), height = "320px")
    ),
    bslib::card(
      bslib::card_header("Subpanels"),
      DT::DTOutput(ns("summary"))
    )
  )
}

overview_server <- function(id, panels, app_state) {
  shiny::moduleServer(id, function(input, output, session) {

    output$env_card <- shiny::renderUI({
      errs <- app_state$env_errors   %||% character()
      warn <- app_state$env_warnings %||% character()
      if (!length(errs) && !length(warn)) return(NULL)
      bullets <- function(items) shiny::tags$ul(
        lapply(items, function(s) shiny::tags$li(s)))
      cls <- if (length(errs)) "alert alert-danger" else "alert alert-warning"
      shiny::div(class = cls,
        if (length(errs)) shiny::tagList(
          shiny::strong("Environment errors"), bullets(errs)),
        if (length(warn)) shiny::tagList(
          shiny::strong("Environment warnings"), bullets(warn)))
    })

    output$counts <- shiny::renderUI({
      p <- panels()
      shiny::tagList(
        shiny::p(shiny::strong("Subpanels indexed: "),
                 nrow(p$summary)),
        shiny::p(shiny::strong("CSV files loaded: "),
                 length(p$subpanels)),
        shiny::p(shiny::strong("5K-shared genes: "),
                 nrow(p$xenium5k)),
        shiny::p(shiny::strong("Custom T1D-GWAS genes: "),
                 nrow(p$custom))
      )
    })

    output$summary <- DT::renderDT({
      DT::datatable(
        panels()$summary,
        rownames  = FALSE,
        selection = list(mode = "single", selected = NULL),
        options   = list(pageLength = 25, order = list(list(0, "asc"))),
        class     = "stripe hover compact"
      )
    })

    output$nbar <- plotly::renderPlotly({
      df <- panels()$summary
      df <- df[order(df$n_genes, decreasing = TRUE), , drop = FALSE]
      df$subpanel <- factor(df$subpanel, levels = df$subpanel)
      plotly::plot_ly(
        df,
        x      = ~n_genes,
        y      = ~subpanel,
        type   = "bar",
        orientation = "h",
        hoverinfo   = "text",
        text   = ~paste0(subpanel, " — ", n_genes, " genes<br>", description)
      ) |>
        plotly::layout(
          margin = list(l = 220),
          xaxis  = list(title = "n_genes"),
          yaxis  = list(title = "", autorange = "reversed"),
          showlegend = FALSE
        )
    })

    shiny::observeEvent(input$summary_rows_selected, {
      idx <- input$summary_rows_selected
      if (length(idx) != 1L) return()
      sp <- panels()$summary$subpanel[idx]
      key <- resolve_subpanel_key(sp, panels())
      app_state$selected_subpanel <- if (is.na(key)) sp else key
      app_state$nav_target        <- "Panel Browser"
    }, ignoreInit = TRUE)
  })
}
