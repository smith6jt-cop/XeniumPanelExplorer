#' Project-wide paths and options.
#'
#' Read at app start; downstream modules pull paths from `app_paths`.

app_paths <- list(
  panel_audit = "data/panel_audit",
  cache       = "cache"
)

app_milestones <- list(
  overview       = "M2",
  panel_browser  = "M2",
  load_xenium    = "M3",
  panel_compare  = "M4",
  cluster        = "M5",
  clustree       = "M6",
  subcluster     = "M7",
  marker         = "M8",
  export         = "M9"
)

#' Placeholder card used by every module before its milestone lands.
placeholder_card <- function(title, milestone) {
  bslib::card(
    bslib::card_header(title),
    bslib::card_body(
      shiny::p(shiny::strong(title), " — coming in ", milestone, "."),
      shiny::p("This is an M1 skeleton; the module's controls and outputs ",
               "are added in the milestone above per CLAUDE.md §10.")
    )
  )
}
