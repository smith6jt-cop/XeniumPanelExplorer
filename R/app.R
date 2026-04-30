#' Launch the Xenium Panel Explorer Shiny app.
#'
#' Returns a `shiny.appobj` that callers pass to `shiny::runApp` (or print).
#' The navbar wires every tab module declared in §5 of CLAUDE.md; M2 lights
#' up Overview and Panel Browser, the rest remain placeholder cards.
#'
#' @export
xenium_panel_app <- function() {
  ui <- bslib::page_navbar(
    id    = "main_nav",
    title = "Xenium Panel Explorer",
    theme = bslib::bs_theme(version = 5, preset = "shiny"),
    bslib::nav_panel("Overview",            overview_ui("overview")),
    bslib::nav_panel("Panel Browser",       panel_browser_ui("panel_browser")),
    bslib::nav_panel("Load Xenium",         load_xenium_ui("load_xenium")),
    bslib::nav_panel("Panel-vs-Data",       panel_compare_ui("panel_compare")),
    bslib::nav_panel("Cluster",             cluster_ui("cluster")),
    bslib::nav_panel("Subcluster",          subcluster_ui("subcluster")),
    bslib::nav_panel("Markers",             marker_ui("marker")),
    bslib::nav_panel("Clustree",            clustree_ui("clustree")),
    bslib::nav_panel("Export",              export_ui("export"))
  )

  server <- function(input, output, session) {
    # App-wide reactive state. `selected_subpanel` is the canonical key
    # (filename stem), e.g. "01_pancreas_endocrine". `nav_target` is the
    # `value` of the nav_panel to switch to.
    app_state <- shiny::reactiveValues(
      selected_subpanel = NULL,
      nav_target        = NULL,
      xen               = NULL,
      xen_path          = NULL,
      xen_clustered     = NULL,
      cluster_error     = NULL,
      cluster_jump_res  = NULL,
      compare_min_det   = 0,
      compare_topn      = 10,
      cluster_stack     = list(),
      subcluster_error  = NULL,
      markers_error     = NULL
    )

    # Whenever a fresh root run lands in xen_clustered, reset the
    # subcluster stack so it begins again at the new root.
    shiny::observeEvent(app_state$xen_clustered, {
      x <- app_state$xen_clustered
      if (is.null(x)) {
        app_state$cluster_stack <- list()
        return()
      }
      app_state$cluster_stack <- list(list(
        obj            = x,
        label          = "root",
        parent_res     = NA_character_,
        parent_cluster = NA_character_,
        opts           = NULL
      ))
    }, ignoreNULL = FALSE)

    # Loaded once at session start. Wrap in a reactive so future M-x
    # modules can re-trigger a reload if the user adds files at runtime.
    panels <- shiny::reactive({
      load_panels()
    })

    overview_server("overview",          panels, app_state)
    panel_browser_server("panel_browser", panels, app_state)
    load_xenium_server("load_xenium",    panels, app_state)
    panel_compare_server("panel_compare", panels, app_state)
    cluster_server("cluster", panels, app_state)
    subcluster_server("subcluster", panels, app_state)
    marker_server("marker", panels, app_state)
    clustree_server("clustree", panels, app_state)
    export_server("export")

    # Cross-tab routing: when a module sets app_state$nav_target, switch
    # the navbar to that panel.
    shiny::observeEvent(app_state$nav_target, {
      target <- app_state$nav_target
      if (is.null(target) || !nzchar(target)) return()
      bslib::nav_select(id = "main_nav", selected = target)
      app_state$nav_target <- NULL
    }, ignoreNULL = TRUE)
  }

  shiny::shinyApp(ui, server)
}
