#' Launch the Xenium Panel Explorer Shiny app.
#'
#' Returns a `shiny.appobj` that callers pass to `shiny::runApp` (or print).
#' The navbar wires every tab module declared in §5 of CLAUDE.md; in M1 each
#' module renders a "coming in M{n}" placeholder.
#'
#' @export
xenium_panel_app <- function() {
  ui <- bslib::page_navbar(
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
    overview_server("overview")
    panel_browser_server("panel_browser")
    load_xenium_server("load_xenium")
    panel_compare_server("panel_compare")
    cluster_server("cluster")
    subcluster_server("subcluster")
    marker_server("marker")
    clustree_server("clustree")
    export_server("export")
  }

  shiny::shinyApp(ui, server)
}
