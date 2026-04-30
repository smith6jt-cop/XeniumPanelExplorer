#' Cluster module — Seurat pipeline UI + resolution sweep.
#' M1 stub; populated in M5 (CLAUDE.md §5 tab 5, §6).

cluster_ui <- function(id) {
  ns <- shiny::NS(id)
  placeholder_card("Cluster", app_milestones$cluster)
}

cluster_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    invisible(NULL)
  })
}
