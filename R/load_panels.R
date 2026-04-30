#' Read every CSV in `data/panel_audit/` into a structured list.
#'
#' The audit directory holds three groups of files:
#'   * 49 per-subpanel CSVs (`subpanel_01_*.csv` ... `subpanel_49_*.csv`),
#'     plus the `99` re-annotated and `99c` / `99d` residuals;
#'   * `subpanel_summary_v2.csv` indexing 01-49 + 99c + 99d (the post-
#'     refinement system; 99 itself is not a row in the v2 summary because
#'     it was split across 21-49);
#'   * ancillary tables: `custom_T1D_GWAS_panel.csv`,
#'     `xenium5k_in_audit.csv`, `xenium5k_already_excluded.csv`, and the
#'     six `hIO_*.csv` files.
#'
#' Returned shape:
#' \describe{
#'   \item{summary}{data.frame from `subpanel_summary_v2.csv`.}
#'   \item{subpanels}{named list of data.frames, keyed by file stem
#'         (e.g. `"01_pancreas_endocrine"`, `"99d_truly_unannotated"`).}
#'   \item{custom}{custom 100-gene T1D-GWAS panel.}
#'   \item{xenium5k}{the 4,992 5K-shared genes.}
#'   \item{excluded}{the 106 already-excluded genes.}
#'   \item{hIO}{named list of the six `hIO_*` data.frames.}
#'   \item{meta}{`path`, `mtime`, vector of subpanel keys.}
#' }
#'
#' Reads use `data.table::fread`.
load_panels <- function(path = app_paths$panel_audit) {
  if (!dir.exists(path)) {
    stop("panel_audit directory not found: ", path)
  }

  read_csv <- function(p) {
    data.table::fread(p, na.strings = c("", "NA"), data.table = FALSE,
                      showProgress = FALSE)
  }

  files <- list.files(path, pattern = "\\.csv$", full.names = TRUE)
  names(files) <- basename(files)

  required <- "subpanel_summary_v2.csv"
  if (!required %in% names(files)) {
    stop("missing ", required, " in ", path)
  }

  summary_df <- read_csv(files[["subpanel_summary_v2.csv"]])

  subpanel_files <- files[grepl("^subpanel_[0-9]", names(files))]
  subpanel_keys  <- sub("^subpanel_", "", sub("\\.csv$", "", names(subpanel_files)))
  subpanels      <- stats::setNames(lapply(subpanel_files, read_csv), subpanel_keys)

  hIO_files <- files[grepl("^hIO_", names(files))]
  hIO_keys  <- sub("\\.csv$", "", names(hIO_files))
  hIO       <- stats::setNames(lapply(hIO_files, read_csv), hIO_keys)

  pick <- function(name) {
    if (name %in% names(files)) read_csv(files[[name]]) else NULL
  }

  list(
    summary   = summary_df,
    subpanels = subpanels,
    custom    = pick("custom_T1D_GWAS_panel.csv"),
    xenium5k  = pick("xenium5k_in_audit.csv"),
    excluded  = pick("xenium5k_already_excluded.csv"),
    hIO       = hIO,
    meta      = list(
      path           = normalizePath(path),
      mtime          = max(file.mtime(unname(files))),
      subpanel_keys  = sort(subpanel_keys)
    )
  )
}

#' Resolve a `subpanel` value from `summary_v2` to a `subpanels` list key.
#'
#' The summary's `subpanel` column uses the long name
#' (`99d_truly_unannotated_subset_of_99c`) whereas the files on disk use
#' the short stem (`99d_truly_unannotated`). Match by prefix.
resolve_subpanel_key <- function(summary_subpanel, panels) {
  keys <- panels$meta$subpanel_keys
  hit  <- keys[startsWith(summary_subpanel, keys) |
               startsWith(keys, summary_subpanel)]
  if (length(hit) == 1L) hit else NA_character_
}
