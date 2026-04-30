#' Overview module — landing page summarising the panel audit.
#' M1 stub; populated in M2 (CLAUDE.md §5 tab 1).

overview_ui <- function(id) {
  ns <- shiny::NS(id)
  placeholder_card("Overview", app_milestones$overview)
}

overview_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    invisible(NULL)
  })
}
