#' Panel Browser module — selectizeInput across the 49 subpanels + custom + 5K.
#'
#' Layout: sidebar with a selectize for the primary panel, a second
#' selectize for an optional comparison panel, a download button, and a
#' filter for `exclude_recommended`. Main panel: a gene `DT`, a `plotly`
#' detection-percentage scatter, and a 2-set comparison summary.

panel_browser_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 320,
      shinyWidgets_or_shiny_selectize(ns("panel"),  "Primary panel",
                                      choices = NULL, multiple = FALSE),
      shinyWidgets_or_shiny_selectize(ns("compare"), "Compare with (optional)",
                                      choices = NULL, multiple = FALSE),
      shiny::checkboxInput(ns("hide_excluded"),
                           "Hide genes with exclude_recommended = yes",
                           value = FALSE),
      shiny::p(shiny::strong("Tip: "),
               "select two panels to see set-overlap stats below the table.")
    ),
    bslib::card(
      bslib::card_header(shiny::textOutput(ns("primary_caption"),
                                           inline = TRUE)),
      DT::DTOutput(ns("genes"))
    ),
    bslib::card(
      bslib::card_header("Detection across the two reference Xenium runs"),
      shiny::p("Each point is a gene in the primary panel. ",
               "x = ", shiny::code("detection_pct_0041323"),
               ", y = ", shiny::code("detection_pct_0041326"),
               ", colour = ", shiny::code("log2_detection_ratio_326_over_323"),
               ". Diagonal is y = x."),
      plotly::plotlyOutput(ns("scatter"), height = "420px")
    ),
    bslib::card(
      bslib::card_header("Overlap with comparison panel"),
      shiny::uiOutput(ns("compare_summary"))
    )
  )
}

# Use shiny's built-in selectize; we wrap via this thin shim so the call
# site can be swapped to shinyWidgets later if M10 polish wants it.
shinyWidgets_or_shiny_selectize <- function(id, label, choices, multiple) {
  shiny::selectizeInput(id, label, choices = choices, multiple = multiple,
                        options = list(allowEmptyOption = TRUE,
                                       placeholder = "(none)"))
}

panel_browser_server <- function(id, panels, app_state) {
  shiny::moduleServer(id, function(input, output, session) {

    panel_choices <- shiny::reactive({
      p <- panels()
      c(
        # the 49 subpanels in numeric order, then 99 / 99c / 99d
        sort(p$meta$subpanel_keys),
        # ancillaries
        "custom_T1D_GWAS_panel",
        "xenium5k_in_audit"
      )
    })

    shiny::observe({
      shiny::updateSelectizeInput(session, "panel",
                                  choices = panel_choices(),
                                  server  = TRUE,
                                  selected = panel_choices()[1])
      shiny::updateSelectizeInput(session, "compare",
                                  choices = c("(none)", panel_choices()),
                                  server  = TRUE,
                                  selected = "(none)")
    })

    # External nav from Overview: a subpanel key arrives via app_state
    shiny::observeEvent(app_state$selected_subpanel, {
      sel <- app_state$selected_subpanel
      if (is.null(sel) || !nzchar(sel)) return()
      if (sel %in% panel_choices()) {
        shiny::updateSelectizeInput(session, "panel", selected = sel)
      }
    }, ignoreNULL = TRUE)

    get_panel_df <- function(key) {
      p <- panels()
      if (is.null(key) || !nzchar(key) || identical(key, "(none)")) return(NULL)
      if (key == "custom_T1D_GWAS_panel") return(p$custom)
      if (key == "xenium5k_in_audit")    return(p$xenium5k)
      p$subpanels[[key]]
    }

    primary_df <- shiny::reactive({
      df <- get_panel_df(input$panel)
      if (is.null(df)) return(NULL)
      if (isTRUE(input$hide_excluded) &&
          "exclude_recommended" %in% names(df)) {
        df <- df[!(df$exclude_recommended %in% c("yes", "TRUE", "true")), ,
                 drop = FALSE]
      }
      df
    })

    compare_df <- shiny::reactive({
      get_panel_df(input$compare)
    })

    output$primary_caption <- shiny::renderText({
      df <- primary_df()
      if (is.null(df)) return("Select a panel.")
      sprintf("%s — %d genes", input$panel, nrow(df))
    })

    output$genes <- DT::renderDT({
      df <- primary_df()
      shiny::req(df)
      DT::datatable(
        df,
        rownames = FALSE,
        filter   = "top",
        options  = list(pageLength = 25, scrollX = TRUE,
                        autoWidth = FALSE),
        class    = "stripe hover compact nowrap"
      )
    })

    output$scatter <- plotly::renderPlotly({
      df <- primary_df()
      shiny::req(df)
      need <- c("detection_pct_0041323", "detection_pct_0041326")
      if (!all(need %in% names(df))) {
        return(plotly::plotly_empty(type = "scatter", mode = "markers") |>
                 plotly::layout(annotations = list(list(
                   text = "Detection columns not present for this panel.",
                   showarrow = FALSE, x = 0.5, y = 0.5, xref = "paper",
                   yref = "paper"))))
      }
      colour_col <- if ("log2_detection_ratio_326_over_323" %in% names(df))
        df$log2_detection_ratio_326_over_323 else NA
      plotly::plot_ly(
        df,
        x = ~detection_pct_0041323,
        y = ~detection_pct_0041326,
        type = "scatter", mode = "markers",
        marker = list(size = 6, color = colour_col,
                      colorbar = list(title = "log2 326/323"),
                      colorscale = "RdBu", reversescale = TRUE,
                      cmid = 0),
        text = ~gene, hoverinfo = "text+x+y"
      ) |>
        plotly::layout(
          xaxis = list(title = "detection_pct_0041323"),
          yaxis = list(title = "detection_pct_0041326",
                       scaleanchor = "x", scaleratio = 1),
          shapes = list(list(type = "line", x0 = 0, y0 = 0, x1 = 100,
                              y1 = 100, line = list(dash = "dot",
                                                    color = "gray")))
        )
    })

    output$compare_summary <- shiny::renderUI({
      a <- primary_df()
      b <- compare_df()
      if (is.null(a) || is.null(b)) {
        return(shiny::p(shiny::em("Select a comparison panel in the sidebar.")))
      }
      ga <- a$gene; gb <- b$gene
      both <- intersect(ga, gb)
      a_only <- setdiff(ga, gb); b_only <- setdiff(gb, ga)
      shiny::tagList(
        shiny::tags$table(
          class = "table table-sm",
          shiny::tags$thead(shiny::tags$tr(
            shiny::tags$th("Set"), shiny::tags$th("Genes"))),
          shiny::tags$tbody(
            shiny::tags$tr(shiny::tags$td(input$panel,
                                          " only"),
                           shiny::tags$td(length(a_only))),
            shiny::tags$tr(shiny::tags$td("Both"),
                           shiny::tags$td(length(both))),
            shiny::tags$tr(shiny::tags$td(input$compare,
                                          " only"),
                           shiny::tags$td(length(b_only))),
            shiny::tags$tr(shiny::tags$td(shiny::strong("Union")),
                           shiny::tags$td(shiny::strong(length(union(ga, gb))))))
        ),
        shiny::p(shiny::strong("Shared genes: "),
                 if (length(both) == 0) "(none)"
                 else paste(head(sort(both), 60), collapse = ", "),
                 if (length(both) > 60) shiny::span(
                   shiny::em(sprintf(" ... and %d more", length(both) - 60))))
      )
    })
  })
}
