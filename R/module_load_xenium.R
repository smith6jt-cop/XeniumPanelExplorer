#' Load Xenium module — directory / .rds / .h5ad chooser + cache via qs2.
#' M1 stub; populated in M3 (CLAUDE.md §5 tab 3).

load_xenium_ui <- function(id) {
  ns <- shiny::NS(id)
  placeholder_card("Load Xenium", app_milestones$load_xenium)
}

load_xenium_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    invisible(NULL)
  })
}
