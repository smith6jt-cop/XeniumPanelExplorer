test_that("every CSV in data/panel_audit/ parses with the expected columns", {
  audit <- file.path(rprojroot::find_root(rprojroot::has_file("DESCRIPTION")),
                     "data", "panel_audit")
  skip_if_not(dir.exists(audit), "panel_audit/ not present in this checkout")

  panels <- load_panels(audit)

  # summary
  expect_setequal(
    names(panels$summary),
    c("subpanel", "n_genes", "description", "pct_of_5K_kept_pool")
  )
  expect_gt(nrow(panels$summary), 50)

  # subpanels — every CSV resolves and has a `gene` column with > 0 rows
  expect_gt(length(panels$subpanels), 0)
  for (key in names(panels$subpanels)) {
    df <- panels$subpanels[[key]]
    expect_true("gene" %in% names(df), info = key)
    expect_gt(nrow(df), 0L)
  }

  # canonical 15-col schema is present on the curated subpanels (01-49)
  canonical_cols <- c("gene", "category", "rationale", "single_gene_panel_note",
                      "exclude_recommended", "detection_pct_0041323",
                      "detection_pct_0041326", "n_cells_0041323",
                      "n_cells_0041326", "log2_detection_ratio_326_over_323",
                      "gene_id", "full_name", "location", "cell_type",
                      "cellchat_pathway")
  for (key in grep("^(0[1-9]|[1-4][0-9])_", names(panels$subpanels),
                   value = TRUE)) {
    expect_true(all(canonical_cols %in% names(panels$subpanels[[key]])),
                info = key)
  }

  # ancillaries
  expect_equal(nrow(panels$xenium5k), 4992L)
  expect_equal(nrow(panels$excluded), 106L)
  expect_equal(nrow(panels$custom),   100L)

  # hIO files — should be 6 of them
  expect_setequal(
    names(panels$hIO),
    c("hIO_genes_vs_5K_status",
      "hIO_genes_unique_vs_5K",
      "hIO_genes_gained_vs_current_panel",
      "hIO_vs_5K_subpanel_coverage",
      "hIO_vs_5K_immune_lost_high_specificity",
      "hIO_vs_5K_immune_losses_detailed")
  )
  for (key in names(panels$hIO)) {
    expect_gt(nrow(panels$hIO[[key]]), 0L)
  }

  # subpanel union ⊂ xenium5k_in_audit (5K-only after the v2 correction)
  all_genes <- unlist(lapply(panels$subpanels, function(df) df$gene))
  expect_true(all(all_genes %in% panels$xenium5k$gene))

  # No custom-100 contamination
  expect_length(intersect(unique(all_genes), panels$custom$gene), 0L)
})

test_that("resolve_subpanel_key maps long summary names to file stems", {
  audit <- file.path(rprojroot::find_root(rprojroot::has_file("DESCRIPTION")),
                     "data", "panel_audit")
  skip_if_not(dir.exists(audit))
  panels <- load_panels(audit)

  expect_equal(
    resolve_subpanel_key("99d_truly_unannotated_subset_of_99c", panels),
    "99d_truly_unannotated"
  )
  expect_equal(
    resolve_subpanel_key("01_pancreas_endocrine", panels),
    "01_pancreas_endocrine"
  )
  expect_true(is.na(resolve_subpanel_key("not_a_real_subpanel", panels)))
})
