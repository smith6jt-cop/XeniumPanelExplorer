#' Clustree module — tree, overlay, stability summary.
#' M1 stub; populated in M6 (CLAUDE.md §5 tab 8, §7).

clustree_ui <- function(id) {
  ns <- shiny::NS(id)
  placeholder_card("Clustree", app_milestones$clustree)
}

clustree_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    invisible(NULL)
  })
}
