#' Marker module — presto-driven Wilcoxon, dot/feature/heatmap plots.
#' M1 stub; populated in M8 (CLAUDE.md §5 tab 7).

marker_ui <- function(id) {
  ns <- shiny::NS(id)
  placeholder_card("Markers", app_milestones$marker)
}

marker_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    invisible(NULL)
  })
}
