audit_dir <- function() {
  file.path(rprojroot::find_root(rprojroot::has_file("DESCRIPTION")),
            "data", "panel_audit")
}

test_that("custom_panel_canonical_cols returns the 10-column schema", {
  cols <- custom_panel_canonical_cols()
  expect_length(cols, 10L)
  expect_true("gene" %in% cols)
  expect_true("detection_pct_0041323" %in% cols)
  expect_true("log2_detection_ratio_326_over_323" %in% cols)
})

test_that("upload_custom_panel enriches a gene-only CSV from references", {
  skip_if_not(dir.exists(audit_dir()), "panel_audit/ missing")
  panels <- load_panels(audit_dir())

  # Pick: one gene known to be in panels$custom (T1D-GWAS), one in
  # xenium5k only, one made-up unmatched gene.
  g_custom <- panels$custom$gene[1]
  g_5k     <- setdiff(panels$xenium5k$gene, panels$custom$gene)[1]
  g_none   <- "DEFINITELY_NOT_A_REAL_GENE_XYZZY"

  csv <- tempfile(fileext = ".csv")
  on.exit(unlink(csv), add = TRUE)
  utils::write.csv(
    data.frame(gene = c(g_custom, g_5k, g_none),
               stringsAsFactors = FALSE),
    csv, row.names = FALSE
  )

  res <- upload_custom_panel(csv, panels)
  expect_equal(res$n_genes, 3L)
  expect_equal(res$source_name, basename(csv))
  expect_equal(res$n_enriched_from_custom, 1L)
  expect_equal(res$n_enriched_from_5k, 1L)
  expect_equal(res$n_unmatched, 1L)

  # All canonical columns present, in canonical order at the front.
  expect_equal(head(names(res$df), 10L), custom_panel_canonical_cols())

  # Genes from references have detection columns filled.
  row_custom <- res$df[res$df$gene == g_custom, ]
  row_5k     <- res$df[res$df$gene == g_5k, ]
  row_none   <- res$df[res$df$gene == g_none, ]
  expect_false(is.na(row_custom$detection_pct_0041323))
  expect_false(is.na(row_5k$detection_pct_0041323))
  expect_true(is.na(row_none$detection_pct_0041323))
})

test_that("upload_custom_panel preserves user-supplied non-NA values", {
  skip_if_not(dir.exists(audit_dir()), "panel_audit/ missing")
  panels <- load_panels(audit_dir())

  # Use a gene that exists in the reference custom panel; supply a
  # category value that differs from the reference and confirm it is
  # NOT overwritten.
  g <- panels$custom$gene[1]
  user_category <- "USER_OVERRIDE_CATEGORY"

  csv <- tempfile(fileext = ".csv")
  on.exit(unlink(csv), add = TRUE)
  utils::write.csv(
    data.frame(gene = g, category = user_category,
               stringsAsFactors = FALSE),
    csv, row.names = FALSE
  )

  res <- upload_custom_panel(csv, panels)
  expect_equal(res$df$category[1], user_category)
  # Detection columns still filled from the reference.
  expect_false(is.na(res$df$detection_pct_0041323[1]))
})

test_that("upload_custom_panel accepts case-insensitive gene column", {
  skip_if_not(dir.exists(audit_dir()), "panel_audit/ missing")
  panels <- load_panels(audit_dir())

  csv <- tempfile(fileext = ".csv")
  on.exit(unlink(csv), add = TRUE)
  utils::write.csv(
    data.frame(Gene = panels$custom$gene[1:3],
               stringsAsFactors = FALSE),
    csv, row.names = FALSE
  )

  res <- upload_custom_panel(csv, panels)
  expect_true("gene" %in% names(res$df))
  expect_equal(res$n_genes, 3L)
})

test_that("upload_custom_panel deduplicates and drops empty gene rows", {
  skip_if_not(dir.exists(audit_dir()), "panel_audit/ missing")
  panels <- load_panels(audit_dir())

  g <- panels$custom$gene[1]
  csv <- tempfile(fileext = ".csv")
  on.exit(unlink(csv), add = TRUE)
  # Hand-written so fread doesn't warn about quoting quirks.
  writeLines(
    c("gene,extra",
      paste0(g, ",1"),
      paste0(g, ",2"),
      ",3",
      " ,4"),
    csv
  )

  res <- suppressWarnings(upload_custom_panel(csv, panels))
  expect_equal(res$n_genes, 1L)
  expect_equal(res$df$gene[1], g)
})

test_that("upload_custom_panel errors when `gene` column is missing", {
  skip_if_not(dir.exists(audit_dir()), "panel_audit/ missing")
  panels <- load_panels(audit_dir())

  csv <- tempfile(fileext = ".csv")
  on.exit(unlink(csv), add = TRUE)
  utils::write.csv(
    data.frame(symbol = c("AAA", "BBB"), stringsAsFactors = FALSE),
    csv, row.names = FALSE
  )

  expect_error(upload_custom_panel(csv, panels),
               regexp = "gene", ignore.case = TRUE)
})

test_that("upload_custom_panel errors on a file with no valid gene rows", {
  skip_if_not(dir.exists(audit_dir()), "panel_audit/ missing")
  panels <- load_panels(audit_dir())

  csv <- tempfile(fileext = ".csv")
  on.exit(unlink(csv), add = TRUE)
  # Write the CSV by hand so we get exactly: a header + two NA-gene rows.
  writeLines(c("gene,extra", "NA,1", "NA,2"), csv)

  expect_error(
    suppressWarnings(upload_custom_panel(csv, panels)),
    regexp = "empty|valid|gene", ignore.case = TRUE
  )
})

test_that("custom_panel_label returns stem when status set, default otherwise", {
  expect_equal(custom_panel_label(NULL), "custom_T1D_GWAS_panel")
  expect_equal(custom_panel_label(list()), "custom_T1D_GWAS_panel")

  st <- list(source_name = "my_t1d_v2.csv")
  expect_equal(custom_panel_label(st), "my_t1d_v2")

  # Source name without an extension still works.
  expect_equal(custom_panel_label(list(source_name = "panel_alt")),
               "panel_alt")

  # Custom default override is respected when status is empty.
  expect_equal(custom_panel_label(NULL, default = "fallback"),
               "fallback")
})

test_that("panel_display_label rewrites only the custom key", {
  st <- list(source_name = "my_t1d_v2.csv")
  expect_equal(panel_display_label("custom_T1D_GWAS_panel", st),
               "my_t1d_v2")
  expect_equal(panel_display_label("custom_T1D_GWAS_panel", NULL),
               "custom_T1D_GWAS_panel")
  expect_equal(panel_display_label("subpanel_01_pancreas_endocrine", st),
               "subpanel_01_pancreas_endocrine")
  expect_equal(panel_display_label("xenium5k_in_audit", st),
               "xenium5k_in_audit")
})
