#' Subcluster module — restrict cells to a chosen cluster and rerun.
#' M1 stub; populated in M7 (CLAUDE.md §5 tab 6).

subcluster_ui <- function(id) {
  ns <- shiny::NS(id)
  placeholder_card("Subcluster", app_milestones$subcluster)
}

subcluster_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    invisible(NULL)
  })
}
