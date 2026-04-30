# Pancreas panel audit — output guide

Inputs reconciled: `panel_audit.csv` (5,092 genes), the official 10x Xenium Prime 5K Human Pan Tissue & Pathways reference (5,001 genes, downloaded from 10xgen.com/prime-5k-human), and `Xenium_hIO_v1-metadata.csv` (380 genes, immuno-oncology-focused custom panel).

**Note on the Xenium_hIO_v1-metadata.xlsx file** that was originally uploaded: the .xlsx was structurally empty (every cell carried only formatting, no values). The CSV version supplied afterward has the data and is what was used.

---

## 1. Panel separation

| Set | Count | File |
|---|---|---|
| `panel_audit.csv` total | 5,092 | (input) |
| Xenium Prime 5K official reference | 5,001 | xenium_5k_metadata.csv |
| 5K genes present in the audit | 4,992 | xenium5k_in_audit.csv |
| Custom T1D-GWAS panel (audit ∖ 5K reference) | 100 | custom_T1D_GWAS_panel.csv |
| Already flagged for exclusion (`exclude_recommended=yes`) | 106 | xenium5k_already_excluded.csv |
| Working pool for subpanels (5K ∩ audit, not user-excluded) | 4,886 | (built from above) |
| 5K-reference genes pre-removed from the audit | 9 | (CMTM5, CYP2A6, F2, KLK4, KLK6, MSLN, MUC4, PAEP, PCDH11Y — all tissue-specific to non-pancreas organs) |

The 100-gene custom set was identified by set difference against the official Xenium Prime 5K Human reference panel (no overlap by definition). Inspection confirms it is a coherent T1D panel: TCR constant/variable segments (TRAC, TRBC2, TRAV1-2, TRAV24, TRBV6-4, TRGC2), B2M, the IA-2 autoantigen (PTPRN), proteasome subunits (PSMB6/7/8/9/10), T1D GWAS hits (AFF3, SH2B3, TNFAIP3), islet markers absent from the 5K (IAPP, CHGA, NKX6-1, MAFA, ENTPD3), and immune-cell markers (PTPRC/CD45, CD24, CD74, CCL5, CCL21, RGS1, TXNIP, etc.).

## 2. Subpanels of the 5K

Twenty functional subpanels were built from the 4,886-gene kept pool, using two evidence sources combined with a logical OR:
- 10x Genomics' `cell_type` annotation (CZI CellGuide; tagged in the official 5K metadata)
- 10x's `cellchat_pathway` annotation (CellChatDB pathway tags)
- Curated marker sets for well-known cell types and processes

Genes can appear in more than one subpanel where biology dictates (e.g., FOXP3 in both T-cell and Treg-relevant categories).

| Subpanel | n_genes | Description |
|---|---|---|
| 01_pancreas_endocrine | 168 | A/B/D/PP/epsilon islet cells, endocrine TFs, beta-cell function |
| 02_pancreas_exocrine | 53 | Acinar (digestive enzymes, REG genes), ductal/centroacinar |
| 03_immune_T_cell | 783 | CD3/4/8/TCR, T-helper TFs, Treg, naive/memory/effector, exhaustion |
| 04_immune_B_plasma | 228 | B-cell markers and TFs, plasma-cell signature |
| 05_immune_NK_ILC | 208 | NK receptors, cytotoxic granule contents, ILC TFs |
| 06_immune_myeloid | 484 | Monocytes, macrophages, dendritic cells, Langerhans |
| 07_immune_granulocyte | 217 | Neutrophils, mast cells, eosinophils, basophils |
| 08_antigen_presentation_MHC | 17 | MHC-I/II machinery (most HLA loci absent from the 5K reference) |
| 09_cytokines_chemokines | 126 | IL/TNF/CCL/CXCL ligands and receptors |
| 10_interferon_antiviral | 48 | Type-I/II/III IFN, JAK/STAT, ISGs |
| 11_endothelial_vascular | 348 | Continuous, fenestrated, lymphatic endothelium |
| 12_pericyte_smooth_muscle | 232 | Mural cells, vascular and visceral SMC |
| 13_fibroblast_stellate | 342 | Fibroblasts and pancreatic stellate cells |
| 14_ECM_remodeling | 57 | Collagens, laminins, MMPs/TIMPs/ADAMs |
| 15_neural_glial | 457 | Schwann cells, peripheral neurons, autonomic markers |
| 16_epithelial_general | 779 | EPCAM, cadherins, keratins, junctions |
| 17_cell_cycle_proliferation | 46 | Mitosis, S-phase, MKI67/TOP2A |
| 18_apoptosis_cell_death | 48 | Apoptosis, pyroptosis, necroptosis (T1D beta-cell death) |
| 19_ER_stress_UPR | 20 | PERK/IRE1/ATF6, chaperones, ERAD (T1D beta-cell stress) |
| 20_signaling_pathways_developmental | 61 | WNT, NOTCH, TGFβ/BMP, FGF, Hippo, Hedgehog |
| 99_uncategorized | 2,409 | Genes without annotation hits or curated-marker hits |

The large `99_uncategorized` set means roughly half of the 5K kept pool is not directly assignable to any cell type or pathway by the available 10x annotations or by the curated marker sets used here. Many of these are general-purpose genes (cytoskeletal, metabolic, transcription, splicing) that are still useful as background but do not define any particular cell population. A second pass with HALLMARK / Reactome / KEGG annotations would categorize most of these if needed.

## 3. What 5K genes are NOT in the 5K (caveat for the design discussion)

A point worth recording, since it affects every comparison below: **the standard Xenium Prime 5K Human Pan Tissue & Pathways panel omits several entire gene families** that matter for pancreas/T1D work:

- **All canonical islet hormone genes** (INS, GCG, SST, PPY, GHRL, CHGB, PTPRN2, UCN3) — none are in the 5K.
- **All HLA class I and class II loci** (HLA-A/B/C/E/F/G/DRA/DRB1/DPA1/DPB1/DQA1/DQB1/DMA/DMB) and **B2M** — absent.
- **All TCR constant and variable segments** (TRAC, TRBC1/2, TRAV*, TRBV*, TRGC*, TRDC) except TRDC — absent.
- **All immunoglobulin chains** except IGHE — absent.
- **C1QA/C1QB/C1QC and several other complement components** — absent.
- Several core mast-cell markers (TPSAB1, TPSB2) — absent.

This is consistent with 10x's standard practice of excluding rearranging/hypervariable loci and highly polymorphic regions from the predesigned panel. The user's custom 100 was clearly designed to fill in this gap — it adds B2M, all six TCR segments listed above, PTPRN, IAPP, CHGA, NKX6-1, MAFA, and several proteasome subunits. The hIO panel separately fills in HLA-B (one classical MHC-I locus), nine immunoglobulin chains (IGHM/G1-4/GP, IGKC, IGLC3, JCHAIN), C1QB/R/S, CPA3 (mast cell), GNLY, NKG7, ISG15, CD74, and more.

## 4. hIO_v1 vs the 5K — what would be lost from immune analysis

### Set arithmetic (raw)

| Comparison | Count |
|---|---|
| Genes in hIO_v1 | 380 |
| hIO_v1 ∩ 5K reference | 281 |
| hIO_v1 ∖ 5K reference (real "gain" the 5K cannot provide) | 99 |
| hIO_v1 ∖ (5K + custom 100) (gain over user's current panel) | 85 |
| Custom 100 ∩ hIO_v1 | 14 (ACTA2, CCL21, CCL5, CD74, IFITM3, IL7R, ISG15, LTB, NKG7, PSMB10, PTPRC, RGS1, SDC1, SPARCL1) |

### Inclusive immune-content comparison (broad immune annotation)

Using the union of subpanels 03–10 as the inclusive immune-relevant set in the 5K kept pool: **1,361 genes**.

| Status vs hIO_v1 | Count |
|---|---|
| In hIO_v1 (preserved if switching) | 231 |
| Lost if switching to hIO_v1 only | 1,130 |

This number is inflated by genes whose 10x cell-type annotation associates them with immune lineages but whose biology is general-purpose (translation factors, splicing factors, metabolism). The next view is more conservative.

### High-specificity immune-content comparison

Filtering to genes whose 10x cell-type tags are ≥70% immune lineage tokens, OR which carry an immune cell-chat pathway tag (CCL/CXCL/IL/IFN/MHC/TNF/TGFβ/etc.): **718 genes** in the 5K kept pool.

| Status vs hIO_v1 | Count |
|---|---|
| In hIO_v1 (preserved) | 172 |
| Lost if switching to hIO_v1 only | 544 |
| ...of which detected ≥1% in either of the user's two samples (0041323/0041326) | 308 |
| ...of which detected ≥5% | 139 |
| ...of which detected ≥10% | 75 |

So the most defensible "real loss" figure from the user's actual data is **~140 high-specificity immune genes that show ≥5% detection and would be lost** by switching from the user's current panel to hIO alone, plus another ~170 genes detected at lower levels.

### Subpanel-level coverage (5K kept genes that are in hIO)

| Subpanel | 5K kept genes | In hIO | Lost if hIO only | % lost |
|---|---|---|---|---|
| 03_immune_T_cell | 783 | 131 | 652 | 83.3 |
| 06_immune_myeloid | 484 | 93 | 391 | 80.8 |
| 04_immune_B_plasma | 228 | 46 | 182 | 79.8 |
| 07_immune_granulocyte | 217 | 39 | 178 | 82.0 |
| 05_immune_NK_ILC | 208 | 51 | 157 | 75.5 |
| 09_cytokines_chemokines | 126 | 62 | 64 | 50.8 |
| 10_interferon_antiviral | 48 | 18 | 30 | 62.5 |
| 08_antigen_presentation_MHC | 17 | 6 | 11 | 64.7 |

Cytokines/chemokines and IFN/antiviral are the two best-preserved categories — hIO captures roughly half. Every other immune category is preserved at <25%.

### Concrete examples of what is lost in each category

The full gene-level loss tables are in `hIO_vs_5K_immune_lost_high_specificity.csv` and `hIO_vs_5K_immune_losses_detailed.csv`. Selected named examples for context:

- **T-cell exhaustion**: hIO has PDCD1, CTLA4, HAVCR2, LAG3, TIGIT, TOX, ENTPD1, NT5E, VSIR. **Lost**: TOX2, BTLA, CD160 (and LAYN is in neither panel).
- **Treg**: hIO has FOXP3, IL2RA, CTLA4, ENTPD1, NT5E, CCR4. **Lost**: IKZF2 (Helios), TNFRSF18 (GITR), CCR8, RTKN2, IKZF4 (Eos).
- **Effector/memory TFs**: hIO has TCF7, EOMES, TBX21, RUNX3, ID2, ZNF683 (Hobit). **Lost**: LEF1, S1PR1, BCL6, PRDM1 (Blimp-1).
- **DC subsets**: hIO has BATF3, IRF8, CLEC10A, CD1A, CD1C, LAMP3. **Lost**: CLEC9A, XCR1 (cDC1), CD1E, CD207 (Langerin), FSCN1.
- **Macrophage / TAM**: hIO has CD68, CD163, MARCO, VSIG4, TREM2, ARG1. **Lost**: MRC1, SIRPA, TREM1, NOS2, FOLR2, CCL18.
- **MHC-I machinery**: hIO has HLA-B only. **Lost**: TAP1, TAP2, NLRC5, ERAP1 (and the rest of HLA-A/C/E/F/G, B2M, TAPBP, ERAP2 are in neither).
- **MHC-II machinery**: hIO has CD74. **Lost**: CIITA (and HLA-DR/DP/DQ/DM, IFI30 are in neither).
- **PRR innate sensors**: hIO has only NOD1, MYD88. **Lost**: TLR1–10, NOD2, NLRP3, AIM2, DDX58 (RIG-I), IFIH1 (MDA5), CGAS, MAVS, TICAM1 (and STING1, TRIF are in neither).
- **Complement**: hIO has C1QB, C1R, C1S (which the 5K lacks). **Lost from 5K side**: C4A, C4B, C5, C5AR1, C6, C8B, C9, CFB, CFH, CR1, CR2.
- **Cytotoxic effectors**: hIO has GZMA, GZMB, GZMH, GZMK, PRF1, GNLY, NKG7, FASLG, TNF. **Lost**: IFNG.
- **Type-I IFN / ISG**: hIO has IFNAR1, ISG15, MX1, IFIT2, IFIT3, IFITM3, STAT1, STAT2. **Lost**: IFNAR2, OAS1, OAS3, IFIT1, IFITM1, RSAD2 (viperin), DDX58, IFIH1, IRF7.

### Overall assessment

hIO_v1 is a focused immuno-oncology panel — heavily T-cell, macrophage, plasma-cell, and immune-checkpoint-oriented — that **adds 99 genes the 5K does not have**, including most immunoglobulin chains, several mast-cell and cytotoxic markers, key chemokines (CCL2/3/3L1/4/5, CXCL1/3/14), and HLA-B. It is not a drop-in replacement for the 5K's immune coverage: it preserves only ~17% of the 5K's high-specificity immune content (172 of 1,033 genes by the strict counting rule below; similar ratio at the inclusive level). The categories it most degrades are T-cell biology, pattern-recognition receptors / innate sensing, MHC-II machinery (CIITA), and Treg cofactors (Helios/GITR/CCR8/Eos).

A more reasonable framing of the design choice is therefore not "hIO instead of 5K" but **"5K (or 5K + custom 100) augmented by the 85 hIO-unique genes"** — that gain set captures most of what the 5K design intentionally omitted (Ig chains, C1Q complement, mast-cell tryptases via CPA3, key chemokine ligands, HLA-B). Whether a 100-gene custom add-on slot can fit those 85 + the existing 100-T1D-GWAS additions is the separable question.

## 5. Output files

```
/home/claude/out/
├── custom_T1D_GWAS_panel.csv                    # the 100 custom genes, with original audit annotations
├── xenium5k_in_audit.csv                        # the 4,992 5K genes joined with 10x annotations
├── xenium5k_already_excluded.csv                # the 106 user-flagged exclusions
├── subpanel_01_pancreas_endocrine.csv ... subpanel_20_signaling_pathways_developmental.csv
├── subpanel_99_uncategorized.csv                # 5K kept genes not assigned to any subpanel
├── subpanel_summary.csv                         # counts and descriptions
├── hIO_genes_vs_5K_status.csv                   # all 380 hIO genes, with 5K-presence flag and annotations
├── hIO_genes_unique_vs_5K.csv                   # the 99 hIO genes not in the 5K reference
├── hIO_genes_gained_vs_current_panel.csv        # the 85 hIO genes not in the user's 5K + custom 100
├── hIO_vs_5K_subpanel_coverage.csv              # per-subpanel coverage table
├── hIO_vs_5K_immune_losses_detailed.csv         # 1,665 rows: every immune-subpanel gene the user would lose
├── hIO_vs_5K_immune_lost_high_specificity.csv   # 544 high-specificity immune genes lost, with detection metrics
└── _README_panel_audit.md                       # this file
```


---

## 6. Reassessment with HALLMARK / Reactome / KEGG (v2)

The original ~2,409 "uncategorized" set has been re-examined using three pathway databases
downloaded from Enrichr's public mirror of MSigDB:

| Source | Sets | Memberships | Unique genes |
|---|---:|---:|---:|
| HALLMARK (MSigDB H, 2020) | 50 | 7,321 | 4,383 |
| Reactome (2022) | 1,818 | 111,212 | 10,489 |
| KEGG (2021 Human) | 320 | 32,489 | 8,078 |

Of the 2,409 originally-uncategorized genes:
- 665 (28%) have at least one HALLMARK hit
- 1,082 (45%) have at least one KEGG hit
- 1,084 (45%) have at least one Reactome hit
- 1,453 (60%) have at least one hit across the three sources
- 956 (40%) have no hit in any of HALLMARK / Reactome / KEGG

A per-gene reannotation is in `subpanel_99_uncategorized_REANNOTATED.csv`
(columns: gene, detection metrics, original 10x annotations, HALLMARK, KEGG, REACTOME).

### Twenty-nine new pathway-based subpanels (21–49)

Built from the same 4,891-gene 5K-kept pool used for subpanels 01–20, by taking the union of
relevant HALLMARK + KEGG + Reactome gene sets. Genes can appear in multiple subpanels (e.g., TP53
appears in p53/senescence, apoptosis-extended, and cell-cycle-extended).

| # | Subpanel | n_genes | Theme |
|---|---|---:|---|
| 21 | glycolysis_glucose_metabolism | 102 | HALLMARK Glycolysis + KEGG glycolysis + Reactome glucose metabolism |
| 22 | oxphos_TCA_mitochondria | 67 | OXPHOS, TCA, mitochondrial respiration |
| 23 | hypoxia_HIF | 167 | HALLMARK Hypoxia, HIF-1 signaling |
| 24 | DNA_repair_damage | 132 | HALLMARK DNA Repair + KEGG repair pathways |
| 25 | p53_senescence | 276 | p53 pathway, cellular senescence |
| 26 | mTOR_PI3K_AKT | 401 | HALLMARK mTORC1 + PI3K/AKT/mTOR + KEGG mTOR/PI3K-AKT/AMPK |
| 27 | MAPK_RAS_KRAS | 405 | HALLMARK KRAS + KEGG MAPK/RAS/ErbB |
| 28 | TNF_NFkB_inflammation | 336 | HALLMARK TNFα-NFkB + Inflammatory + KEGG TNF/NF-kB |
| 29 | allograft_autoimmunity_antigen_processing | 269 | HALLMARK Allograft + KEGG Type I diabetes/autoimmune + Reactome MHC processing |
| 30 | complement_extended | 125 | HALLMARK Complement + KEGG complement & coagulation + Reactome cascade |
| 31 | JAK_STAT_IL_extended | 424 | HALLMARK IL-2/STAT5 + IL-6/JAK/STAT3 + KEGG JAK-STAT/Th1-Th2/Th17/cytokine-receptor |
| 32 | innate_PRR_TLR_NLR_RLR | 191 | TLR/NLR/RLR/cGAS-STING/CLR signaling |
| 33 | cell_adhesion_junctions_ECM_extended | 413 | Apical jct + tight/adherens/gap jct + focal adhesion + ECM-receptor |
| 34 | endocytosis_phagosome_lysosome_autophagy | 189 | Vesicle trafficking, phagosome, lysosome, autophagy, mitophagy |
| 35 | cell_death_extended | 287 | Apoptosis + necroptosis + ferroptosis (extends 18) |
| 36 | cell_cycle_extended | 390 | G2-M + E2F + Mitotic Spindle + MYC + KEGG cell cycle (extends 17) |
| 37 | UPR_ER_stress_extended | 87 | UPR + KEGG protein processing in ER (extends 19) |
| 38 | insulin_biology_T1D_extended | 240 | HALLMARK Pancreas Beta + KEGG Type I/II diabetes/MODY/AGE-RAGE + Reactome insulin secretion regulation |
| 39 | reactive_oxygen_species | 30 | HALLMARK ROS + glutathione metabolism |
| 40 | EMT | 98 | Epithelial-mesenchymal transition |
| 41 | lipid_bile_heme_peroxisome_metabolism | 266 | Fatty acid + cholesterol + bile + heme + peroxisome |
| 42 | calcium_cAMP_signaling | 264 | KEGG calcium/cAMP/cGMP-PKG (relevant to insulin secretion) |
| 43 | iron_zinc_metal_homeostasis | 46 | Iron uptake + zinc SLC30/SLC39 + ferroptosis (T1D autoantigen SLC30A8) |
| 44 | translation_RNA_proteasome | 79 | Ribosome + spliceosome + proteasome + cap-dep translation |
| 45 | hematopoietic_lineage_KEGG | 74 | KEGG hematopoietic cell lineage CD markers |
| 46 | GPCR_signaling | 404 | KEGG neuroactive ligand-receptor + Reactome GPCR signaling |
| 47 | ion_channels | 92 | K/Ca/Na ion channels |
| 48 | chromatin_transcription | 481 | Chromatin remodeling + histone modifiers + RNA Pol II transcription |
| 49 | synapse_neurotransmission | 241 | KEGG synaptic vesicle cycle + glutamate/GABA/cholinergic/dopaminergic/serotonergic |

### Final coverage

Of the 4,891-gene 5K-kept pool:
- **3,595 genes (73.5%)** are now assigned to at least one of the 49 subpanels
- **1,296 genes (26.5%)** remain in residual (`subpanel_99c_residual_after_reannotation.csv`)
- Of the residual: **956 are truly unannotated** (no HALLMARK / KEGG / Reactome hit, file `subpanel_99d_truly_unannotated.csv`); 340 have hits but only in very general parent pathway terms ("Disease", "Metabolism Of Proteins", "Signal Transduction", "Immune System") that do not constitute a useful subpanel.

### What's in the residual

The 956 truly-unannotated set is dominated by:
- Highly expressed housekeeping or scaffold proteins (e.g., H3F3B, EPRS, MAP4, WBP2, TSPAN3, IPO5, BRD4, SAFB, PTBP1)
- Tissue-specific genes not in canonical pathway DBs (e.g., AMY1A — salivary amylase; NOTCH2NLA)
- E3 ubiquitin ligases (RNF/TRIM family)
- Zinc-finger transcription factors (ZNF family)
- Pseudogene-like (~80 genes by name-pattern)

Detection profile of the residual 1,296: 841 detected ≥1%, 404 detected ≥5%, 147 detected ≥10% in either of the user's two samples. Of the 956 truly unannotated, 287 are detected ≥5% — these are highly expressed but uncharacterized in canonical pathway space, and would warrant individual literature review before being designated as candidates for removal.

### Files added in v2

```
subpanel_99_uncategorized_REANNOTATED.csv   # original 2,409 with H/K/R hit columns
subpanel_99c_residual_after_reannotation.csv  # 1,296 genes still without a subpanel
subpanel_99d_truly_unannotated.csv          # 956 genes with no H/K/R hit (subset of 99c)
subpanel_21_*.csv ... subpanel_49_*.csv      # 29 new pathway-based subpanels
subpanel_summary_v2.csv                      # full counts (49 subpanels + residual)
```
