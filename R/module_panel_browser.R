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
               "select two panels to see set-overlap stats below the table."),
      bslib::accordion(
        open = FALSE,
        bslib::accordion_panel(
          "Custom panel source",
          shiny::p(shiny::em(
            "Upload a CSV to replace the T1D-GWAS custom panel for this ",
            "session. A `gene` column is required; missing canonical ",
            "columns are filled in from the original T1D-GWAS panel and ",
            "the xenium5k reference for any matching genes.")),
          shiny::fileInput(ns("custom_upload"),
                           "Replace custom panel CSV",
                           accept = c(".csv", "text/csv")),
          shiny::actionButton(ns("custom_reset"),
                              "Reset to default",
                              class = "btn-sm btn-outline-secondary"),
          shiny::uiOutput(ns("custom_status"))
        )
      )
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

panel_browser_server <- function(id, panels, panels_default, app_state) {
  shiny::moduleServer(id, function(input, output, session) {

    # Handle a user upload of a replacement custom-panel CSV. Enrichment
    # always uses the on-disk defaults (panels_default()), not the
    # currently-active override, so re-uploads are idempotent.
    shiny::observeEvent(input$custom_upload, {
      f <- input$custom_upload
      if (is.null(f)) return()
      tryCatch({
        result <- upload_custom_panel(
          csv_path    = f$datapath,
          panels      = panels_default(),
          source_name = f$name
        )
        app_state$custom_panel_override <- result$df
        app_state$custom_panel_status   <- result
      }, error = function(e) {
        app_state$custom_panel_override <- NULL
        app_state$custom_panel_status   <- NULL
        shinyWidgets::sendSweetAlert(
          session = session,
          title   = "Custom panel upload failed",
          text    = conditionMessage(e),
          type    = "error",
          btn_labels = "OK"
        )
      })
    }, ignoreNULL = TRUE)

    shiny::observeEvent(input$custom_reset, {
      app_state$custom_panel_override <- NULL
      app_state$custom_panel_status   <- NULL
      # Clear the fileInput so re-uploading the same file re-fires.
      shiny::updateTextInput(session, "custom_upload", value = "")
    }, ignoreInit = TRUE)

    output$custom_status <- shiny::renderUI({
      st <- app_state$custom_panel_status
      if (is.null(st)) {
        n <- nrow(panels_default()$custom %||% data.frame())
        return(shiny::tags$p(shiny::tags$small(
          shiny::strong("Custom panel: "), "default ",
          sprintf("(%d genes)", n))))
      }
      shiny::tags$div(
        shiny::tags$p(shiny::tags$small(
          shiny::strong("Custom panel: "), "uploaded ",
          shiny::tags$code(st$source_name),
          sprintf(" (%d genes)", st$n_genes))),
        shiny::tags$ul(
          class = "small mb-0",
          shiny::tags$li(sprintf("%d enriched from T1D-GWAS",
                                 st$n_enriched_from_custom)),
          shiny::tags$li(sprintf("%d enriched from xenium5k",
                                 st$n_enriched_from_5k)),
          shiny::tags$li(sprintf("%d unmatched (no reference data)",
                                 st$n_unmatched))
        )
      )
    })

    # Values used for lookup in `get_panel_df()`. Stable across uploads.
    panel_choices <- shiny::reactive({
      p <- panels()
      c(
        sort(p$meta$subpanel_keys),
        "custom_T1D_GWAS_panel",
        "xenium5k_in_audit"
      )
    })

    # Display labels — when an override is active the custom-panel slot
    # shows the uploaded filename stem (matches every other UI surface).
    panel_choices_labeled <- shiny::reactive({
      vals <- panel_choices()
      labels <- vals
      st <- app_state$custom_panel_status
      if (!is.null(st)) {
        labels[vals == "custom_T1D_GWAS_panel"] <- custom_panel_label(st)
      }
      stats::setNames(vals, labels)
    })

    shiny::observe({
      ch <- panel_choices_labeled()
      cur_panel   <- shiny::isolate(input$panel)
      cur_compare <- shiny::isolate(input$compare)
      sel_panel <- if (!is.null(cur_panel) && cur_panel %in% ch) cur_panel
                   else unname(ch)[1]
      sel_compare <- if (!is.null(cur_compare) &&
                         (cur_compare %in% ch || cur_compare == "(none)"))
                       cur_compare else "(none)"
      shiny::updateSelectizeInput(session, "panel",
                                  choices = ch,
                                  server  = TRUE,
                                  selected = sel_panel)
      shiny::updateSelectizeInput(session, "compare",
                                  choices = c("(none)" = "(none)", ch),
                                  server  = TRUE,
                                  selected = sel_compare)
    })

    # Registered after the choices observer so it runs LAST in the flush
    # cycle — surfaces the just-uploaded panel in the dropdown without
    # being clobbered by the choices observer's selected-value default.
    shiny::observeEvent(app_state$custom_panel_status, {
      shiny::updateSelectizeInput(session, "panel",
                                  selected = "custom_T1D_GWAS_panel")
    }, ignoreNULL = TRUE, ignoreInit = TRUE)

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
      sprintf("%s — %d genes",
              panel_display_label(input$panel,
                                  app_state$custom_panel_status),
              nrow(df))
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

      # log10(1 + pct) so 0% is plottable; ticks at the original percent.
      df$lx <- log10(1 + df$detection_pct_0041323)
      df$ly <- log10(1 + df$detection_pct_0041326)
      tick_pct  <- c(0, 1, 3, 10, 30, 100)
      tick_vals <- log10(1 + tick_pct)
      tick_text <- as.character(tick_pct)
      ax_max    <- log10(101)

      has_ratio <- "log2_detection_ratio_326_over_323" %in% names(df) &&
                   any(is.finite(df$log2_detection_ratio_326_over_323))
      marker <- if (has_ratio) {
        r <- df$log2_detection_ratio_326_over_323
        # Robust symmetric limits: 95th-pct of |ratio|, floored at 2,
        # capped at 5 — stops one outlier from washing out the panel.
        q <- stats::quantile(abs(r), 0.95, na.rm = TRUE)
        cmax_q <- min(5, max(2, q))
        list(size = 6, color = r,
             cmin = -cmax_q, cmax = cmax_q, cmid = 0, cauto = FALSE,
             colorscale = "RdBu", reversescale = TRUE,
             colorbar = list(title = "log2 326/323"))
      } else {
        list(size = 6, color = "#1f77b4")
      }

      plotly::plot_ly(
        df,
        x = ~lx, y = ~ly,
        type = "scatter", mode = "markers",
        marker = marker,
        text = ~sprintf("%s<br>0041323: %.2f%%<br>0041326: %.2f%%",
                        gene, detection_pct_0041323, detection_pct_0041326),
        hoverinfo = "text"
      ) |>
        plotly::layout(
          xaxis = list(title    = "detection_pct_0041323",
                       tickvals = tick_vals, ticktext = tick_text,
                       range    = c(0, ax_max), zeroline = FALSE),
          yaxis = list(title    = "detection_pct_0041326",
                       tickvals = tick_vals, ticktext = tick_text,
                       range    = c(0, ax_max), zeroline = FALSE,
                       scaleanchor = "x", scaleratio = 1),
          shapes = list(list(type = "line",
                             x0 = 0, y0 = 0, x1 = ax_max, y1 = ax_max,
                             line = list(dash = "dot", color = "gray")))
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
      st <- app_state$custom_panel_status
      lbl_a <- panel_display_label(input$panel,   st)
      lbl_b <- panel_display_label(input$compare, st)
      shiny::tagList(
        shiny::tags$table(
          class = "table table-sm",
          shiny::tags$thead(shiny::tags$tr(
            shiny::tags$th("Set"), shiny::tags$th("Genes"))),
          shiny::tags$tbody(
            shiny::tags$tr(shiny::tags$td(lbl_a, " only"),
                           shiny::tags$td(length(a_only))),
            shiny::tags$tr(shiny::tags$td("Both"),
                           shiny::tags$td(length(both))),
            shiny::tags$tr(shiny::tags$td(lbl_b, " only"),
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
