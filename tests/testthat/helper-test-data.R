# Synthetic Xenium-like fixtures used by every test that needs a Seurat
# object (M3 onward). Built once per testthat session in tempdir().
#
# Per CLAUDE.md §10: "Generate the synthetic test object inside
# tests/testthat/helper-test-data.R using the actual gene names from
# subpanel_summary_v2.csv (sample ~500 genes across subpanels) so
# panel-validation logic is exercised."

#' Resolve the absolute path to data/panel_audit/, regardless of cwd.
test_panel_audit_dir <- function() {
  file.path(rprojroot::find_root(rprojroot::has_file("DESCRIPTION")),
            "data", "panel_audit")
}

#' Sample ~500 unique gene names spanning multiple subpanels.
make_test_genes <- function(panels = NULL, n = 500L, seed = 1L) {
  if (is.null(panels)) panels <- load_panels(test_panel_audit_dir())
  set.seed(seed)
  pool <- unique(unlist(lapply(panels$subpanels, `[[`, "gene"),
                        use.names = FALSE))
  pool <- pool[!is.na(pool) & nzchar(pool)]
  sample(pool, min(n, length(pool)))
}

#' Build a synthetic Seurat object for testing.
#'
#' n_cells × n_genes Poisson counts; centroid coords on a 1000×1000 grid
#' jittered slightly. Genes are real audit names so panel_validate sees
#' realistic input.
make_test_seurat <- function(n_cells = 800L, n_genes = 500L, seed = 1L,
                              panels = NULL) {
  if (is.null(panels)) panels <- load_panels(test_panel_audit_dir())
  genes <- make_test_genes(panels, n = n_genes, seed = seed)
  set.seed(seed)
  # ~5% non-zero entries
  nnz <- as.integer(0.05 * length(genes) * n_cells)
  i <- sample.int(length(genes), nnz, replace = TRUE)
  j <- sample.int(n_cells, nnz, replace = TRUE)
  x <- stats::rpois(nnz, lambda = 3) + 1L
  M <- Matrix::sparseMatrix(
    i = i, j = j, x = x,
    dims = c(length(genes), n_cells),
    dimnames = list(genes, sprintf("cell_%05d", seq_len(n_cells)))
  )
  meta <- data.frame(
    cell_id    = colnames(M),
    x_centroid = stats::runif(n_cells, 0, 1000),
    y_centroid = stats::runif(n_cells, 0, 1000),
    transcript_counts = Matrix::colSums(M),
    stringsAsFactors = FALSE,
    row.names = colnames(M)
  )
  SeuratObject::CreateSeuratObject(
    counts    = M,
    assay     = "Xenium",
    meta.data = meta,
    project   = "synthetic_test"
  )
}

#' Save the synthetic Seurat object as a `.rds` and return the path.
make_test_rds <- function(dir = tempfile("xen_rds_"), ...) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  obj <- make_test_seurat(...)
  out <- file.path(dir, "synthetic_xenium.rds")
  saveRDS(obj, out)
  out
}

#' Write a synthetic Xenium output-bundle directory.
#'
#' Produces `cell_feature_matrix.h5` (10x layout) + `cells.parquet`
#' inside `dir`. Returns the directory path.
make_test_bundle <- function(dir = tempfile("xen_bundle_"), ...) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  obj <- make_test_seurat(...)

  counts <- SeuratObject::GetAssayData(obj, layer = "counts")
  features <- rownames(counts)
  barcodes <- colnames(counts)

  # 10x cell_feature_matrix.h5 expects CSC: indices = row indices, indptr
  # over columns. Matrix::sparseMatrix(repr="C") → dgCMatrix with @i (row
  # 0-based) and @p (column ptrs).
  csc <- methods::as(counts, "CsparseMatrix")
  h5  <- file.path(dir, "cell_feature_matrix.h5")
  if (file.exists(h5)) file.remove(h5)
  rhdf5::h5createFile(h5)
  rhdf5::h5createGroup(h5, "matrix")
  rhdf5::h5write(as.numeric(csc@x),       h5, "matrix/data")
  rhdf5::h5write(as.integer(csc@i),       h5, "matrix/indices")
  rhdf5::h5write(as.integer(csc@p),       h5, "matrix/indptr")
  rhdf5::h5write(as.integer(dim(csc)),    h5, "matrix/shape")
  rhdf5::h5write(as.character(barcodes),  h5, "matrix/barcodes")
  rhdf5::h5createGroup(h5, "matrix/features")
  rhdf5::h5write(as.character(features),  h5, "matrix/features/name")
  rhdf5::h5write(as.character(features),  h5, "matrix/features/id")
  rhdf5::h5closeAll()

  cells <- obj@meta.data
  cells$cell_id <- rownames(cells)
  arrow::write_parquet(cells, file.path(dir, "cells.parquet"))
  dir
}
