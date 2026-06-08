# Recommendations for the `Xenium_Analysis` phenotyper

These are recommendations for the **consumer** repo
(`smith6jt-cop/Xenium_Analysis`), which vendors these subpanels at a pinned
commit into `data/reference/subpanels/{pancreas,shared,thymus}/` and builds
broad-lineage masks via `scripts/tissue_markers/<tissue>.py::SUBPANEL_ALLOWLIST`.
That repo is out of scope to edit from here; the machine-readable source for
all of the below is `data/panel_roles.csv` + `data/panel_gene_roles.csv`.

## 1. Keep the allowlist identity-only — it already is
The current `SUBPANEL_ALLOWLIST`s map **only Tier-1 identity panels** to
lineages (11 files → 8 lineages for pancreas; 15 → 8 for thymus). This matches
`panel_roles.csv` `phenotyping_use == broad_mask` exactly. No lineage masks
should be added from Tier-3 (state/pathway) or residual panels.

## 2. Add a `STATE_PANELS` companion (score, don't cluster)
Tier-3 programs carry real biology but must be **scored separately**, never used
as a lineage axis. Build a sibling constant from `panel_roles.csv` where
`phenotyping_use == module_score` and apply via `sc.tl.score_genes` /
`AddModuleScore` — e.g. IFN-response (10), cytokine-signaling (09),
matrix-remodeling (14), proliferation (17), apoptosis (18), and the pathway
panels (21–49). This keeps inflamed/cycling/stressed cells from being
mis-assigned by the argmax masks.

## 3. Promote two identity genes that are currently only in non-mask panels
`AIRE` and `FEZF2` (medullary-TEC identity TFs) presently live in thymus
`11_positive_negative_selection` and `19_AIRE_TRA_program`, neither of which is
a mask. Add them to the TEC mask source (`02_thymic_epithelial_medullary` /
`04_thymic_specialized_TEC`) so mTECs are positively identifiable.

## 4. Optional new fine-types hiding in mixed panels
`panel_gene_roles.csv` flags lineage-restricted markers buried in `state`
panels that could seed **fine-tier** subtypes if those populations matter:
- **Granulocytes** — CXCR1/CXCR2 (neutrophil), IL5RA/CCR3 (eosinophil) [from 09]; MMP8 (neutrophil) [from 14].
- **cDC1 / pDC** — XCR1 (cDC1), IL3RA (pDC) [from 09]; IFNA1/2/7/8/17 (pDC type-I-IFN producers) [from 10].
- **Monocyte vs macrophage** — CCR2 (monocyte), CD36/MMP12 (macrophage).
These are candidates only; none are wired into the current taxonomy.

## 5. Hygiene that affects vendoring
- The duplicate thymus `99_uncategorized.csv` has been removed upstream; re-vendor to drop it.
- Pathway panels 21–49 are **name-, not number-, stable** across tissues — key any cross-tissue logic by filename.
- Only the `gene` column is needed for masks; the per-tissue "fat" detection columns are for the XeniumPanelExplorer app, not the phenotyper.

*Rationale and citations: see `docs/panel_classification.md`.*
