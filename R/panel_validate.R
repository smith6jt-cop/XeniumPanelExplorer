#' Compare a loaded dataset's gene set against the panel audit reference.
#'
#' Reference set = `xenium5k_in_audit$gene` ∪ `custom_T1D_GWAS_panel$gene`
#' (4,992 + 100 = 5,092 unique). The validation never blocks analysis;
#' it returns a structured report the UI can render.
#'
#' @param genes character vector of gene symbols present in the dataset.
#' @param panels output of [load_panels()].
#' @return named list:
#'   * `n_data`      — genes in the dataset
#'   * `n_reference` — genes in the reference union
#'   * `intersection`, `missing_from_data`, `extra_in_data` — gene vectors
#'   * `n_*` — corresponding counts
#'   * `pct_reference_covered` — `intersection / n_reference`
#'   * `partial`    — TRUE if not a complete cover
panel_validate <- function(genes, panels) {
  if (!length(genes)) {
    stop("`genes` is empty; nothing to validate.")
  }
  data_g <- unique(as.character(genes))
  ref_g  <- unique(c(panels$xenium5k$gene, panels$custom$gene))

  inter <- intersect(data_g, ref_g)
  miss  <- setdiff(ref_g, data_g)
  extra <- setdiff(data_g, ref_g)

  list(
    n_data                 = length(data_g),
    n_reference            = length(ref_g),
    intersection           = inter,
    missing_from_data      = miss,
    extra_in_data          = extra,
    n_intersection         = length(inter),
    n_missing_from_data    = length(miss),
    n_extra_in_data        = length(extra),
    pct_reference_covered  = if (length(ref_g)) length(inter) / length(ref_g) else NA_real_,
    partial                = length(miss) > 0L || length(extra) > 0L
  )
}

#' Render a one-paragraph human-readable summary of [panel_validate()].
panel_validate_summary <- function(rep) {
  glue_prefix <- function(...) paste0(...)
  msg <- sprintf(
    paste0(
      "Loaded dataset: %d genes. Reference (xenium5k_in_audit ∪ custom-100): %d genes. ",
      "Intersection: %d (%.1f%% of reference). Missing from data: %d. ",
      "Extra in data (not in reference): %d."),
    rep$n_data, rep$n_reference, rep$n_intersection,
    100 * rep$pct_reference_covered,
    rep$n_missing_from_data, rep$n_extra_in_data
  )
  if (rep$partial) {
    msg <- paste0(msg,
                  " The match is partial — analysis is not blocked, but ",
                  "downstream subpanel selection will only score genes that ",
                  "are present in the loaded data.")
  }
  msg
}
