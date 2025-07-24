# HMM-Based Detection of Kunitz Domains from Structure-Derived Alignments

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/license-CC--BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/)
[![Citation: CFF](https://img.shields.io/badge/citation-CFF-blue.svg)](CITATION.cff)
[![University of Bologna](https://img.shields.io/badge/university-Bologna-red.svg)](https://www.unibo.it/)
[![Bioinformatics Lab 1](https://img.shields.io/badge/course-Bioinformatics%20Lab%201-blueviolet)](https://github.com/)
[![HMMER](https://img.shields.io/badge/tool-HMMER-yellow)](http://hmmer.org/)
[![Python 3.13+](https://img.shields.io/badge/python-3.13+-blue)](https://www.python.org/)
[![TM-align](https://img.shields.io/badge/tool-TM--align-orange)](https://zhanggroup.org/TM-align/)
[![MMseqs2](https://img.shields.io/badge/tool-MMseqs2-green)](https://github.com/soedinglab/MMseqs2)
[![Project Status](https://img.shields.io/badge/status-complete-success)](https://github.com/)

<div align="center">

  <img src="docs/.repo_visulas/graphical_abstract.png" alt="Kunitz Domain HMM Classification Project Banner" width="100%"/>

</div>

This repository contains the complete pipeline and materials for building, evaluating, and validating a profile HMM designed to detect Kunitz-type domains in protein sequences, as part of the final assessment for **Laboratory of Bioinformatics 1 @ University of Bologna**.

---

## Project Overview

This project addresses the identification of **Kunitz-type serine protease inhibitors** through a **custom-trained HMM**, evaluated for performance on diverse validation datasets. The model was built from structure-based alignments, evaluated using strict quality metrics, and benchmarked against known positive and negative datasets.

---

## 🗂️ Repository Structure

```bash
├── data/                         # All datasets and processed data
│   ├── datasets/                 # FASTA files, classification data, evaluation results
│   ├── pdbs/                     # Cleaned single-chain PDB structures
│   ├── processed_data/           # Intermediate processing results
│   ├── raw_data/                 # Original input data
│   ├── raw_pdbs/                 # Downloaded full PDB structures
│   ├── tmalign_results/          # Pairwise alignment outputs
│   ├── visualization/            # Plots and visual analysis results
│   └── consistency_check.txt     # Data validation results
├── scripts/                      # Processing pipeline scripts
│   ├── 01_csv_to_fasta.sh        # Convert CSV to FASTA format
│   ├── 02_mmseqs_cluster.sh      # Sequence clustering with MMseqs2
│   ├── 03_extract_ids.sh         # ID formatting for PDBeFold
│   ├── 04_extract_chains.sh      # PDB chain extraction
│   ├── 05_run_tmalign.sh         # Structural alignment pipeline
│   ├── 06_parse_tmalign.py       # TM-align results parser
│   ├── 07_kunitz_superposition.cxc # ChimeraX superposition script
│   ├── 08_plot_pdbefold_matrices.py # Visualization scripts
│   ├── 09_build_hmm.sh           # HMM model construction
│   ├── 11_consistency_check.sh   # Data validation
│   ├── 12_kunitz_hmm_validator.sh # Enhanced HMM evaluation tool
├── docs/                         # Documentation and visuals
│   ├── .repo_visulas/            # Repository graphics and banner
│   └── results/                  # Analysis results and reports
├── environment_full.yml          # Conda environment specification
├── LICENCE                       # License file
├── LICENCE-DATA.txt             # Data license information
└── README.md                     # Project documentation
```
## Project Workflow Summary

### 1. Data Acquisition and Preprocessing

- Data was retrieved from RCSB PDB using a custom query:
  - Pfam ID: PF00014
  - Resolution ≤ 3 Å
  - Sequence length between 45–80 residues
- A custom report was downloaded from the RCSB website including the following fields:
  - Entry ID
  - Polymer Entity ID
  - Sequence
  - Annotation Identifier
  - Chain ID

- Extracted FASTA sequences from the CSV report using `scripts/01_csv_to_fasta.sh`


### 2. Sequence Clustering

- Clustered with MMseqs2 using `scripts/02_mmseqs_cluster.sh`
- Identity threshold: 90%, coverage: 80%
- Output: representative sequences for further analysis

### 3. ID Extraction for Structural Search

- Used `scripts/03_extract_ids.sh` to format IDs for PDBeFold

### 4. Structural Filtering

- Extracted desired chains from downloaded PDB files using:
  ```
  ./scripts/04_extract_chains.sh <cleaned_id_list> <raw_pdb_dir> <output_dir>
  ```
- Manual QC in AliView and ChimeraX identified and excluded:
  - `1yld_B` (truncated structure)
  - `5jbt_Y` (structurally divergent)

### 5. Structural Alignment and Quality Assessment

- Ran all-vs-all TM-align using `scripts/05_run_tmalign.sh`
- Parsed and visualized results using `scripts/06_parse_tmalign.py`
  - Outputs: RMSD and TM-score matrices, rankings, heatmaps
  - Top reference: `1f5r_I`

### 6. Superposition

- Structures were aligned in ChimeraX using Matchmaker
- Alignment centered on `1f5r:I`
- Outputs include `.cxs` session file and figure

### 7: HMM Construction
```bash
hmmbuild kunitz_model.hmm pdb_kunitz_PDBeFold_alignment_clean.fasta.ali
```

### 8: HMM Evaluation & Cross-Validation

The final HMM model undergoes rigorous evaluation using a 2-fold cross-validation approach to assess its performance on independent datasets. This evaluation process ensures robust performance metrics and validates the model's ability to correctly identify Kunitz-type domains while minimizing false positives.

**Evaluation Methodology:**
- **Cross-validation design:** 2-fold splitting to maximize dataset utilization
- **Overlap removal:** Training sequences are filtered out to prevent data leakage
- **Performance metrics:** Matthews Correlation Coefficient (MCC), True Positive Rate (TPR), and Positive Predictive Value (PPV)
- **Threshold optimization:** Multiple E-value thresholds tested to find optimal cutoffs

**Validation Datasets:**
- `human_kunitz.fasta` - Human Kunitz domain sequences (positive set)
- `human_notkunitz.fasta` - Human non-Kunitz sequences (negative control)
- `nothuman_kunitz.fasta` - Non-human Kunitz sequences (diversity test)
- `uniprot_sprot.fasta` - SwissProt background sequences (large negative set)

**Analysis Pipeline:**
1. Combine input datasets and remove training sequence overlaps
2. Random split into balanced positive/negative folds
3. Execute hmmsearch against the trained HMM model
4. Parse results and calculate classification performance
5. Generate comprehensive performance reports and threshold analysis

---

## 🛠️ Environment Setup

The project includes a streamlined conda environment with only essential bioinformatics tools:

```bash
# Create the environment
conda env create -f environment_full.yml

# Activate the environment
conda activate kunitz
```

**Key dependencies:**
- **Python 3.13** with scientific computing stack (NumPy, Pandas, SciPy)
- **Bioinformatics tools:** BLAST, HMMER, MMseqs2, MUSCLE, TM-align
- **Analysis tools:** BioPython, Matplotlib, Seaborn
- **Sequence utilities:** SeqKit, PDB-tools

---

## 📈 Performance Results
| UniProt ID | Length | \# Domains (PF00014) | Domain Position(s) | Comments               |
|------------|--------|----------------------|--------------------|------------------------|
| A0A1Q1NL17 | 101    | 1                    | 32--88             | Short sequence         |
| O62247     | 202    | 1                    | 138--184           | Domain near C-terminal |
| Q8WPG5     | 134    | 2                    | 17--69, 83--129    | Tandem domains         |
| D3GGZ8     | 195    | 1                    | 120--190           | Domain near C-terminal |

> Best result observed with E-value threshold = 1e-06 using full sequence mode:
MCC = 0.9945, TPR = 1.0, PPV = 0.989
