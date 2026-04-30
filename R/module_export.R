#' Export module — Seurat object, cluster CSVs, static report.
#' M1 stub; populated in M9 (CLAUDE.md §5 tab 9).

export_ui <- function(id) {
  ns <- shiny::NS(id)
  placeholder_card("Export", app_milestones$export)
}

export_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    invisible(NULL)
  })
}
