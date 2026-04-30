# Xenium Panel Explorer

Interactive Shiny app for exploring 49 curated subpanels of the
**10x Genomics Xenium Prime 5K Human Pan Tissue and Pathways** panel
(plus a 100-gene custom T1D-GWAS add-on), and for re-clustering
user-loaded Xenium runs against any chosen subpanel with full control
of the clustering / sub-clustering pipeline and `clustree` for
resolution-stability inspection.

The app is built for a single-user research workflow on a workstation or
on HiPerGator. There is no authentication or multi-user state. See
[`CLAUDE.md`](CLAUDE.md) for the full build spec.

## Tabs

| Tab | What it does |
|---|---|
| **Overview** | Audit summary; click a row to drill into the Panel Browser. |
| **Panel Browser** | Subpanel gene tables, detection scatter, 2-set comparison. |
| **Load Xenium** | Ingest a Xenium output bundle, a saved Seurat (`.rds`/`.qs2`), or paste a path. Caches via `qs2`. |
| **Panel-vs-Data** | Coverage / detection of every subpanel against the loaded data, with a top-N heatmap. |
| **Cluster** | The core analytical tab. Runs `run_cluster_pipeline()` end-to-end (normalize → scale → PCA → optional Harmony → UMAP → resolution sweep). |
| **Subcluster** | Stack-based drill-down: pick a parent cluster, recluster on a (possibly different) subpanel. |
| **Markers** | `presto::wilcoxauc` marker tables, ranked AUC bar, DotPlot, mean-expression heatmap, FeaturePlot panel (UMAP + spatial). |
| **Clustree** | Resolution tree, UMAP overlay, stability summary (ARI / NMI / fraction-changed). "Use this resolution" hands off to the Cluster tab. |
| **Export** | Download the Seurat object (`.qs2`), cluster assignments (CSV), all marker tables (CSV), and a self-contained HTML session report. |

## Repo layout

```
xenium-panel-app/
├── app.R                      # `pkgload::load_all(".")` + `xenium_panel_app()`
├── R/                         # one Shiny module per tab + pure helpers
├── data/panel_audit/          # 49 subpanel CSVs + summary + ancillary tables
├── tests/testthat/            # unit + smoke tests; helper-test-data.R fixtures
├── cache/                     # qs2 cache (gitignored)
├── DESCRIPTION / NAMESPACE    # package layout (used for `pkgload::load_all`)
├── renv.lock / renv/          # reproducible R environment
└── README.md / CLAUDE.md      # this file + the build spec
```

## Local install (Ubuntu 22.04 / 24.04)

System deps used during install — most R packages will pull source
builds if no PPM binary is available:

```bash
sudo apt-get install -y \
  build-essential cmake gfortran pkg-config \
  libcurl4-openssl-dev libssl-dev libxml2-dev \
  libhdf5-dev hdf5-tools \
  libfontconfig1-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
  libcairo2-dev libxt-dev libharfbuzz-dev libfribidi-dev \
  libgit2-dev libuv1-dev pandoc
```

R 4.4 or newer. Then from the project root:

```r
install.packages("renv")
renv::restore()                   # pulls every package pinned in renv.lock
```

If you don't have `libuv1-dev` on the host, set `USE_BUNDLED_LIBUV=1`
before `renv::restore` so `fs` builds with its bundled libuv.

`presto` is installed from GitHub (`immunogenomics/presto`); `renv`
records that source in the lockfile.

## Run locally

From the project root:

```bash
R -e 'shiny::runApp("app.R", launch.browser = TRUE)'
```

Or in an interactive R session:

```r
pkgload::load_all(".")
shiny::runApp(xenium_panel_app(), launch.browser = TRUE)
```

`app.R` is the canonical entry point — `pkgload::load_all(".")` followed
by `xenium_panel_app()`.

## Run on HiPerGator

Per the build spec (CLAUDE.md §12):

```bash
module load R/4.4 hdf5/1.14
cd /path/to/XeniumPanelExplorer
R -e 'shiny::runApp("app.R", port = 4321, host = "127.0.0.1", launch.browser = FALSE)'
```

Tunnel the port to your laptop (VS Code remote / SSH `-L 4321:127.0.0.1:4321`).

Datasets larger than 1 M cells: avoid `SCTransform` — the app's pipeline
already gates that option above 200 k cells and falls back to
`LogNormalize` with a warning. For larger workflows the user has separate
GPU tooling (RAPIDS); this app is intentionally CPU-only.

## Tests

```r
devtools::test()
```

Most tests run on a synthetic 800-cell × 500-gene fixture built in
`tests/testthat/helper-test-data.R` from real audit gene names. The
shinytest2 end-to-end smoke test is gated on `chromote` having a
detectable Chrome binary; it is skipped on hosts without Chrome.

## Known environment notes

- This codebase was developed on a host where `/usr/local/lib/R/site-library`
  contained packages built against an older R series. Compilation against
  R 4.6 sometimes failed because a transitive package's source build
  preferred the stale system include path. The fix used during
  development was `install.packages(c(...), lib = .libPaths()[1])` from
  the project root — that forces fresh builds into the renv project
  library so the stale system copies are bypassed at compile time.
- `pandoc` is **not** required. The Export tab's session report is
  built with `htmltools::save_html` directly; there is no rmarkdown
  / quarto / commonmark dependency on the render path.

## Out of scope (per CLAUDE.md §14)

CellChat / NicheNet, 3D spatial visualisation, multi-dataset integration
beyond Harmony on `orig.ident`, `Azimuth` reference mapping, the
Stellaromics / Pyxa platform, authentication / multi-user state.
