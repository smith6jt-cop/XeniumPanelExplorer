#' Panel Browser module — selectizeInput across the 49 subpanels + custom + 5K.
#' M1 stub; populated in M2 (CLAUDE.md §5 tab 2).

panel_browser_ui <- function(id) {
  ns <- shiny::NS(id)
  placeholder_card("Panel Browser", app_milestones$panel_browser)
}

panel_browser_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    invisible(NULL)
  })
}
