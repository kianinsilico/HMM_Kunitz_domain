# Hidden Markov Model for the Kunitz‑type Protease Inhibitor Domain


This project aims to build a Hidden Markov Model (HMM) for the Kunitz-type (PF00014) protease inhibitor domain using structural data from the Protein Data Bank (PDB). The resulting model will be used to annotate homologous domains in external databases such as SwissProt.

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

## Directory Structure

```
scripts/                 # Bash and Python scripts for all steps
data/
├── raw_data/            # Raw FASTA, cluster, and CSV input
├── raw_pdbs/            # Downloaded full PDBs
├── pdbs/                # Cleaned single-chain PDBs
├── processed_data/      # Cleaned ID lists and alignment results
├── visualization/       # TM-align and ChimeraX outputs and plots
```

## Next Steps

- Build multiple sequence alignments from structurally curated dataset
- Generate HMM profiles using `hmmbuild`
- Validate with SwissProt homologs
