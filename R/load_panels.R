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

#' Short display label for the custom-panel slot.
#'
#' Returns the stem of the uploaded filename (basename, no extension) when
#' an override is active, otherwise the canonical key. Used at every UI
#' surface that prints the custom-panel name so the uploaded filename
#' propagates beyond the Panel Browser dropdown.
custom_panel_label <- function(status,
                               default = "custom_T1D_GWAS_panel") {
  if (is.null(status) || is.null(status$source_name)) return(default)
  tools::file_path_sans_ext(status$source_name)
}

#' Pass-through display-label mapper for any panel key.
#'
#' Only `custom_T1D_GWAS_panel` is rewritten (via [custom_panel_label()]);
#' every other key is returned as-is.
panel_display_label <- function(key, status) {
  if (identical(key, "custom_T1D_GWAS_panel")) {
    return(custom_panel_label(status))
  }
  key
}

#' Canonical 10-column schema of `custom_T1D_GWAS_panel.csv`.
custom_panel_canonical_cols <- function() {
  c("gene", "category", "rationale", "single_gene_panel_note",
    "exclude_recommended", "detection_pct_0041323",
    "detection_pct_0041326", "n_cells_0041323", "n_cells_0041326",
    "log2_detection_ratio_326_over_323")
}

#' Parse a user-uploaded CSV and enrich it to the canonical custom-panel
#' schema by filling missing columns from the original T1D-GWAS panel and
#' the xenium5k audit reference for any genes that overlap.
#'
#' @param csv_path Path to the uploaded CSV.
#' @param panels   The default panels list (from `load_panels()`). The
#'                 enrichment sources are `panels$custom` then
#'                 `panels$xenium5k`; user-supplied non-NA values are
#'                 never overwritten.
#' @param source_name Optional label (defaults to `basename(csv_path)`).
#' @return list(df, n_genes, n_enriched_from_custom, n_enriched_from_5k,
#'              n_unmatched, source_name)
upload_custom_panel <- function(csv_path, panels, source_name = NULL) {
  if (!file.exists(csv_path)) {
    stop("upload_custom_panel: file not found: ", csv_path)
  }
  if (is.null(source_name)) source_name <- basename(csv_path)

  df <- data.table::fread(csv_path, na.strings = c("", "NA"),
                          data.table = FALSE, showProgress = FALSE)
  if (nrow(df) == 0L || ncol(df) == 0L) {
    stop("Uploaded CSV is empty.")
  }

  # Normalise the gene column: accept any case (gene/Gene/GENE).
  gene_col <- grep("^gene$", names(df), ignore.case = TRUE, value = TRUE)
  if (length(gene_col) == 0L) {
    stop("Uploaded CSV must have a `gene` column (case-insensitive). ",
         "Found columns: ", paste(names(df), collapse = ", "))
  }
  if (gene_col[1] != "gene") names(df)[names(df) == gene_col[1]] <- "gene"

  df$gene <- trimws(as.character(df$gene))
  df <- df[!is.na(df$gene) & nzchar(df$gene), , drop = FALSE]
  df <- df[!duplicated(df$gene), , drop = FALSE]
  if (nrow(df) == 0L) {
    stop("Uploaded CSV has no valid (non-empty) gene rows.")
  }

  # Ensure the canonical columns exist (add as NA where missing). We keep
  # any extra user columns at the end.
  canon <- custom_panel_canonical_cols()
  for (col in canon) {
    if (!(col %in% names(df))) df[[col]] <- NA
  }
  # Re-order so canonical columns come first.
  extra <- setdiff(names(df), canon)
  df <- df[, c(canon, extra), drop = FALSE]

  # Enrichment sources: prefer the original T1D-GWAS panel (more
  # contextual to a custom-panel upload), fall back to xenium5k.
  fill_cols <- setdiff(canon, "gene")
  src_custom <- panels$custom
  src_5k     <- panels$xenium5k

  n_from_custom <- 0L
  n_from_5k     <- 0L
  n_unmatched   <- 0L

  for (i in seq_len(nrow(df))) {
    g <- df$gene[i]
    matched <- FALSE

    # 1) Original T1D-GWAS panel.
    if (!is.null(src_custom) && nrow(src_custom) > 0L) {
      hit <- which(src_custom$gene == g)
      if (length(hit) >= 1L) {
        filled_here <- FALSE
        for (col in fill_cols) {
          if (!(col %in% names(src_custom))) next
          if (is.na(df[[col]][i]) && !is.na(src_custom[[col]][hit[1]])) {
            df[[col]][i] <- src_custom[[col]][hit[1]]
            filled_here <- TRUE
          }
        }
        if (filled_here) n_from_custom <- n_from_custom + 1L
        matched <- TRUE
      }
    }

    # 2) xenium5k_in_audit (only fills cells still NA).
    if (!is.null(src_5k) && nrow(src_5k) > 0L) {
      hit <- which(src_5k$gene == g)
      if (length(hit) >= 1L) {
        filled_here <- FALSE
        for (col in fill_cols) {
          if (!(col %in% names(src_5k))) next
          if (is.na(df[[col]][i]) && !is.na(src_5k[[col]][hit[1]])) {
            df[[col]][i] <- src_5k[[col]][hit[1]]
            filled_here <- TRUE
          }
        }
        if (filled_here && !matched) n_from_5k <- n_from_5k + 1L
        matched <- TRUE
      }
    }

    if (!matched) n_unmatched <- n_unmatched + 1L
  }

  list(
    df                     = df,
    n_genes                = nrow(df),
    n_enriched_from_custom = n_from_custom,
    n_enriched_from_5k     = n_from_5k,
    n_unmatched            = n_unmatched,
    source_name            = source_name
  )
}
