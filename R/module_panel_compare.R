#' Panel-vs-Data Compare module — coverage and detection for each subpanel.
#' M1 stub; populated in M4 (CLAUDE.md §5 tab 4).

panel_compare_ui <- function(id) {
  ns <- shiny::NS(id)
  placeholder_card("Panel-vs-Data Compare", app_milestones$panel_compare)
}

panel_compare_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    invisible(NULL)
  })
}
