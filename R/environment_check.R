#' Verify the R environment matches what the app needs.
#'
#' At session start the app calls this once and surfaces any issues
#' both in the terminal (`message()`) and in the Overview tab (a warning
#' card driven off `app_state$env_warnings`). It does not abort: the
#' intent is to make a misconfigured host obvious rather than to gate
#' use by users running on a near-miss configuration.
#'
#' What it checks:
#' \itemize{
#'   \item R version >= 4.4 (CLAUDE.md §3 minimum).
#'   \item Every required R package in the Imports list can be loaded.
#'   \item `data/panel_audit/` exists and contains
#'         `subpanel_summary_v2.csv` (the only file the app refuses
#'         to start without).
#'   \item Optional probes (warnings only): `chromote::find_chrome()`
#'         resolves a Chrome binary (needed by the shinytest2
#'         end-to-end test, never by the running app).
#' }
#'
#' @param required character vector of R packages to require.
#' @param min_r_version package_version() comparable string; default 4.4.
#' @return a list with two character vectors: `errors` (block-level
#'         problems, currently always empty — the app keeps starting),
#'         and `warnings` (everything else).
check_environment <- function(
  required = c("shiny", "bslib", "DT", "plotly", "data.table", "ggplot2",
               "Seurat", "SeuratObject", "Matrix", "qs2", "arrow",
               "rhdf5", "shinyFiles", "waiter", "harmony", "clustree",
               "aricode", "presto", "scales", "ggrastr", "fs", "rlang",
               "viridisLite", "htmltools", "shinycssloaders",
               "shinyWidgets"),
  min_r_version = "4.4.0"
) {
  errors   <- character()
  warnings <- character()

  if (utils::compareVersion(as.character(getRversion()),
                             min_r_version) < 0L) {
    warnings <- c(warnings, sprintf(
      "R %s detected; CLAUDE.md §3 pins R >= %s. Some packages may not load cleanly.",
      getRversion(), min_r_version))
  }

  missing_pkgs <- required[!vapply(required, requireNamespace,
                                    logical(1), quietly = TRUE)]
  if (length(missing_pkgs)) {
    warnings <- c(warnings, sprintf(
      "Missing R packages: %s. Run `renv::restore()` from the project root.",
      paste(missing_pkgs, collapse = ", ")))
  }

  audit <- file.path(app_paths$panel_audit, "subpanel_summary_v2.csv")
  if (!file.exists(audit)) {
    warnings <- c(warnings, sprintf(
      "%s not found. The Overview / Panel Browser tabs will be empty until it's restored.",
      audit))
  }

  if (requireNamespace("chromote", quietly = TRUE)) {
    chrome <- tryCatch(chromote::find_chrome(), error = function(e) "")
    if (!nzchar(chrome %||% "")) {
      warnings <- c(warnings,
        "chromote couldn't find a Chrome binary; the shinytest2 end-to-end test will be skipped.")
    }
  }

  list(errors = errors, warnings = warnings)
}

#' Print [check_environment()]'s result to the terminal.
#'
#' Called once during app construction so a user launching the app from
#' the command line sees the same surface as the Overview-tab card.
print_environment_check <- function(env = check_environment()) {
  if (!length(env$errors) && !length(env$warnings)) {
    message("Xenium Panel Explorer environment check: OK")
    return(invisible(env))
  }
  if (length(env$errors)) {
    message("Xenium Panel Explorer environment errors:")
    for (e in env$errors) message("  - ", e)
  }
  if (length(env$warnings)) {
    message("Xenium Panel Explorer environment warnings:")
    for (w in env$warnings) message("  - ", w)
  }
  invisible(env)
}
